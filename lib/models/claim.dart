class ClaimReply {
  final String id;
  final String userId;
  final String userName;
  final String manzana;
  final String casa;
  final String text;
  final DateTime createdAt;

  ClaimReply({
    required this.id,
    required this.userId,
    required this.userName,
    required this.manzana,
    required this.casa,
    required this.text,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'userName': userName,
        'manzana': manzana,
        'casa': casa,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ClaimReply.fromMap(Map<String, dynamic> map) => ClaimReply(
        id: map['id'] ?? '',
        userId: map['userId'] ?? '',
        userName: map['userName'] ?? '',
        manzana: map['manzana'] ?? '',
        casa: map['casa'] ?? '',
        text: map['text'] ?? '',
        createdAt: map['createdAt'] != null
            ? DateTime.parse(map['createdAt'])
            : DateTime.now(),
      );
}

class Claim {
  final String id;
  final String communityId;
  final String userId;
  final String userName;
  final String manzana;
  final String casa;
  final String barrio;
  final String phone;
  final String title;
  final String description;
  final DateTime createdAt;
  final int likesCount;
  final List<String> likedUserIds;
  final List<ClaimReply> replies;

  Claim({
    required this.id,
    required this.communityId,
    required this.userId,
    required this.userName,
    required this.manzana,
    required this.casa,
    required this.barrio,
    required this.phone,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.likesCount,
    required this.likedUserIds,
    required this.replies,
  });

  Map<String, dynamic> toMap() => {
        'communityId': communityId,
        'userId': userId,
        'userName': userName,
        'manzana': manzana,
        'casa': casa,
        'barrio': barrio,
        'phone': phone,
        'title': title,
        'description': description,
        'createdAt': createdAt.toIso8601String(),
        'likesCount': likesCount,
        'likedUserIds': likedUserIds,
        'replies': replies.map((r) => r.toMap()).toList(),
      };

  factory Claim.fromMap(Map<String, dynamic> map, String id) => Claim(
        id: id,
        communityId: map['communityId'] ?? '',
        userId: map['userId'] ?? '',
        userName: map['userName'] ?? '',
        manzana: map['manzana'] ?? '',
        casa: map['casa'] ?? '',
        barrio: map['barrio'] ?? '',
        phone: map['phone'] ?? '',
        title: map['title'] ?? '',
        description: map['description'] ?? '',
        createdAt: map['createdAt'] != null
            ? DateTime.parse(map['createdAt'])
            : DateTime.now(),
        likesCount: map['likesCount'] ?? 0,
        likedUserIds: List<String>.from(map['likedUserIds'] ?? []),
        replies: (map['replies'] as List<dynamic>? ?? [])
            .map((r) => ClaimReply.fromMap(r as Map<String, dynamic>))
            .toList(),
      );
}
