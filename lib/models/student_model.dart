class StudentModel {
  final String id;
  final String name;
  final String classId;
  final int birthDay;
  final int birthMonth;
  final int birthYear;

  StudentModel({
    required this.id,
    required this.name,
    required this.classId,
    required this.birthDay,
    required this.birthMonth,
    required this.birthYear,
  });

  factory StudentModel.fromMap(Map<String, dynamic> map) {
    print('Parsing student data: ${map.toString()}');
    
    // Get birth month first
    final birthMonth = map['birthMonth'] is int 
        ? map['birthMonth'] 
        : int.tryParse(map['birthMonth']?.toString() ?? '');
    
    // Skip invalid birth months
    if (birthMonth == null || birthMonth == 0) {
      print('Skipping student ${map['name']} due to invalid birth month');
      throw FormatException('Invalid birth month');
    }
    
    final birthDay = map['birthDay'] is int 
        ? map['birthDay'] 
        : int.tryParse(map['birthDay']?.toString() ?? '') ?? 1;
    
    final birthYear = map['birthYear'] is int 
        ? map['birthYear'] 
        : int.tryParse(map['birthYear']?.toString() ?? '') ?? 2000;
    
    return StudentModel(
      id: map['\$id'] ?? '',
      name: map['name'] ?? '',
      classId: map['classId'] ?? '',
      birthDay: birthDay,
      birthMonth: birthMonth,
      birthYear: birthYear,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'classId': classId,
      'birthDay': birthDay,
      'birthMonth': birthMonth,
      'birthYear': birthYear,
    };
  }
}