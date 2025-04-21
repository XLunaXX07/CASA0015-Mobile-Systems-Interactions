class UserModel {
  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final List<EmergencyContact> emergencyContacts;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    this.emergencyContacts = const [],
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      emergencyContacts: map['emergencyContacts'] != null
          ? List<EmergencyContact>.from(
              map['emergencyContacts']?.map((x) => EmergencyContact.fromMap(x)))
          : [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'emergencyContacts': emergencyContacts.map((x) => x.toMap()).toList(),
    };
  }
}

class EmergencyContact {
  final String name;
  final String phoneNumber;
  final String relationship;

  EmergencyContact({
    required this.name,
    required this.phoneNumber,
    this.relationship = '',
  });

  factory EmergencyContact.fromMap(Map<String, dynamic> map) {
    return EmergencyContact(
      name: map['name'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      relationship: map['relationship'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phoneNumber': phoneNumber,
      'relationship': relationship,
    };
  }
} 