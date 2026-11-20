class Complaint {
  final String id, title, loc, by, owner;
  final String? fsId; // id dokumen Firestore complaints/{id}
  final String? imageUrl; // URL foto bukti (opsional)
  String status, pic, reply; // Baru | Diproses | Selesai
  Complaint(this.id, this.title, this.loc, this.by, this.status, this.pic, this.reply, this.owner,
      {this.fsId, this.imageUrl});
}