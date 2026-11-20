import 'package:flutter/material.dart' hide Page;

import 'package:sekolahku/core/theme.dart';
import 'package:sekolahku/models/aduan.dart';
import 'package:sekolahku/models/agenda.dart';
import 'package:sekolahku/models/booking.dart';
import 'package:sekolahku/models/complaint.dart';
import 'package:sekolahku/models/lost_found.dart';
import 'package:sekolahku/models/mading.dart';
import 'package:sekolahku/models/order.dart';
import 'package:sekolahku/models/role.dart';
import 'package:sekolahku/models/session.dart';
import 'package:sekolahku/services/firebase_service.dart' as firebase_service;
import 'package:sekolahku/views/aduan/aduan_views.dart';
import 'package:sekolahku/views/akademik/perkembangan_screen.dart';
import 'package:sekolahku/views/auth/auth_screen.dart' show ChangePasswordScreen;
import 'package:sekolahku/views/booking/booking_views.dart';
import 'package:sekolahku/views/guru/guru_views.dart';
import 'package:sekolahku/views/kalender/kalender_screen.dart';
import 'package:sekolahku/views/koperasi/koperasi_views.dart';
import 'package:sekolahku/views/lost_found/lost_found_views.dart';
import 'package:sekolahku/views/mading/mading_views.dart';
import 'package:sekolahku/views/notif/bell_button.dart';
import 'package:sekolahku/views/pengaduan/pengaduan_views.dart';
import 'package:sekolahku/widgets/widgets.dart';

/// Beranda untuk SISWA dan GURU (fitur sama; guru/ketua ekskul bisa buat pengumuman,
/// guru bisa memantau perkembangan siswa & analitik).
class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int i = 0;
  @override
  Widget build(BuildContext context) => Scaffold(
        body: IndexedStack(index: i, children: [
          HomeTab(onTab: (n) => setState(() => i = n)),
          const ServicesTab(),
          const KoperasiTab(),
          ActivityTab(key: ValueKey(i)),
          const ProfileTab(),
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
                  icon: Icon(Icons.extension_outlined),
                  selectedIcon: Icon(Icons.extension),
                  label: 'Layanan'),
              NavigationDestination(
                  icon: Icon(Icons.shopping_cart_outlined),
                  selectedIcon: Icon(Icons.shopping_cart),
                  label: 'Koperasi'),
              NavigationDestination(
                  icon: Icon(Icons.assignment_outlined),
                  selectedIcon: Icon(Icons.assignment),
                  label: 'Aktivitas'),
              NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: 'Profil'),
            ]),
      );
}

String _avatar() => switch (Session.role) {
      Role.guru => '👩‍🏫',
      Role.ortu => '👨‍👩‍👧',
      _ => '🧑‍🎓',
    };

class HomeTab extends StatelessWidget {
  final void Function(int) onTab;
  const HomeTab({super.key, required this.onTab});
  @override
  Widget build(BuildContext c) {
    return StreamBuilder<List<Mading>>(
      stream: firebase_service.FirebaseService.i.madingsStream(),
      builder: (context, snap) {
        final all = approvedOf(snap.data ?? const <Mading>[]);
        final pinned = all.where((m) => m.pinned).firstOrNull;
        return Page('', back: false, [
      Row(children: [
        Emoji(_avatar(), size: 48),
        const SizedBox(width: 12),
        Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Selamat pagi,', style: TextStyle(color: kMuted, fontSize: 12)),
          Text('${Session.name} 👋',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        ])),
        const BellButton(),
      ]),
      const SizedBox(height: 14),
      if (pinned != null)
        GCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Pill('📌 Pengumuman penting', bg: Colors.white24, fg: Colors.white),
          const SizedBox(height: 8),
          Text(pinned.title,
              style: const TextStyle(
                  color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
          Text('Untuk: ${pinned.target}', style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 12),
          FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: Colors.white, foregroundColor: kPrimary),
              onPressed: () => go(c, MadingDetail(m: pinned)),
              child: const Text('Baca selengkapnya ›')),
        ])),

