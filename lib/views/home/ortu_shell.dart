import 'package:flutter/material.dart' hide Page;

import 'package:sekolahku/core/theme.dart';
import 'package:sekolahku/models/agenda.dart';
import 'package:sekolahku/models/akademik.dart';
import 'package:sekolahku/models/mading.dart';
import 'package:sekolahku/models/role.dart';
import 'package:sekolahku/models/session.dart';
import 'package:sekolahku/services/academic_stats.dart';
import 'package:sekolahku/services/firebase_service.dart' as firebase_service;
import 'package:sekolahku/views/akademik/perkembangan_screen.dart';
import 'package:sekolahku/views/kalender/kalender_screen.dart';
import 'package:sekolahku/views/mading/mading_views.dart';
import 'package:sekolahku/views/notif/bell_button.dart';
import 'package:sekolahku/widgets/widgets.dart';

/// Shell khusus ORANG TUA (Ortu).
/// Bersifat READ-ONLY:
/// - Tidak ada tombol/fitur aksi admin atau guru (tidak bisa approve, moderasi, buat laporan/pengumuman)
/// - Menampilkan riwayat nilai anak mereka melalui 'Perkembangan Siswa'
/// - Mading & Kalender sekolah hanya bisa dibaca (read-only)
class OrtuShell extends StatefulWidget {
  const OrtuShell({super.key});
  @override
  State<OrtuShell> createState() => _OrtuShellState();
}

class _OrtuShellState extends State<OrtuShell> {
  int i = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: IndexedStack(index: i, children: [
          OrtuHomeTab(onOpenPerkembangan: () => setState(() => i = 1)),
          const PerkembanganScreen(),
          const OrtuMadingTab(),
          const KalenderScreen(),
          const OrtuProfileTab(),
        ]),
        bottomNavigationBar: NavigationBar(
          selectedIndex: i,
          backgroundColor: Colors.white,
          indicatorColor: kSoft,
          onDestinationSelected: (n) => setState(() => i = n),
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Beranda'),
            NavigationDestination(
                icon: Icon(Icons.insights_outlined),
                selectedIcon: Icon(Icons.insights),
                label: 'Nilai'),
            NavigationDestination(
                icon: Icon(Icons.campaign_outlined),
                selectedIcon: Icon(Icons.campaign),
                label: 'Mading'),
            NavigationDestination(
                icon: Icon(Icons.calendar_month_outlined),
                selectedIcon: Icon(Icons.calendar_month),
                label: 'Kalender'),
            NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profil'),
          ],
        ),
      );
}

class OrtuHomeTab extends StatefulWidget {
  final VoidCallback onOpenPerkembangan;
  const OrtuHomeTab({super.key, required this.onOpenPerkembangan});

  @override
  State<OrtuHomeTab> createState() => _OrtuHomeTabState();
}

class _OrtuHomeTabState extends State<OrtuHomeTab> {
  Student? _anak;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final anak = await firebase_service.FirebaseService.i.getStudentForOrtu();
    if (!mounted) return;
    setState(() => _anak = anak);
  }

  @override
  Widget build(BuildContext c) {
    final anak = _anak;
    final avg = anak != null ? averageOf(anak.grades) : 0.0;
    final trend = anak != null ? trendOf(anak.grades) : '—';

    return StreamBuilder<List<Mading>>(
      stream: firebase_service.FirebaseService.i.madingsStream(),
      builder: (context, snap) {
        final all = approvedOf(snap.data ?? const <Mading>[]);
        final pinned = all.where((m) => m.pinned).firstOrNull;

        return Page('', back: false, [
      Row(children: [
        const Emoji('👨‍👩‍👧', size: 48),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Selamat datang,', style: TextStyle(color: kMuted, fontSize: 12)),
            Text('${Session.name} 👋',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          ]),
        ),
        const BellButton(),
      ]),
      const SizedBox(height: 14),

      // Banner kartu anak & perkembangan nilai (Akses Utama Ortu)
      if (anak != null)
        GCard(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Pill('👨‍👩‍👧 Portal Orang Tua', bg: Colors.white24, fg: Colors.white),
                Pill('Read-only', bg: Colors.white24, fg: Colors.white),
              ],
            ),
            const SizedBox(height: 10),
            Text(anak.name,
                style: const TextStyle(
                    color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
            Text('Kelas ${anak.kelas} · NIS ${anak.id}',
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Rata-rata Nilai',
                        style: TextStyle(color: Colors.white70, fontSize: 11)),
                    Text(avg.toStringAsFixed(1),
                        style: const TextStyle(
                            color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                  ]),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Tren Belajar',
                        style: TextStyle(color: Colors.white70, fontSize: 11)),
                    Text(trend,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                  ]),
                  FilledButton(
                    style: FilledButton.styleFrom(
                        backgroundColor: Colors.white, foregroundColor: kPrimary),
                    onPressed: () => go(c, const PerkembanganScreen()),
                    child: const Text('Rincian Nilai ›',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ]),
        ),

      if (pinned != null) ...[
        const H('Pengumuman penting'),
        Card2(
          onTap: () => go(c, MadingDetail(m: pinned)),
          child: Row(children: [
            Emoji(pinned.emoji, bg: pinned.bg),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(pinned.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text('Untuk: ${pinned.target} · ${pinned.time}',
                    style: const TextStyle(color: kMuted, fontSize: 12)),
              ]),
            ),
            const Icon(Icons.chevron_right, color: kMuted),
          ]),
        ),
      ],

      H('Perkembangan Siswa', more: 'Buka grafik', onMore: () => go(c, const PerkembanganScreen())),
      Card2(
        color: kSoft,
        onTap: () => go(c, const PerkembanganScreen()),
        child: const Row(children: [
          Emoji('📊', bg: Colors.white, size: 48),
          SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Pantau Nilai & Riwayat Belajar',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              Text('Lihat nilai UH, UTS, UAS, dan capaian per mata pelajaran anak Anda.',
                  style: TextStyle(color: kMuted, fontSize: 12)),
            ]),
          ),
          Icon(Icons.chevron_right, color: kPrimary),
        ]),
      ),

      H('Mading & Info Sekolah',
          more: 'Lihat semua', onMore: () => go(c, const OrtuMadingTab(wrapInScaffold: true))),
      for (final m in all.where((m) => !m.pinned).take(2)) MadingTile(m),

      StreamBuilder<List<AgendaEvent>>(
        stream: firebase_service.FirebaseService.i.agendasStream(),
        builder: (context, aSnap) {
          final upcoming = (aSnap.data ?? const <AgendaEvent>[]).take(2).toList();
          if (upcoming.isEmpty) return const SizedBox.shrink();
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            H('Agenda Sekolah',
                more: 'Kalender', onMore: () => go(c, const KalenderScreen())),
            for (final e in upcoming)
              infoRow(e.emoji, kSoft, e.title, '${fmtDate(e.date)} · ${e.desc}'),
          ]);
        },
      ),
    ]);
      },
    );
  }
}

