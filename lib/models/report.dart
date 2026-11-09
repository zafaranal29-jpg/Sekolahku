class Report {
  final String emoji, title, sub, quote;
  final int count;
  String status; // open | hidden | ignored
  Report(this.emoji, this.title, this.sub, this.quote, this.count, [this.status = 'open']);
}