      // Pintasan khusus Guru: Pantau Perkembangan Siswa
      if (Session.role == Role.guru)
        Card2(
          color: kSoft,
          onTap: () => go(c, const PerkembanganScreen()),
          child: const Row(children: [
            Emoji('📊', bg: Colors.white, size: 44),
            SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Perkembangan Siswa', style: TextStyle(fontWeight: FontWeight.w700)),
                Text('Pantau grafik nilai dan riwayat belajar siswa binaan',
                    style: TextStyle(color: kMuted, fontSize: 12)),
              ]),
            ),
            Icon(Icons.chevron_right, color: kPrimary),
          ]),
        ),

      const H('Akses cepat'),
      Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        for (final q in [
          ('🍱', 'Koperasi', kYellowBg, () => onTab(2)),
          ('🛠️', 'Pengaduan', kRedBg, () => go(c, const PengaduanScreen())),
          ('🎒', 'Lost&Found', kGreenBg, () => go(c, const LostFoundScreen())),
          ('🏟️', 'Booking', kBlueBg, () => go(c, const BookingScreen())),
          ('📅', 'Kalender', kSoft, () => go(c, const KalenderScreen())),
        ])
          GestureDetector(
              onTap: q.$4,
              child: Column(children: [
                Emoji(q.$1, bg: q.$3, size: 56),
                const SizedBox(height: 6),
                Text(q.$2, style: const TextStyle(fontSize: 11)),
              ])),
      ]),
      if (Session.canAnnounce) ...[
        const SizedBox(height: 12),
        Card2(
            color: kYellowBg,
            onTap: () => go(c, const MadingForm(kind: 'Pengumuman')),
            child: Row(children: [
              const Emoji('📢', bg: Colors.white, size: 44),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                    Session.isKetua
                        ? 'Buat pengumuman ekskul ${Session.ketuaOf}'
                        : 'Buat pengumuman',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const Text('Akan di-ACC admin sebelum terbit',
                    style: TextStyle(color: kAmber, fontSize: 12)),
              ])),
              const Icon(Icons.chevron_right, color: kMuted),
            ])),
      ],
      H('Mading & pengumuman',
          more: 'Lihat semua', onMore: () => go(c, const MadingList())),
      for (final m in all.where((m) => !m.pinned).take(2)) MadingTile(m),
      StreamBuilder<List<AgendaEvent>>(
        stream: firebase_service.FirebaseService.i.agendasStream(),
        builder: (context, aSnap) {
          final upcoming = (aSnap.data ?? const <AgendaEvent>[]).take(2).toList();
          if (upcoming.isEmpty) return const SizedBox.shrink();
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            H('Agenda terdekat',
                more: 'Kalender', onMore: () => go(c, const KalenderScreen())),
            for (final e in upcoming)
              infoRow(e.emoji, kSoft, e.title, '${fmtDate(e.date)} · ${e.desc}'),
          ]);
        },
      ),
      StreamBuilder<List<Order>>(
        stream: firebase_service.FirebaseService.i.ordersStream(),
        builder: (context, oSnap) {
          final order = (oSnap.data ?? const <Order>[])
              .where((o) => o.owner == Session.name && o.status != 'Selesai')
              .firstOrNull;
          if (order == null) return const SizedBox.shrink();
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const H('Pesanan aktif'),
            Card2(
                child: Row(children: [
              const Emoji('🥪', bg: kYellowBg),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Pesanan #${order.id}', style: const TextStyle(fontWeight: FontWeight.w700)),
                Text('Ambil ${order.slot}', style: const TextStyle(color: kMuted, fontSize: 12)),
              ])),
              Pill.status(order.status),
            ])),
          ]);
        },
      ),
    ]);
      },
    );
  }
}

