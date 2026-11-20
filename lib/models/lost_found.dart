import 'package:flutter/material.dart' show Color;

class LfItem {
  final String id, emoji, name, where, kind, hidden, by, owner; // kind: Ditemukan | Hilang
  final String? fsId; // id dokumen Firestore lf_items/{id}
  final String? imageUrl; // URL foto barang (opsional)
  final Color bg;
  String status; // Menunggu validasi | Aktif | Diklaim | Selesai | Ditolak
  LfItem(this.id, this.emoji, this.name, this.where, this.kind, this.hidden, this.by, this.owner,
      this.bg, this.status, {this.fsId, this.imageUrl});
}

class LfClaim {
  final String id, owner, desc;
  final String? fsId; // id dokumen Firestore lf_claims/{id}
  final LfItem item;
  String status; // Menunggu | Disetujui | Ditolak | Selesai
  LfClaim(this.id, this.item, this.owner, this.desc, this.status, {this.fsId});
}