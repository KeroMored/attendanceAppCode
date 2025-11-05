class QuestionModel {
  final String? id;
  final String quizId;
  final String questionText;
  final String choiceA;
  final String choiceB;
  final String choiceC;
  final String choiceD;
  final String correctAnswer; // 'A', 'B', 'C', or 'D'
  final int questionOrder;
  final DateTime createdAt;

  QuestionModel({
    this.id,
    required this.quizId,
    required this.questionText,
    required this.choiceA,
    required this.choiceB,
    required this.choiceC,
    required this.choiceD,
    required this.correctAnswer,
    required this.questionOrder,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'quizId': quizId,
      'questionText': questionText,
      'choiceA': choiceA,
      'choiceB': choiceB,
      'choiceC': choiceC,
      'choiceD': choiceD,
      'correctAnswer': correctAnswer,
      'questionOrder': questionOrder,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory QuestionModel.fromMap(Map<String, dynamic> map) {
    try {
      return QuestionModel(
        id: map['\$id'],
        quizId: map['quizId']?.toString() ?? '',
        questionText: map['questionText']?.toString() ?? '',
        choiceA: map['choiceA']?.toString() ?? '',
        choiceB: map['choiceB']?.toString() ?? '',
        choiceC: map['choiceC']?.toString() ?? '',
        choiceD: map['choiceD']?.toString() ?? '',
        correctAnswer: map['correctAnswer']?.toString() ?? 'A',
        questionOrder: map['questionOrder'] is int ? map['questionOrder'] : 1,
        createdAt: map['createdAt'] != null 
            ? DateTime.parse(map['createdAt'].toString()) 
            : DateTime.now(),
      );
    } catch (e) {
      print('Error parsing QuestionModel: $e');
      print('Map data: $map');
      rethrow;
    }
  }

  QuestionModel copyWith({
    String? id,
    String? quizId,
    String? questionText,
    String? choiceA,
    String? choiceB,
    String? choiceC,
    String? choiceD,
    String? correctAnswer,
    int? questionOrder,
    DateTime? createdAt,
  }) {
    return QuestionModel(
      id: id ?? this.id,
      quizId: quizId ?? this.quizId,
      questionText: questionText ?? this.questionText,
      choiceA: choiceA ?? this.choiceA,
      choiceB: choiceB ?? this.choiceB,
      choiceC: choiceC ?? this.choiceC,
      choiceD: choiceD ?? this.choiceD,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      questionOrder: questionOrder ?? this.questionOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String getChoiceText(String choice) {
    switch (choice.toLowerCase()) {
      case 'a':
        return choiceA;
      case 'b':
        return choiceB;
      case 'c':
        return choiceC;
      case 'd':
        return choiceD;
      default:
        return '';
    }
  }

  bool isCorrectAnswer(String selectedChoice) {
    return selectedChoice.toLowerCase() == correctAnswer.toLowerCase();
  }
}