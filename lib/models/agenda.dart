class AgendaEvent {
  final String? id; // id dokumen Firestore agendas/{id}
  DateTime date;
  String title, desc, emoji;
  AgendaEvent(this.date, this.title, this.desc, this.emoji, {this.id});
}