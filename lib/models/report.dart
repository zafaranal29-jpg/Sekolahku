class Report {
  final String emoji, title, sub, quote;
  final int count;
  String status; // open | hidden | ignored
  String? id; // Firestore document id (untuk update status)
  Report(this.emoji, this.title, this.sub, this.quote, this.count, [this.status = 'open', this.id]);
}