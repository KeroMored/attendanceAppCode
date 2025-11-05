class QuizResultModel {
  final String? id;
  final String solverId;      // Changed from participantName to solverId
  final String solverName;    // Added to store the name
  final String quizId;
  final String classId;
  final int score;
  final int totalQuestions;
  final List<String> answers;
  final DateTime completedAt;
  final int? timeTaken; // in seconds

  QuizResultModel({
    this.id,
    required this.solverId,
    required this.solverName,
    required this.quizId,
    required this.classId,
    required this.score,
    required this.totalQuestions,
    required this.answers,
    required this.completedAt,
    this.timeTaken,
  });

  double get percentage => totalQuestions > 0 ? (score / totalQuestions) * 100 : 0;

  String get gradeText {
    final percent = percentage;
    if (percent >= 90) return 'ممتاز';
    if (percent >= 80) return 'جيد جداً';
    if (percent >= 70) return 'جيد';
    if (percent >= 60) return 'مقبول';
    return 'ضعيف';
  }

  factory QuizResultModel.fromMap(Map<String, dynamic> map) {
    try {
      return QuizResultModel(
        id: map['\$id'] as String?,
        solverId: map['solverId']?.toString() ?? '',
        solverName: map['solverName']?.toString() ?? '',
        quizId: map['quizId']?.toString() ?? '',
        classId: map['classId']?.toString() ?? '',
        score: int.tryParse(map['score']?.toString() ?? '0') ?? 0,
        totalQuestions: int.tryParse(map['totalQuestions']?.toString() ?? '0') ?? 0,
        answers: (map['answers'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        completedAt: DateTime.tryParse(map['completedAt']?.toString() ?? '') ?? DateTime.now(),
        timeTaken: int.tryParse(map['timeTaken']?.toString() ?? '0'),
      );
    } catch (e) {
      print('Error parsing QuizResultModel: $e');
      print('Map data: $map');
      rethrow;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'solverId': solverId,
      'solverName': solverName,
      'quizId': quizId,
      'classId': classId,
      'score': score,
      'totalQuestions': totalQuestions,
      'answers': answers,
      'completedAt': completedAt.toIso8601String(),
      if (timeTaken != null) 'timeTaken': timeTaken,
    };
  }
}