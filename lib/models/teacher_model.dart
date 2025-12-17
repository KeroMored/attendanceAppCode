enum TeacherRole {
  admin,
  superAdmin,
  user,
}

extension TeacherRoleExtension on TeacherRole {
  String get value {
    switch (this) {
      case TeacherRole.admin:
        return 'admin';
      case TeacherRole.superAdmin:
        return 'superAdmin';
      case TeacherRole.user:
        return 'user';
    }
  }

  String get displayName {
    switch (this) {
      case TeacherRole.admin:
        return 'مشرف';
      case TeacherRole.superAdmin:
        return 'ادمن';
      case TeacherRole.user:
        return 'خادم';
    }
  }

  static TeacherRole fromString(String value) {
    switch (value) {
      case 'admin':
        return TeacherRole.admin;
      case 'superAdmin':
        return TeacherRole.superAdmin;
      case 'user':
        return TeacherRole.user;
      default:
        return TeacherRole.user;
    }
  }
}

class TeacherModel {
  final String? id;
  final String name;
  final String? address;
  final String? phoneNumber1;
  final String? phoneNumber2;
  final String? students; // Relationship field from Appwrite
  final String teacherPassword;
  final TeacherRole role;

  TeacherModel({
    this.id,
    required this.name,
    this.address,
    this.phoneNumber1,
    this.phoneNumber2,
    this.students,
    required this.teacherPassword,
    required this.role,
  });

  // Convert TeacherModel to Map for Appwrite
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'phoneNumber1': phoneNumber1,
      'phoneNumber2': phoneNumber2,
      'students': students,
      'teacherPassword': teacherPassword,
      'role': role.value,
    };
  }

  // Create TeacherModel from Map (from Appwrite)
  factory TeacherModel.fromMap(Map<String, dynamic> map) {
    // Helper function to safely convert to String
    String? safeString(dynamic value) {
      if (value == null) return null;
      if (value is String) return value;
      if (value is List && value.isNotEmpty) return value.first.toString();
      return value.toString();
    }

    return TeacherModel(
      id: safeString(map['\$id']),
      name: safeString(map['name']) ?? '',
      address: safeString(map['address']),
      phoneNumber1: safeString(map['phoneNumber1']),
      phoneNumber2: safeString(map['phoneNumber2']),
      students: safeString(map['students']),
      teacherPassword: safeString(map['teacherPassword']) ?? '',
      role: TeacherRoleExtension.fromString(safeString(map['role']) ?? 'user'),
    );
  }

  // Create a copy of TeacherModel with updated fields
  TeacherModel copyWith({
    String? id,
    String? name,
    String? address,
    String? phoneNumber1,
    String? phoneNumber2,
    String? students,
    String? teacherPassword,
    TeacherRole? role,
  }) {
    return TeacherModel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      phoneNumber1: phoneNumber1 ?? this.phoneNumber1,
      phoneNumber2: phoneNumber2 ?? this.phoneNumber2,
      students: students ?? this.students,
      teacherPassword: teacherPassword ?? this.teacherPassword,
      role: role ?? this.role,
    );
  }

  @override
  String toString() {
    return 'TeacherModel(id: $id, name: $name, address: $address, phoneNumber1: $phoneNumber1, phoneNumber2: $phoneNumber2, students: $students, teacherPassword: $teacherPassword, role: ${role.value})';
  }
}