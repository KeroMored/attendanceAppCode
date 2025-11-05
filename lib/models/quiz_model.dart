class QuizModel {
  final String? id;
  final String name;
  final String classId;
  final bool isVisible;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<String> questionIds;

  QuizModel({
    this.id,
    required this.name,
    required this.classId,
    this.isVisible = false,
    required this.createdAt,
    this.updatedAt,
    this.questionIds = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'classId': classId,
      'isVisible': isVisible,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'questionIds': questionIds,
    };
  }

  factory QuizModel.fromMap(Map<String, dynamic> map) {
    try {
      return QuizModel(
        id: map['\$id'],
        name: map['name']?.toString() ?? '',
        classId: map['classId']?.toString() ?? '',
        isVisible: map['isVisible'] is bool ? map['isVisible'] : false,
        createdAt: map['createdAt'] != null 
            ? DateTime.parse(map['createdAt'].toString()) 
            : DateTime.now(),
        updatedAt: map['updatedAt'] != null 
            ? DateTime.parse(map['updatedAt'].toString()) 
            : null,
        questionIds: map['questionIds'] is List 
            ? List<String>.from(map['questionIds']) 
            : [],
      );
    } catch (e) {
      print('Error parsing QuizModel: $e');
      print('Map data: $map');
      rethrow;
    }
  }

  QuizModel copyWith({
    String? id,
    String? name,
    String? classId,
    bool? isVisible,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? questionIds,
  }) {
    return QuizModel(
      id: id ?? this.id,
      name: name ?? this.name,
      classId: classId ?? this.classId,
      isVisible: isVisible ?? this.isVisible,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      questionIds: questionIds ?? this.questionIds,
    );
  }
}