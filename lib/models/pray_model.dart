class PrayModel {
  final String? id;
  final String name;
  final DateTime date;
  final bool isVisible;
  final String classId;
  final String createdBy;

  PrayModel({
    this.id,
    required this.name,
    required this.date,
    this.isVisible = true,
    required this.classId,
    required this.createdBy,
  });

  factory PrayModel.fromMap(Map<String, dynamic> map) {
    return PrayModel(
      id: map['\$id'] as String?,
      name: map['name']?.toString() ?? '',
      date: DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
      isVisible: map['isVisible'] as bool? ?? true,
      classId: map['classId']?.toString() ?? '',
      createdBy: map['createdBy']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'date': date.toIso8601String(),
      'isVisible': isVisible,
      'classId': classId,
      'createdBy': createdBy,
    };
  }
}