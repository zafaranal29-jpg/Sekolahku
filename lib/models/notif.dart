import 'package:flutter/material.dart' show Color;

import 'role.dart';
import 'session.dart';

class AppNotif {
  final String? id; // id dokumen Firestore notifications/{id}
  final String emoji, title, sub;
  final Color bg;
  final String? toName; // ditujukan ke satu orang
  final Set<Role>? toRoles; // atau ke beberapa role (null = semua)
  String time;
  Set<String> readBy; // nama-nama yang sudah membaca
  AppNotif(this.emoji, this.title, this.sub, this.bg,
      {this.id,
      this.toName,
      this.toRoles,
      this.time = 'Baru saja',
      Set<String>? readBy})
      : readBy = readBy ?? <String>{};
  bool get mine =>
      toName != null ? toName == Session.name : (toRoles == null || toRoles!.contains(Session.role));
  bool get readForMe => readBy.contains(Session.name);
}