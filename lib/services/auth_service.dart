import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
	final FirebaseAuth _auth;

	AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

	Future<UserCredential> signIn({
		required String email,
		required String password,
	}) {
		return _auth.signInWithEmailAndPassword(
			email: email.trim(),
			password: password,
		);
	}

	Future<UserCredential> signUp({
		required String email,
		required String password,
	}) {
		return _auth.createUserWithEmailAndPassword(
			email: email.trim(),
			password: password,
		);
	}

	Future<void> signOut() => _auth.signOut();

	Future<void> resetPassword(String email) {
		return _auth.sendPasswordResetEmail(email: email.trim());
	}

	User? get currentUser => _auth.currentUser;

	Stream<User?> get authStateChanges => _auth.authStateChanges();

	static String messageForError(Object error) {
		if (error is! FirebaseAuthException) {
			return 'No se pudo completar la operación. Inténtalo de nuevo.';
		}

		switch (error.code) {
			case 'invalid-email':
				return 'El correo electrónico no es válido.';
			case 'user-not-found':
			case 'wrong-password':
			case 'invalid-credential':
				return 'El correo o la contraseña son incorrectos.';
			case 'email-already-in-use':
				return 'Ya existe una cuenta con este correo electrónico.';
			case 'weak-password':
				return 'La contraseña es demasiado débil.';
			case 'too-many-requests':
				return 'Demasiados intentos. Espera unos minutos e inténtalo de nuevo.';
			case 'network-request-failed':
				return 'No hay conexión con el servidor. Comprueba tu conexión a Internet.';
			case 'user-disabled':
				return 'Esta cuenta ha sido deshabilitada.';
			case 'operation-not-allowed':
				return 'El inicio de sesión por correo aún no está habilitado.';
			default:
				return 'No se pudo completar la operación. Inténtalo de nuevo.';
		}
	}
}
