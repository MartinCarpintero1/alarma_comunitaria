enum UserRole { resident, security, admin }

class UserModel {
  final String id;
  final String name;
  final String email;
  final String communityId;
  final String department;
  final String manzana;
  final String casa;
  final String barrio;
  final String houseDescription;
  final String phone;
  final String activationCode;
  final UserRole role;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.communityId,
    required this.department,
    required this.manzana,
    required this.casa,
    required this.barrio,
    required this.houseDescription,
    required this.phone,
    required this.activationCode,
    required this.role,
  });

  factory UserModel.empty() {
    return const UserModel(
      id: '',
      name: '',
      email: '',
      communityId: '',
      department: '',
      manzana: '',
      casa: '',
      barrio: '',
      houseDescription: '',
      phone: '',
      activationCode: '',
      role: UserRole.resident,
    );
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      communityId: map['communityId'] as String? ?? '',
      department: map['department'] as String? ?? '',
      manzana: map['manzana'] as String? ?? '',
      casa: map['casa'] as String? ?? '',
      barrio: map['barrio'] as String? ?? '',
      houseDescription: map['houseDescription'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      activationCode: map['activationCode'] as String? ?? '',
      role: UserRole.values.firstWhere(
        (role) => role.name == (map['role'] as String? ?? 'resident'),
        orElse: () => UserRole.resident,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'communityId': communityId,
      'department': department,
      'manzana': manzana,
      'casa': casa,
      'barrio': barrio,
      'houseDescription': houseDescription,
      'phone': phone,
      'activationCode': activationCode,
      'role': role.name,
    };
  }
}
