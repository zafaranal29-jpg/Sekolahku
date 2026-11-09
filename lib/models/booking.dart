class BookingReq {
  final String emoji, facility, when, who, owner;
  final String? fsId; // id dokumen Firestore bookings/{id}
  String status; // Menunggu | Disetujui | Ditolak | Dibatalkan
  BookingReq(this.emoji, this.facility, this.when, this.who, this.status,
      [this.owner = '', this.fsId]);
}