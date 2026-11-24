import 'package:alarma_comunitaria/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthRepository {
	final FirebaseFirestore _firestore;

	AuthRepository({FirebaseFirestore? firestore})
			: _firestore = firestore ?? FirebaseFirestore.instance;

	CollectionReference<Map<String, dynamic>> get _usersCollection =>
			_firestore.collection('users');

	Future<void> createUserProfile(UserModel profile) {
		return _usersCollection.doc(profile.id).set(profile.toMap());
	}

	Future<UserModel?> getUserProfile(String uid) async {
		final snapshot = await _usersCollection.doc(uid).get();
		if (!snapshot.exists || snapshot.data() == null) return null;
		return UserModel.fromMap(snapshot.data()!, snapshot.id);
	}

	Stream<UserModel?> watchUserProfile(String uid) {
		return _usersCollection.doc(uid).snapshots().map((snapshot) {
			if (!snapshot.exists || snapshot.data() == null) return null;
			return UserModel.fromMap(snapshot.data()!, snapshot.id);
		});
	}

	Future<void> updateUserProfile(UserModel profile) {
		return _usersCollection.doc(profile.id).update(profile.toMap());
	}
}
