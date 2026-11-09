const aduanKinds = ['Perundungan', 'Kekerasan / pelecehan', 'Aspirasi / saran', 'Lainnya'];

class Aduan {
  final String id, kind, body, owner;
  final bool anon; // kalau true, admin tidak melihat identitas pelapor
  final String? fsId; // id dokumen Firestore aduans/{id}
  String status, reply; // Baru | Diproses | Selesai
  Aduan(this.id, this.kind, this.body, this.owner, this.anon, this.status, this.reply,
      {this.fsId});
}