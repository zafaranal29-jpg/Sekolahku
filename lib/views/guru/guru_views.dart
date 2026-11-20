import 'package:flutter/material.dart' hide Page;

import 'package:sekolahku/core/theme.dart';
import 'package:sekolahku/models/mading.dart';
import 'package:sekolahku/models/session.dart';
import 'package:sekolahku/services/firebase_service.dart' as firebase_service;
import 'package:sekolahku/widgets/widgets.dart';

// Alat bantu khusus guru (dibuka dari tab Layanan).
class AnalitikScreen extends StatefulWidget {
  const AnalitikScreen({super.key});
  @override
  State<AnalitikScreen> createState() => _AnalitikState();
}

class _AnalitikState extends State<AnalitikScreen> {
  int scope = 1;
  @override
  Widget build(BuildContext c) {
    final s = scope == 0
        ? [
            ('96%', 'Pengumuman terbaca', kSoft),
            ('1,8 hari', 'Rata-rata penanganan', kGreenBg),
            ('6', 'Pengaduan bulan ini', kRedBg),
            ('Rp 410rb', 'Jajan kelas', kYellowBg)
          ]
        : [
            ('92%', 'Pengumuman terbaca', kSoft),
            ('2,4 hari', 'Rata-rata penanganan', kGreenBg),
            ('47', 'Pengaduan bulan ini', kRedBg),
            ('Rp 3,2jt', 'Penjualan koperasi', kYellowBg)
          ];
    return Page('Dashboard analitik', [
      SegmentedButton<int>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: 0, label: Text('Kelas saya')),
            ButtonSegment(value: 1, label: Text('Seluruh sekolah'))
          ],
          selected: {scope},
          onSelectionChanged: (v) => setState(() => scope = v.first)),
      const SizedBox(height: 10),
      Row(children: [statBox(s[0].$1, s[0].$2, s[0].$3), statBox(s[1].$1, s[1].$2, s[1].$3)]),
      Row(children: [statBox(s[2].$1, s[2].$2, s[2].$3), statBox(s[3].$1, s[3].$2, s[3].$3)]),
      const SizedBox(height: 6),
      MiniBars('Tren pengaduan · 6 minggu',
          scope == 0 ? [.3, .5, .4, .6, .35, .25] : [.5, .7, .45, .9, .7, .5],
          const ['M1', 'M2', 'M3', 'M4', 'M5', 'M6']),
      const MiniBars('Penggunaan fasilitas', [.7, .5, .9, .4, .6], ['Lap', 'Lab', 'Aula', 'Rg', 'Pst']),
    ]);
  }
}

class StatusTerbaca extends StatefulWidget {
  const StatusTerbaca({super.key});
  @override
  State<StatusTerbaca> createState() => _StatusTerbacaState();
}

class _StatusTerbacaState extends State<StatusTerbaca> {
  static const names = [
    ('Andi Saputra', 'XI IPA 1'),
    ('Bella Anindya', 'XI IPA 2'),
    ('Dimas Pratama', 'XI IPA 2'),
    ('Eka Wulandari', 'XI IPA 3')
  ];
  final reminded = <String>{};
  @override
  Widget build(BuildContext c) {
    return StreamBuilder<List<Mading>>(
      stream: firebase_service.FirebaseService.i.madingsStream(),
      builder: (context, snap) {
        final mine = (snap.data ?? const <Mading>[])
            .where((m) =>
                m.owner == Session.name &&
                m.kind == 'Pengumuman' &&
                m.status == 'Disetujui')
            .firstOrNull;
        return Page('Status terbaca',
        bottom: Btn('Ingatkan semua (20)', () {
          setState(() => reminded.addAll(names.map((n) => n.$1)));
          toast(c, 'Pengingat dikirim ke 20 siswa');
        }),
        [
          Card2(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(mine?.title ?? 'Belum ada pengumumanmu yang terbit',
                style: const TextStyle(fontWeight: FontWeight.w700)),
            Text('Target: ${mine?.target ?? '-'} · 105 siswa',
                style: const TextStyle(color: kMuted, fontSize: 12)),
            const SizedBox(height: 8),
            const LinearProgressIndicator(
                value: 85 / 105, color: kPrimary, backgroundColor: kSoft, minHeight: 8),
            const SizedBox(height: 6),
            const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('✓ 85 sudah baca', style: TextStyle(fontSize: 12)),
                  Text('20 belum', style: TextStyle(fontSize: 12, color: kMuted))
                ]),
          ])),
          const H('Belum membaca'),
          for (final n in names)
            infoRow('🧑', kSoft, n.$1, n.$2,
                trailing: reminded.contains(n.$1)
                    ? const Text('Terkirim ✓', style: TextStyle(color: kGreen, fontSize: 12))
                    : TextButton(
                        onPressed: () => setState(() => reminded.add(n.$1)),
                        child: const Text('Ingatkan'))),
        ]);
      },
    );
  }
}