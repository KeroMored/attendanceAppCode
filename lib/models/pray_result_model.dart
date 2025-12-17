class PrayResultModel {
  final String? id;
  final String solverId;
  final String solverName;
  final String prayId;
  final String classId;
  final DateTime completedAt;

  PrayResultModel({
    this.id,
    required this.solverId,
    required this.solverName,
    required this.prayId,
    required this.classId,
    required this.completedAt,
  });

  factory PrayResultModel.fromMap(Map<String, dynamic> map) {
    return PrayResultModel(
      id: map['\$id'] as String?,
      solverId: map['solverId']?.toString() ?? '',
      solverName: map['solverName']?.toString() ?? '',
      prayId: map['prayId']?.toString() ?? '',
      classId: map['classId']?.toString() ?? '',
      completedAt: DateTime.tryParse(map['completedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'solverId': solverId,
      'solverName': solverName,
      'prayId': prayId,
      'classId': classId,
      'completedAt': completedAt.toIso8601String(),
    };
  }
}