// ================= LAYANAN / AKTIVITAS / PROFIL =================
class ServicesTab extends StatelessWidget {
  const ServicesTab({super.key});
  @override
  Widget build(BuildContext c) {
    final items = <(String, String, String, Color, Widget)>[
      ('📌', 'Mading & Pengumuman', 'Baca, upload mading (ACC admin)', kSoft, const MadingList()),
      ('📅', 'Kalender agenda', 'Jadwal kegiatan sekolah', kBlueBg, const KalenderScreen()),
      ('🛠️', 'Pengaduan fasilitas', 'Laporkan kerusakan & pantau status', kRedBg,
          const PengaduanScreen()),
      ('🛡️', 'Lapor & Aspirasi', 'Perundungan, kekerasan, saran · bisa anonim', kRedBg,
          const AduanScreen()),
      ('🎒', 'Lost & Found', 'Barang hilang dan ditemukan', kGreenBg, const LostFoundScreen()),
      ('🏟️', 'Booking fasilitas', 'Lapangan, lab, aula (ACC admin)', kYellowBg,
          const BookingScreen()),
      // Fitur Perkembangan Siswa bisa diakses oleh Guru dan Siswa
      ('📈', 'Perkembangan Siswa', 'Riwayat nilai & evaluasi akademik', kSoft,
          const PerkembanganScreen()),
      if (Session.role == Role.guru)
        ('📊', 'Dashboard analitik', 'Statistik kelas & sekolah', kSoft,
            const AnalitikScreen()),
      if (Session.role == Role.guru)
        ('👀', 'Status terbaca', 'Pantau siapa yang belum membaca', kBlueBg,
            const StatusTerbaca()),
    ];
    return Page('Layanan', back: false, [
      if (Session.canAnnounce)
        Card2(
            color: kYellowBg,
            onTap: () => go(c, const MadingForm(kind: 'Pengumuman')),
            child: Row(children: [
              const Emoji('📢', bg: Colors.white, size: 56),
              const SizedBox(width: 14),
              Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                    Session.isKetua
                        ? 'Pengumuman ekskul ${Session.ketuaOf}'
                        : 'Buat pengumuman',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(
                    Session.isKetua
                        ? 'Sebagai Ketua Ekskul · ACC admin'
                        : 'Sematkan & push diputuskan admin',
                    style: const TextStyle(color: kAmber, fontSize: 12)),
              ])),
              const Icon(Icons.chevron_right, color: kMuted),
            ])),
      for (final s in items)
        Card2(
            onTap: () => go(c, s.$5),
            child: Row(children: [
              Emoji(s.$1, bg: s.$4, size: 56),
              const SizedBox(width: 14),
              Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.$2, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(s.$3, style: const TextStyle(color: kMuted, fontSize: 12)),
              ])),
              const Icon(Icons.chevron_right, color: kMuted),
            ])),
    ]);
  }
}

List<(String, String, String, String, Color)> _activityItems(
  String me, {
  required List<Order> orders,
  required List<Complaint> complaints,
  required List<Aduan> aduans,
  required List<BookingReq> bookings,
  required List<LfItem> items,
  required List<LfClaim> claims,
  required List<Mading> madings,
}) => [
      for (final o in orders.where((o) => o.owner == me))
        ('🥪', 'Pesanan #${o.id}', 'Ambil ${o.slot}', o.status, kYellowBg),
      for (final x in complaints.where((x) => x.owner == me))
        ('🛠️', 'Laporan: ${x.title}', '#${x.id}', x.status, kRedBg),
      for (final a in aduans.where((a) => a.owner == me))
        ('🛡️', '${a.kind} #${a.id}', a.anon ? 'Anonim' : 'Dengan nama', a.status, kSoft),
      for (final b in bookings.where((b) => b.owner == me))
        ('🏟️', 'Booking ${b.facility}', b.when, b.status, kYellowBg),
      for (final i in items.where((i) => i.owner == me))
        ('🎒', 'Posting: ${i.name}', i.kind, i.status, kGreenBg),
      for (final k in claims.where((k) => k.owner == me))
        ('🧴', 'Klaim ${k.item.name}', '#${k.id}', k.status, kBlueBg),
      for (final m in madings.where((m) => m.owner == me))
        (m.emoji, '${m.kind}: ${m.title}', m.time, m.status, m.bg),
    ];

