class TaskModel {
  const TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.pointsReward,
    required this.isActive,
    required this.createdAt,
    this.quiz,
  });

  final String id;
  final String title;
  final String description;
  final String category;
  final int pointsReward;
  final bool isActive;
  final DateTime createdAt;
  final QuizModel? quiz;

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    final pr = json['pointsReward'];
    final points = switch (pr) {
      final num n => n.toInt(),
      final String s => int.tryParse(s) ?? 0,
      _ => 0,
    };

    final rawCreatedAt = json['createdAt'];
    final createdAt = rawCreatedAt is String
        ? DateTime.tryParse(rawCreatedAt) ??
            DateTime.fromMillisecondsSinceEpoch(0)
        : DateTime.fromMillisecondsSinceEpoch(0);

    final rawQuiz = json['quiz'];
    final quiz = rawQuiz is Map<String, dynamic>
        ? QuizModel.fromJson(rawQuiz)
        : null;

    return TaskModel(
      id: (json['id'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      category: (json['category'] as String?) ?? '',
      pointsReward: points,
      isActive: (json['isActive'] as bool?) ?? true,
      createdAt: createdAt,
      quiz: quiz,
    );
  }
}

class QuizModel {
  const QuizModel({
    required this.passScore,
    this.maxAttempts,
    required this.shuffleQuestions,
    required this.questions,
  });

  final int passScore; // 0..100
  final int? maxAttempts; // null => unlimited
  final bool shuffleQuestions;
  final List<QuizQuestionModel> questions;

  factory QuizModel.fromJson(Map<String, dynamic> json) {
    final ps = json['passScore'];
    final passScore = ps is num ? ps.toInt() : int.tryParse('${ps ?? ''}') ?? 70;
    final ma = json['maxAttempts'];
    final maxAttempts =
        ma == null ? null : (ma is num ? ma.toInt() : int.tryParse('$ma'));
    final sh = json['shuffleQuestions'] == true;

    final qs = json['questions'];
    final questions = (qs is List)
        ? qs
            .whereType<Map>()
            .map((e) => QuizQuestionModel.fromJson(
                  Map<String, dynamic>.from(e),
                ))
            .toList(growable: false)
        : const <QuizQuestionModel>[];

    return QuizModel(
      passScore: passScore,
      maxAttempts: maxAttempts,
      shuffleQuestions: sh,
      questions: questions,
    );
  }
}

class QuizQuestionModel {
  const QuizQuestionModel({
    required this.id,
    required this.text,
    required this.multiSelect,
    required this.options,
  });

  final String id;
  final String text;
  final bool multiSelect;
  final List<QuizOptionModel> options;

  factory QuizQuestionModel.fromJson(Map<String, dynamic> json) {
    final opts = json['options'];
    final options = (opts is List)
        ? opts
            .whereType<Map>()
            .map((e) => QuizOptionModel.fromJson(
                  Map<String, dynamic>.from(e),
                ))
            .toList(growable: false)
        : const <QuizOptionModel>[];

    return QuizQuestionModel(
      id: (json['id'] as String?) ?? '',
      text: (json['text'] as String?) ?? '',
      multiSelect: (json['multiSelect'] as bool?) ?? false,
      options: options,
    );
  }
}

class QuizOptionModel {
  const QuizOptionModel({
    required this.id,
    required this.text,
  });

  final String id;
  final String text;

  factory QuizOptionModel.fromJson(Map<String, dynamic> json) {
    return QuizOptionModel(
      id: (json['id'] as String?) ?? '',
      text: (json['text'] as String?) ?? '',
    );
  }
}
