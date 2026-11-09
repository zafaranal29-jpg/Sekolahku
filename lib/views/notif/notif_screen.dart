import 'package:flutter/material.dart' hide Page;

import 'package:sekolahku/core/theme.dart';
import 'package:sekolahku/models/notif.dart';
import 'package:sekolahku/services/notif_service.dart';
import 'package:sekolahku/widgets/widgets.dart';

class NotifScreen extends StatefulWidget {
  const NotifScreen({super.key});
  @override
  State<NotifScreen> createState() => _NotifState();
}

class _NotifState extends State<NotifScreen> {
  @override
  void initState() {
    super.initState();
    // Tandai semua notifikasi yang belum dibaca sebagai sudah dibaca saat dibuka.
    NotifService.i.myNotifs().first.then((list) {
      for (final n in list.where((n) => !n.readForMe)) {
        NotifService.i.markRead(n);
      }
    });
  }

  Widget _tile(AppNotif n) => Card2(
          child: Row(children: [
        Emoji(n.emoji, bg: n.bg),
        const SizedBox(width: 12),
        Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(n.title, style: const TextStyle(fontWeight: FontWeight.w700)),
          Text('${n.sub} · ${n.time}', style: const TextStyle(color: kMuted, fontSize: 12)),
        ])),
        if (!n.readForMe) const CircleAvatar(radius: 4, backgroundColor: kRed),
      ]));

  @override
  Widget build(BuildContext c) {
    return Page('Notifikasi', [
      StreamBuilder<List<AppNotif>>(
        stream: NotifService.i.myNotifs(),
        builder: (context, snap) {
          final mine = snap.data ?? const <AppNotif>[];
          if (mine.isEmpty) {
            return const Padding(
                padding: EdgeInsets.all(40),
                child: Center(
                    child: Text('Belum ada notifikasi',
                        style: TextStyle(color: kMuted))));
          }
          final baru = mine.where((n) => !n.readForMe).toList();
          final lama = mine.where((n) => n.readForMe).toList();
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (baru.isNotEmpty) ...[
              const Text('Baru',
                  style: TextStyle(color: kMuted, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              for (final n in baru) _tile(n),
            ],
            if (lama.isNotEmpty) ...[
              const SizedBox(height: 6),
              const Text('Sebelumnya',
                  style: TextStyle(color: kMuted, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              for (final n in lama) _tile(n),
            ],
          ]);
        },
      ),
    ]);
  }
}