class ActivityTab extends StatelessWidget {
  const ActivityTab({super.key});
  @override
  Widget build(BuildContext c) {
    final me = Session.name;
    return StreamBuilder<List<Order>>(
      stream: firebase_service.FirebaseService.i.ordersStream(),
      builder: (context, oSnap) {
        return StreamBuilder<List<Complaint>>(
          stream: firebase_service.FirebaseService.i.complaintsStream(),
          builder: (context, cSnap) {
            return StreamBuilder<List<Aduan>>(
              stream: firebase_service.FirebaseService.i.aduansStream(),
              builder: (context, aSnap) {
                return StreamBuilder<List<BookingReq>>(
                  stream: firebase_service.FirebaseService.i.bookingsStream(),
                  builder: (context, bSnap) {
                    return StreamBuilder<List<LfItem>>(
                      stream: firebase_service.FirebaseService.i.lfItemsStream(),
                      builder: (context, iSnap) {
                        return StreamBuilder<List<LfClaim>>(
                          stream: firebase_service.FirebaseService.i.lfClaimsStream(),
                          builder: (context, kSnap) {
                            return StreamBuilder<List<Mading>>(
                              stream: firebase_service.FirebaseService.i.madingsStream(),
                              builder: (context, mSnap) {
                                final items = _activityItems(me,
                                    orders: oSnap.data ?? const <Order>[],
                                    complaints: cSnap.data ?? const <Complaint>[],
                                    aduans: aSnap.data ?? const <Aduan>[],
                                    bookings: bSnap.data ?? const <BookingReq>[],
                                    items: iSnap.data ?? const <LfItem>[],
                                    claims: kSnap.data ?? const <LfClaim>[],
                                    madings: mSnap.data ?? const <Mading>[]);
                                return Page('Aktivitas saya', back: false, [
                                  if (items.isEmpty)
                                    const Padding(
                                        padding: EdgeInsets.all(40),
                                        child: Center(
                                            child: Text('Belum ada aktivitas',
                                                style: TextStyle(color: kMuted)))),
                                  for (final a in items)
                                    Card2(
                                        child: Row(children: [
                                      Emoji(a.$1, bg: a.$5),
                                      const SizedBox(width: 12),
                                      Expanded(
                                          child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                            Text(a.$2,
                                                style:
                                                    const TextStyle(fontWeight: FontWeight.w700)),
                                            Text(a.$3,
                                                style: const TextStyle(
                                                    color: kMuted, fontSize: 12)),
                                          ])),
                                      Pill.status(a.$4),
                                    ])),
                                ]);
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});
  @override
  Widget build(BuildContext c) {
    final guru = Session.role == Role.guru;
    final me = Session.name;
    return Page('Profil', back: false, [
      Card2(
          padding: const EdgeInsets.all(18),
          child: Row(children: [
            Emoji(_avatar(), size: 70),
            const SizedBox(width: 14),
            Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(me, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              Text(
                  guru
                      ? 'Guru · Wali kelas XI IPA 3 & Guru Matematika'
                      : 'XI IPA 3 · NIS 2024-0153',
                  style: const TextStyle(color: kMuted, fontSize: 12)),
              const Text('SMA Nusantara 1', style: TextStyle(color: kMuted, fontSize: 12)),
              if (Session.isKetua) ...[
                const SizedBox(height: 6),
                Pill('⭐ Ketua Ekskul ${Session.ketuaOf}', bg: kYellowBg, fg: kAmber)
              ],
            ])),
          ])),
      StreamBuilder<List<Order>>(
        stream: firebase_service.FirebaseService.i.ordersStream(),
        builder: (context, oSnap) {
          return StreamBuilder<List<Complaint>>(
            stream: firebase_service.FirebaseService.i.complaintsStream(),
            builder: (context, cSnap) {
              return StreamBuilder<List<Aduan>>(
                stream: firebase_service.FirebaseService.i.aduansStream(),
                builder: (context, aSnap) {
                  return StreamBuilder<List<LfClaim>>(
                    stream: firebase_service.FirebaseService.i.lfClaimsStream(),
                    builder: (context, kSnap) {
                      final orders = oSnap.data ?? const <Order>[];
                      final cmps = cSnap.data ?? const <Complaint>[];
                      final adus = aSnap.data ?? const <Aduan>[];
                      final lfcs = kSnap.data ?? const <LfClaim>[];
                      return Card2(
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                            _Stat('${orders.where((o) => o.owner == me).length}', 'Pesanan'),
                            _Stat(
                                '${cmps.where((x) => x.owner == me).length + adus.where((a) => a.owner == me).length}',
                                'Laporan'),
                            _Stat('${lfcs.where((k) => k.owner == me).length}', 'Klaim'),
                          ]));
                    },
                  );
                },
              );
            },
          );
        },
      ),
      for (final m in [
        ('✏️', 'Edit profil', 'Foto, nomor, email', kBlueBg, () => go(c, const EditProfile())),
        (
          '🔒',
          'Ganti password',
          'Perbarui keamanan akun',
          kYellowBg,
          () => go(c, const ChangePasswordScreen())
        ),
        (
          '🔔',
          'Notifikasi & privasi',
          'Atur pemberitahuan',
          kYellowBg,
          () => go(c, const SettingsScreen())
        ),
        (
          '🚪',
          'Keluar',
          '',
          kRedBg,
          () => Navigator.pushNamedAndRemoveUntil(c, '/auth', (_) => false)
        ),
      ])
        Card2(
            onTap: m.$5,
            child: Row(children: [
              Emoji(m.$1, bg: m.$4, size: 46),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(m.$2, style: const TextStyle(fontWeight: FontWeight.w700)),
                if (m.$3.isNotEmpty)
                  Text(m.$3, style: const TextStyle(color: kMuted, fontSize: 12)),
              ])),
              const Icon(Icons.chevron_right, color: kMuted),
            ])),
    ]);
  }
}

class _Stat extends StatelessWidget {
  final String n, l;
  const _Stat(this.n, this.l);
  @override
  Widget build(BuildContext c) => Column(children: [
        Text(n, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        Text(l, style: const TextStyle(color: kMuted, fontSize: 12)),
      ]);
}

class EditProfile extends StatelessWidget {
  const EditProfile({super.key});
  @override
  Widget build(BuildContext c) => Page('Edit profil', [
        Center(child: Emoji(_avatar(), size: 90)),
        const SizedBox(height: 16),
        Field('Nama lengkap', controller: TextEditingController(text: Session.name)),
        Field(
            Session.role == Role.guru
                ? 'Jabatan (tidak bisa diubah)'
                : 'Kelas (tidak bisa diubah)',
            controller: TextEditingController(
                text: Session.role == Role.guru
                    ? 'Wali kelas XI IPA 3 & Guru Matematika'
                    : 'XI IPA 3')),
        Field('Email', controller: TextEditingController(text: 'alex@email.com')),
        Field('Nomor HP', controller: TextEditingController(text: '0812-xxxx-xxxx')),
        Btn('Simpan perubahan', () {
          toast(c, 'Profil disimpan');
          Navigator.pop(c);
        }),
      ]);
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsState();
}

class _SettingsState extends State<SettingsScreen> {
  final v = {
    'Pengumuman baru': true,
    'Pesanan koperasi': true,
    'Status pengaduan & laporan': true,
    'Persetujuan admin (mading, booking, klaim)': true,
    'Agenda baru': true,
    'Tampilkan nama di Lost & Found': false
  };
  @override
  Widget build(BuildContext c) => Page('Pengaturan', [
        for (final e in v.entries)
          Card2(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(e.key),
                  value: e.value,
                  activeThumbColor: kPrimary,
                  onChanged: (x) => setState(() => v[e.key] = x))),
        const SizedBox(height: 10),
        const Center(
            child: Text('SekolahKu v2.0 (MVVM Restructured)',
                style: TextStyle(color: kMuted, fontSize: 12))),
      ]);
}