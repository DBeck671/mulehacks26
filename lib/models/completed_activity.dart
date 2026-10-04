// A snapshot of one successful attempt, independent of later retries.
class CompletedActivity {
  const CompletedActivity({
    required this.questId,
    required this.title,
    required this.xp,
    required this.attempt,
    required this.completedAt,
    required this.verificationMethod,
  });
  final int questId, xp, attempt;
  final String title, verificationMethod;
  final DateTime completedAt;

  Map<String, Object> toJson() => {
    'questId': questId,
    'title': title,
    'xp': xp,
    'attempt': attempt,
    'completedAt': completedAt.toUtc().toIso8601String(),
    'verificationMethod': verificationMethod,
  };

  factory CompletedActivity.fromJson(Map<String, dynamic> json) =>
      CompletedActivity(
        questId: json['questId'] as int,
        title: json['title'] as String,
        xp: json['xp'] as int,
        attempt: json['attempt'] as int,
        completedAt: DateTime.parse(json['completedAt'] as String),
        verificationMethod: json['verificationMethod'] as String,
      );
}
