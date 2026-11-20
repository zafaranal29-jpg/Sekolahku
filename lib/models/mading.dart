import 'package:flutter/material.dart' show Color;

import 'package:sekolahku/core/theme.dart';

/// kind: 'Pengumuman' (resmi: admin/guru/ketua ekskul) atau 'Mading' (kiriman siswa/guru).
class Mading {
  final String? id; // id dokumen Firestore madings/{id}
  final String emoji, cat, title, target, body, by, owner, kind;
  final Color bg;
  final String? imageUrl; // URL foto unstuck di Firebase Storage (opsional)
  String time, status; // Menunggu | Disetujui | Ditolak
  bool pinned, push, reqPin, reqPush;
  Mading({
    required this.emoji,
    required this.cat,
    required this.title,
    required this.target,
    required this.body,
    this.id,
    this.time = 'Baru saja',
    this.bg = kSoft,
    this.by = 'Admin Sekolah',
    this.owner = '',
    this.kind = 'Pengumuman',
    this.status = 'Disetujui',
    this.pinned = false,
    this.push = false,
    this.reqPin = false,
    this.reqPush = false,
    this.imageUrl,
  });
}