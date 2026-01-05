class SubmissionActionResult {
  const SubmissionActionResult({
    required this.submission,
    this.balance,
  });

  final SubmissionActionSubmission submission;
  final int? balance;

  factory SubmissionActionResult.fromJson(Map<String, dynamic> json) {
    final submissionRaw = json['submission'];

    int? balance;
    final balRaw = json['balance'];
    if (balRaw is num) balance = balRaw.toInt();
    if (balRaw is String) balance = int.tryParse(balRaw);

    return SubmissionActionResult(
      submission: submissionRaw is Map
          ? SubmissionActionSubmission.fromJson(
              Map<String, dynamic>.from(submissionRaw),
            )
          : const SubmissionActionSubmission(
              id: '',
              status: '',
              decidedAt: null,
              decidedById: null,
              rewardPointsApplied: null,
              commentAdmin: null,
            ),
      balance: balance,
    );
  }
}

class SubmissionActionSubmission {
  const SubmissionActionSubmission({
    required this.id,
    required this.status,
    required this.decidedAt,
    required this.decidedById,
    required this.rewardPointsApplied,
    required this.commentAdmin,
  });

  final String id;
  final String status;
  final DateTime? decidedAt;
  final String? decidedById;
  final int? rewardPointsApplied;
  final String? commentAdmin;

  factory SubmissionActionSubmission.fromJson(Map<String, dynamic> json) {
    final decidedAtRaw = json['decidedAt'];
    DateTime? decidedAt;
    if (decidedAtRaw is String) decidedAt = DateTime.tryParse(decidedAtRaw);
    if (decidedAtRaw is int) decidedAt = DateTime.fromMillisecondsSinceEpoch(decidedAtRaw);
    if (decidedAtRaw is num) {
      decidedAt = DateTime.fromMillisecondsSinceEpoch(decidedAtRaw.toInt());
    }

    final rewardRaw = json['rewardPointsApplied'];
    int? rewardPointsApplied;
    if (rewardRaw is num) rewardPointsApplied = rewardRaw.toInt();
    if (rewardRaw is String) rewardPointsApplied = int.tryParse(rewardRaw);

    final commentAdmin = (json['commentAdmin'] as String?)?.trim();

    return SubmissionActionSubmission(
      id: json['id']?.toString() ?? '',
      status: (json['status'] ?? '') as String,
      decidedAt: decidedAt,
      decidedById: json['decidedById']?.toString(),
      rewardPointsApplied: rewardPointsApplied,
      commentAdmin: (commentAdmin == null || commentAdmin.isEmpty) ? null : commentAdmin,
    );
  }
}
