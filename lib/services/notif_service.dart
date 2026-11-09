import 'package:flutter/material.dart' show Color;

import 'package:sekolahku/core/theme.dart';
import 'package:sekolahku/models/notif.dart';
import 'package:sekolahku/models/role.dart';
import 'package:sekolahku/services/firebase_service.dart';

/// Notifikasi berbasis Firestore. `notify` menulis dokumen ke `notifications`,
/// `myNotifs`/`unreadStream` membaca stream (kosong saat Firebase belum aktif).
class NotifService {
  static final NotifService i = NotifService._();
  NotifService._();

  Future<void> notify(String emoji, String title, String sub,
      {Color bg = kSoft, String? to, Set<Role>? roles}) {
    return FirebaseService.i.addNotification(
      emoji: emoji,
      title: title,
      sub: sub,
      bg: bg,
      toName: to,
      toRoles: (roles == null || roles.isEmpty) ? null : roles.map((r) => r.name).toList(),
    );
  }

  /// Notifikasi milik pengguna sekarang (sudah difilter `mine`).
  Stream<List<AppNotif>> myNotifs() =>
      FirebaseService.i.notifsStream().map((l) => l.where((n) => n.mine).toList());

  /// Jumlah belum dibaca (untuk badge lonceng).
  Stream<int> unreadStream() => FirebaseService.i
      .notifsStream()
      .map((l) => l.where((n) => n.mine && !n.readForMe).length);

  Future<void> markRead(AppNotif n) {
    if (n.id == null) return Future.value();
    return FirebaseService.i.markNotificationRead(n.id!);
  }
}