/// Tampilan Mading Khusus Ortu: READ ONLY (tanpa Floating Action Button untuk buat mading/pengumuman).
class OrtuMadingTab extends StatefulWidget {
  final bool wrapInScaffold;
  const OrtuMadingTab({super.key, this.wrapInScaffold = false});

  @override
  State<OrtuMadingTab> createState() => _OrtuMadingTabState();
}

class _OrtuMadingTabState extends State<OrtuMadingTab> {
  int f = 0;
  static const cats = ['Semua', 'Akademik', 'Kegiatan', 'Prestasi', 'Karya', 'Info'];

  @override
  Widget build(BuildContext c) {
    return StreamBuilder<List<Mading>>(
      stream: firebase_service.FirebaseService.i.madingsStream(),
      builder: (context, snap) {
        final list = approvedOf(snap.data ?? const <Mading>[])
            .where((m) => f == 0 || m.cat == cats[f])
            .toList();
        final body = Page(
          'Mading & Pengumuman',
          back: widget.wrapInScaffold,
          [
            const Card2(
              color: kSoft,
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(children: [
                Text('👁️', style: TextStyle(fontSize: 18)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Mode Baca Orang Tua: Pengumuman dan mading resmi sekolah.',
                    style: TextStyle(color: kMuted, fontSize: 12),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 4),
            Chips(cats, f, (i) => setState(() => f = i)),
            const H('Terbaru'),
            if (list.isEmpty)
              const Padding(
                padding: EdgeInsets.all(30),
                child: Center(
                    child: Text('Belum ada isi',
                        style: TextStyle(color: kMuted))),
              ),
            for (final m in list) MadingTile(m),
          ],
        );

        return widget.wrapInScaffold ? Scaffold(body: body) : body;
      },
    );
  }
}

class OrtuProfileTab extends StatefulWidget {
  const OrtuProfileTab({super.key});

  @override
  State<OrtuProfileTab> createState() => _OrtuProfileTabState();
}

class _OrtuProfileTabState extends State<OrtuProfileTab> {
  Student? _anak;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final anak = await firebase_service.FirebaseService.i.getStudentForOrtu();
    if (!mounted) return;
    setState(() => _anak = anak);
  }

  @override
  Widget build(BuildContext c) {
    final anak = _anak;

    return Page('Profil Orang Tua', back: false, [
      Card2(
        padding: const EdgeInsets.all(18),
        child: Row(children: [
          const Emoji('👨‍👩‍👧', size: 70),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(Session.name,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const Text('Orang Tua / Wali Siswa',
                  style: TextStyle(color: kMuted, fontSize: 12)),
              const Text('SMA Nusantara 1', style: TextStyle(color: kMuted, fontSize: 12)),
              const SizedBox(height: 6),
              const Pill('Hak Akses: Read-Only', bg: kSoft, fg: kPrimary),
            ]),
          ),
        ]),
      ),
      if (anak != null)
        Card2(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Data Anak yang Ditautkan',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 8),
            Row(children: [
              const Emoji('🧑‍🎓', bg: kYellowBg, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(anak.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text('Kelas ${anak.kelas} · NIS ${anak.id}',
                      style: const TextStyle(color: kMuted, fontSize: 12)),
                ]),
              ),
              OutlinedButton(
                onPressed: () => go(c, const PerkembanganScreen()),
                child: const Text('Nilai'),
              ),
            ]),
          ]),
        ),
      Card2(
        onTap: () => go(c, const PerkembanganScreen()),
        child: const Row(children: [
          Emoji('📈', bg: kGreenBg, size: 46),
          SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Riwayat Nilai Siswa', style: TextStyle(fontWeight: FontWeight.w700)),
              Text('Lihat laporan nilai dan tren belajar anak',
                  style: TextStyle(color: kMuted, fontSize: 12)),
            ]),
          ),
          Icon(Icons.chevron_right, color: kMuted),
        ]),
      ),
      Card2(
        onTap: () => Navigator.pushNamedAndRemoveUntil(c, '/auth', (_) => false),
        child: const Row(children: [
          Emoji('🚪', bg: kRedBg, size: 46),
          SizedBox(width: 12),
          Expanded(
            child: Text('Keluar dari Akun',
                style: TextStyle(fontWeight: FontWeight.w700, color: kRed)),
          ),
          Icon(Icons.chevron_right, color: kMuted),
        ]),
      ),
    ]);
  }
}