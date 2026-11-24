import 'dart:async';

import 'package:alarma_comunitaria/models/user_model.dart';
import 'package:alarma_comunitaria/repositories/auth_repository.dart';
import 'package:alarma_comunitaria/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AuthStatus { loading, authenticated, unauthenticated, fail }

class AuthState {
	final AuthStatus status;
	final User? firebaseUser;
	final UserModel? profile;
	final String? errorMessage;

	const AuthState({
		required this.status,
		this.firebaseUser,
		this.profile,
		this.errorMessage,
	});

	const AuthState.inProgress() : this(status: AuthStatus.loading);
	const AuthState.guest({String? errorMessage})
			: this(status: AuthStatus.unauthenticated, errorMessage: errorMessage);
	const AuthState.user(User user, UserModel profile)
			: this(status: AuthStatus.authenticated, firebaseUser: user, profile: profile);
	const AuthState.failure(String message, {User? user})
			: this(status: AuthStatus.fail, firebaseUser: user, errorMessage: message);
}

final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository());

final communityNeighborsCountProvider = StreamProvider.family<int, String>((ref, communityId) {
  final cleanCommunityId = communityId.trim();
  return FirebaseFirestore.instance
      .collection('users')
      .where('communityId', isEqualTo: cleanCommunityId)
      .snapshots()
      .map((snapshot) => snapshot.docs.length);
});

final communityNeighborsStreamProvider = StreamProvider.family<List<UserModel>, String>((ref, communityId) {
  final cleanCommunityId = communityId.trim();
  if (cleanCommunityId.isEmpty) return Stream.value([]);
  return FirebaseFirestore.instance
      .collection('users')
      .where('communityId', isEqualTo: cleanCommunityId)
      .snapshots()
      .map((snapshot) {
    final list = snapshot.docs.map((doc) => UserModel.fromMap(doc.data(), doc.id)).toList();
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  });
});

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

class AuthNotifier extends Notifier<AuthState> {
	late final AuthService _authService;
	late final AuthRepository _authRepository;
	StreamSubscription<User?>? _authSubscription;

	@override
	AuthState build() {
		if (Firebase.apps.isEmpty) return const AuthState.guest();
		_authService = ref.read(authServiceProvider);
		_authRepository = ref.read(authRepositoryProvider);
		_authSubscription = _authService.authStateChanges.listen(_handleAuthState);
		ref.onDispose(() => _authSubscription?.cancel());
		unawaited(_handleAuthState(_authService.currentUser));
		return const AuthState.inProgress();
	}

	User? get currentUser => _authService.currentUser;

	Future<void> _handleAuthState(User? user) async {
		if (user == null) {
			state = const AuthState.guest();
			return;
		}

		state = const AuthState.inProgress();
		try {
			final profile = await _authRepository.getUserProfile(user.uid);
			if (profile == null) {
				state = const AuthState.failure(
					'Tu cuenta no tiene un perfil comunitario completo. Contacta al administrador.',
				);
				return;
			}

			if (profile.activationCode.isNotEmpty) {
				try {
					final codeQuery = await FirebaseFirestore.instance
							.collection('codigos_dispositivos')
							.where('codigo', isEqualTo: profile.activationCode)
							.get();
					if (codeQuery.docs.isNotEmpty) {
						final codeData = codeQuery.docs.first.data();
						final Timestamp? vencimientoTs = codeData['fechaVencimiento'] as Timestamp?;
						if (vencimientoTs != null && DateTime.now().isAfter(vencimientoTs.toDate())) {
							state = const AuthState.failure(
								'SUBSCRIPCIÓN_VENCIDA',
							);
							return;
						}
					}
				} catch (_) {}
			}

			final prefs = await SharedPreferences.getInstance();
			await prefs.setString('communityId', profile.communityId);
			await prefs.setString('userId', profile.id);
			await prefs.setString('activationCode', profile.activationCode);

			try {
				OneSignal.login(user.uid);
				OneSignal.User.addTagWithKey("communityId", profile.communityId);
			} catch (_) {}

			state = AuthState.user(user, profile);
		} catch (error) {
			state = AuthState.failure(
				'No se pudo cargar tu perfil. Comprueba tu conexión e inténtalo de nuevo.',
				user: user,
			);
		}
	}

	Future<bool> signIn({required String email, required String password}) async {
		state = const AuthState.inProgress();
		try {
			final credential = await _authService.signIn(email: email, password: password);
			await _handleAuthState(credential.user);
			return state.status == AuthStatus.authenticated;
		} catch (error) {
			state = AuthState.failure(AuthService.messageForError(error));
			return false;
		}
	}

