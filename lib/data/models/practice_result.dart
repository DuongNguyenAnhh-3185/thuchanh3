class PracticeResult {
  final String sessionId;
  final String lessonId;
  final String userId;
  final String completedAt;
  final int activeDurationSeconds;
  final String status;
  final ScoreBreakdown scores;
  final String transcript;
  final String targetText;
  final List<WordEvaluation> words;
  final List<String> feedbackTips;

  PracticeResult({
    required this.sessionId,
    required this.lessonId,
    required this.userId,
    required this.completedAt,
    required this.activeDurationSeconds,
    required this.status,
    required this.scores,
    required this.transcript,
    required this.targetText,
    required this.words,
    required this.feedbackTips,
  });

  factory PracticeResult.fromJson(Map<String, dynamic> json) {
    return PracticeResult(
      sessionId: json['sessionId'] as String? ?? '',
      lessonId: json['lessonId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      completedAt: json['completedAt'] as String? ?? DateTime.now().toUtc().toIso8601String(),
      activeDurationSeconds: (json['activeDurationSeconds'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'completed',
      scores: ScoreBreakdown.fromJson(json['scores'] as Map<String, dynamic>? ?? {}),
      transcript: json['transcript'] as String? ?? '',
      targetText: json['targetText'] as String? ?? '',
      words: (json['words'] as List<dynamic>?)
              ?.map((item) => WordEvaluation.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      feedbackTips: (json['feedbackTips'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'lessonId': lessonId,
      'userId': userId,
      'completedAt': completedAt,
      'activeDurationSeconds': activeDurationSeconds,
      'status': status,
      'scores': scores.toJson(),
      'transcript': transcript,
      'targetText': targetText,
      'words': words.map((w) => w.toJson()).toList(),
      'feedbackTips': feedbackTips,
    };
  }
}

class ScoreBreakdown {
  final double? overall;
  final double? accuracy;
  final double? fluency;
  final double? completeness;

  ScoreBreakdown({
    this.overall,
    this.accuracy,
    this.fluency,
    this.completeness,
  });

  factory ScoreBreakdown.fromJson(Map<String, dynamic> json) {
    return ScoreBreakdown(
      overall: (json['overall'] as num?)?.toDouble(),
      accuracy: (json['accuracy'] as num?)?.toDouble(),
      fluency: (json['fluency'] as num?)?.toDouble(),
      completeness: (json['completeness'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'overall': overall,
      'accuracy': accuracy,
      'fluency': fluency,
      'completeness': completeness,
    };
  }
}

class WordEvaluation {
  final String word;
  final String ipa;
  final double score;
  final String status; // 'correct', 'warning', 'incorrect'
  final List<PhonemeEvaluation> phonemes;

  WordEvaluation({
    required this.word,
    required this.ipa,
    required this.score,
    required this.status,
    required this.phonemes,
  });

  factory WordEvaluation.fromJson(Map<String, dynamic> json) {
    return WordEvaluation(
      word: json['word'] as String? ?? '',
      ipa: json['ipa'] as String? ?? '',
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'correct',
      phonemes: (json['phonemes'] as List<dynamic>?)
              ?.map((p) => PhonemeEvaluation.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'word': word,
      'ipa': ipa,
      'score': score,
      'status': status,
      'phonemes': phonemes.map((p) => p.toJson()).toList(),
    };
  }
}

class PhonemeEvaluation {
  final String phoneme;
  final String ipaExpected;
  final String ipaActual;
  final double score;
  final bool isCorrect;

  PhonemeEvaluation({
    required this.phoneme,
    required this.ipaExpected,
    required this.ipaActual,
    required this.score,
    required this.isCorrect,
  });

  factory PhonemeEvaluation.fromJson(Map<String, dynamic> json) {
    return PhonemeEvaluation(
      phoneme: json['phoneme'] as String? ?? '',
      ipaExpected: json['ipaExpected'] as String? ?? '',
      ipaActual: json['ipaActual'] as String? ?? '',
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      isCorrect: json['isCorrect'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'phoneme': phoneme,
      'ipaExpected': ipaExpected,
      'ipaActual': ipaActual,
      'score': score,
      'isCorrect': isCorrect,
    };
  }
}
