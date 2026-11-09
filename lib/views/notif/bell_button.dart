import 'package:flutter/material.dart' hide Page;

import 'package:sekolahku/core/theme.dart';
import 'package:sekolahku/services/notif_service.dart';
import 'package:sekolahku/views/notif/notif_screen.dart';

/// Tombol lonceng dengan lencana jumlah notifikasi belum dibaca. Dipakai semua role.
class BellButton extends StatefulWidget {
  const BellButton({super.key});
  @override
  State<BellButton> createState() => _BellButtonState();
}

class _BellButtonState extends State<BellButton> {
  @override
  Widget build(BuildContext c) {
    return StreamBuilder<int>(
      stream: NotifService.i.unreadStream(),
      builder: (context, snap) {
        final count = snap.data ?? 0;
        return IconButton.filled(
            style: IconButton.styleFrom(backgroundColor: Colors.white),
            onPressed: () => go(c, const NotifScreen()).then((_) {
                  if (mounted) setState(() {});
                }),
            icon: Badge(
                isLabelVisible: count > 0,
                label: Text('$count'),
                child: const Text('🔔', style: TextStyle(fontSize: 20))));
      },
    );
  }
}