	Future<bool> signUp({
		required String name,
		required String email,
		required String password,
		required String communityId,
		required String department,
		required String manzana,
		required String casa,
		required String barrio,
		required String houseDescription,
		required String phone,
		required String activationCode,
	}) async {
		state = const AuthState.inProgress();
		User? user;
		try {
			final codeTrim = activationCode.trim();
			if (codeTrim.length != 5) {
				state = const AuthState.failure('El código de activación debe tener exactamente 5 cifras.');
				return false;
			}

			final firestore = FirebaseFirestore.instance;
			final codeQuery = await firestore
					.collection('codigos_dispositivos')
					.where('codigo', isEqualTo: codeTrim)
					.get();

			if (codeQuery.docs.isEmpty) {
				state = const AuthState.failure('El código de activación no existe en el sistema.');
				return false;
			}

			final codeDoc = codeQuery.docs.first;
			final codeData = codeDoc.data();
			final bool activo = codeData['activo'] as bool? ?? false;

			if (activo) {
				state = const AuthState.failure('Este código de activación ya ha sido utilizado por otra persona.');
				return false;
			}

			final Timestamp? vencimientoTs = codeData['fechaVencimiento'] as Timestamp?;
			if (vencimientoTs != null && DateTime.now().isAfter(vencimientoTs.toDate())) {
				state = const AuthState.failure('Este código de activación ha vencido. Contacte a soporte.');
				return false;
			}

			final credential = await _authService.signUp(email: email, password: password);
			user = credential.user;
			if (user == null) throw StateError('Firebase no devolvió el usuario creado.');

			await firestore.collection('codigos_dispositivos').doc(codeDoc.id).update({
				'activo': true,
				'userId': user.uid,
				'fechaUltimaRenovacion': Timestamp.now(),
			});

			final profile = UserModel(
				id: user.uid,
				name: name.trim(),
				email: user.email ?? email.trim(),
				communityId: communityId.trim(),
				department: department.trim(),
				manzana: manzana.trim(),
				casa: casa.trim(),
				barrio: barrio.trim(),
				houseDescription: houseDescription.trim(),
				phone: phone.trim(),
				activationCode: codeTrim,
				role: UserRole.resident,
			);
			await _authRepository.createUserProfile(profile);

			final prefs = await SharedPreferences.getInstance();
			await prefs.setString('communityId', profile.communityId);
			await prefs.setString('userId', profile.id);
			await prefs.setString('activationCode', codeTrim);

			try {
				OneSignal.login(user.uid);
				OneSignal.User.addTagWithKey("communityId", profile.communityId);
			} catch (_) {}

			state = AuthState.user(user, profile);
			return true;
		} catch (error) {
			if (user != null) {
				try {
					await user.delete();
				} catch (_) {
					await _authService.signOut();
				}
			}
			state = AuthState.failure(AuthService.messageForError(error));
			return false;
		}
	}

	Future<bool> updateProfile({
		required String name,
		required String manzana,
		required String casa,
		required String barrio,
		required String department,
		required String houseDescription,
		required String phone,
	}) async {
		final currentUser = state.firebaseUser;
		final currentProfile = state.profile;
		if (currentUser == null || currentProfile == null) return false;

		try {
			final updatedProfile = UserModel(
				id: currentProfile.id,
				name: name.trim(),
				email: currentProfile.email,
				communityId: currentProfile.communityId,
				department: department.trim(),
				manzana: manzana.trim(),
				casa: casa.trim(),
				barrio: barrio.trim(),
				houseDescription: houseDescription.trim(),
				phone: phone.trim(),
				activationCode: currentProfile.activationCode,
				role: currentProfile.role,
			);
			await _authRepository.updateUserProfile(updatedProfile);

			final prefs = await SharedPreferences.getInstance();
			await prefs.setString('communityId', updatedProfile.communityId);
			await prefs.setString('userId', updatedProfile.id);

			try {
				OneSignal.login(currentUser.uid);
				OneSignal.User.addTagWithKey("communityId", updatedProfile.communityId);
			} catch (_) {}

			state = AuthState.user(currentUser, updatedProfile);
			return true;
		} catch (error) {
			state = AuthState.failure('No se pudo actualizar el perfil.');
			return false;
		}
	}

	Future<void> signOut() async {
		state = const AuthState.inProgress();
		try {
			final prefs = await SharedPreferences.getInstance();
			await prefs.remove('communityId');
			await prefs.remove('userId');
			await prefs.remove('activationCode');
			try {
				await FlutterForegroundTask.stopService();
				await OneSignal.logout();
			} catch (_) {}
			await _authService.signOut();
		} catch (error) {
			state = AuthState.failure(AuthService.messageForError(error));
		}
	}

	Future<bool> resetPassword(String email) async {
		try {
			await _authService.resetPassword(email);
			return true;
		} catch (error) {
			state = AuthState.failure(AuthService.messageForError(error));
			return false;
		}
	}
}
