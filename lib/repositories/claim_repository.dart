import 'package:alarma_comunitaria/models/claim.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final claimRepositoryProvider = Provider((ref) => ClaimRepository());

class ClaimRepository {
  final FirebaseFirestore _firestore;

  ClaimRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _claimsCollection =>
      _firestore.collection('claims');

  Stream<List<Claim>> watchClaims(String communityId) {
    return _claimsCollection
        .where('communityId', isEqualTo: communityId)
        .snapshots()
        .map((snapshot) {
      final claims = snapshot.docs
          .map((doc) => Claim.fromMap(doc.data(), doc.id))
          .toList();
      claims.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return claims;
    });
  }

  Future<String> createClaim(Claim claim) async {
    final docRef = await _claimsCollection.add(claim.toMap());
    return docRef.id;
  }

  Future<void> toggleLike(String claimId, String userId) async {
    final docRef = _claimsCollection.doc(claimId);
    final doc = await docRef.get();
    if (!doc.exists) return;

    final data = doc.data()!;
    final List<String> likedUserIds = List<String>.from(data['likedUserIds'] ?? []);
    int likesCount = data['likesCount'] ?? 0;

    if (likedUserIds.contains(userId)) {
      likedUserIds.remove(userId);
      likesCount = (likesCount > 0) ? likesCount - 1 : 0;
    } else {
      likedUserIds.add(userId);
      likesCount += 1;
    }

    await docRef.update({
      'likedUserIds': likedUserIds,
      'likesCount': likesCount,
    });
  }

  Future<void> addReply(String claimId, ClaimReply reply) async {
    final docRef = _claimsCollection.doc(claimId);
    final doc = await docRef.get();
    if (!doc.exists) return;

    final data = doc.data()!;
    final List<dynamic> rawReplies = data['replies'] ?? [];
    rawReplies.add(reply.toMap());

    await docRef.update({
      'replies': rawReplies,
    });
  }

  Future<void> deleteClaim(String claimId) async {
    await _claimsCollection.doc(claimId).delete();
  }
}
