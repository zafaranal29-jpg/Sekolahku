import 'package:flutter/material.dart' hide Page;

import 'package:sekolahku/core/theme.dart';
import 'package:sekolahku/models/aduan.dart';
import 'package:sekolahku/models/booking.dart';
import 'package:sekolahku/models/complaint.dart';
import 'package:sekolahku/models/lost_found.dart';
import 'package:sekolahku/models/mading.dart';
import 'package:sekolahku/models/role.dart';
import 'package:sekolahku/models/user.dart';
import 'package:sekolahku/services/data_store.dart';
import 'package:sekolahku/services/firebase_service.dart' as firebase_service;
import 'package:sekolahku/services/notif_service.dart';
import 'package:sekolahku/views/aduan/aduan_views.dart';
import 'package:sekolahku/views/kalender/kalender_screen.dart';
import 'package:sekolahku/views/mading/mading_views.dart';
import 'package:sekolahku/views/notif/bell_button.dart';
import 'package:sekolahku/widgets/widgets.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});
  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int i = 0;
  @override
  Widget build(BuildContext context) => Scaffold(
        body: IndexedStack(index: i, children: [
          AdminDashboard(onTab: (n) => setState(() => i = n)),
          ApprovalTab(key: ValueKey(i)),
          LaporanAdminTab(key: ValueKey(i)),
          const UsersTab(),
          KalenderScreen(key: ValueKey(i)),
        ]),
        bottomNavigationBar: NavigationBar(
            selectedIndex: i,
            backgroundColor: Colors.white,
            indicatorColor: kSoft,
            onDestinationSelected: (n) => setState(() => i = n),
            destinations: const [
              NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: 'Dashboard'),
              NavigationDestination(
                  icon: Icon(Icons.fact_check_outlined),
                  selectedIcon: Icon(Icons.fact_check),
                  label: 'Persetujuan'),
              NavigationDestination(
                  icon: Icon(Icons.report_outlined),
                  selectedIcon: Icon(Icons.report),
                  label: 'Laporan'),
              NavigationDestination(
                  icon: Icon(Icons.groups_outlined),
                  selectedIcon: Icon(Icons.groups),
                  label: 'Pengguna'),
              NavigationDestination(
                  icon: Icon(Icons.calendar_month_outlined),
                  selectedIcon: Icon(Icons.calendar_month),
                  label: 'Kalender'),
            ]),
      );
}

class AdminDashboard extends StatelessWidget {
  final void Function(int) onTab;
  const AdminDashboard({super.key, required this.onTab});

  Widget _quick(String e, String t, Color bg, VoidCallback f) => Expanded(
      child: GestureDetector(
          onTap: f,
          child: Column(children: [
            Emoji(e, bg: bg, size: 60),
            const SizedBox(height: 6),
            Text(t, style: const TextStyle(fontSize: 11))
          ])));

  @override
  Widget build(BuildContext c) {
    return StreamBuilder<List<AppUser>>(
      stream: firebase_service.FirebaseService.i.usersStream(),
      builder: (context, snap) {
        final users = snap.data ?? const <AppUser>[];
        final active = users.where((u) => u.active).length;
        final inactive = users.where((u) => !u.active).length;
        return StreamBuilder<List<Mading>>(
          stream: firebase_service.FirebaseService.i.madingsStream(),
          builder: (context, mSnap) {
            final pm = (mSnap.data ?? const <Mading>[])
                .where((m) => m.status == 'Menunggu')
                .length;
            return _buildDashboard(c, active, inactive, pm);
          },
        );
      },
    );
  }

  Widget _buildDashboard(BuildContext c, int active, int inactive, int pm) {
    final ds = DataStore.i;
    final pb = ds.bookingRequests.where((b) => b.status == 'Menunggu').length;
    final pl = ds.lfItems.where((x) => x.status == 'Menunggu validasi').length;
    final pk = ds.lfClaims.where((k) => k.status == 'Menunggu').length;
    final approvals = pm + pb + pl + pk;
    final cmp = ds.complaints.where((x) => x.status == 'Baru').length;
    final adu = ds.aduans.where((a) => a.status == 'Baru').length;
    final mod = ds.reports.where((r) => r.status == 'open').length;
    const chev = Icon(Icons.chevron_right, color: kMuted);
    return Page('Admin sekolah', back: false,
        action: Row(mainAxisSize: MainAxisSize.min, children: [
          const BellButton(),
          IconButton(
              tooltip: 'Keluar',
              onPressed: () => Navigator.pushNamedAndRemoveUntil(c, '/auth', (_) => false),
              icon: const Icon(Icons.logout)),
        ]),
        [
          Row(children: [
            statBox('$active', 'Pengguna aktif', kSoft),
            statBox('$approvals', 'Perlu disetujui', kYellowBg)
          ]),
          Row(children: [
            statBox('${cmp + adu}', 'Laporan baru', kRedBg),
            statBox('$mod', 'Perlu moderasi', kBlueBg)
          ]),
          const H('Aksi cepat'),
          Row(children: [
            _quick('📢', 'Pengumuman', kYellowBg,
                () => go(c, const MadingForm(kind: 'Pengumuman'))),
            _quick('📌', 'Mading', kSoft, () => go(c, const MadingList())),
            _quick('📅', 'Kalender', kBlueBg, () => onTab(4)),
          ]),
          const H('Perlu tindakan'),
          infoRow('📥', kYellowBg, 'Menunggu persetujuan',
              '$pm mading · $pb booking · $pl barang · $pk klaim',
              trailing: chev, onTap: () => onTab(1)),
          infoRow('🛠️', kRedBg, 'Laporan belum diproses',
              '$cmp fasilitas · $adu aduan & aspirasi',
              trailing: chev, onTap: () => onTab(2)),
          infoRow('👥', kSoft, 'Akun menunggu aktivasi', '$inactive akun baru',
              trailing: chev, onTap: () => onTab(3)),
          infoRow('🛡️', kBlueBg, 'Moderasi konten', '$mod laporan konten',
              trailing: chev, onTap: () => go(c, const ModerasiTab())),
        ]);
  }
}

// ---------------- PERSETUJUAN ----------------
class ApprovalTab extends StatefulWidget {
  const ApprovalTab({super.key});
  @override
  State<ApprovalTab> createState() => _ApprovalState();
}

class _ApprovalState extends State<ApprovalTab> {
  int f = 0;
  void refresh() => setState(() {});

  Widget _buttons(
          {required VoidCallback onNo,
          required VoidCallback onYes,
          String yes = 'Setujui',
          String no = 'Tolak'}) =>
      Row(children: [
        Expanded(child: OutlinedButton(onPressed: onNo, child: Text(no))),
        const SizedBox(width: 8),
        Expanded(
            child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: kPrimary),
                onPressed: onYes,
                child: Text(yes))),
      ]);

  Widget _empty() => const Padding(
      padding: EdgeInsets.all(40),
      child: Center(
          child: Text('Tidak ada yang menunggu 🎉', style: TextStyle(color: kMuted))));

  @override
  Widget build(BuildContext c) {
    return StreamBuilder<List<BookingReq>>(
      stream: firebase_service.FirebaseService.i.bookingsStream(),
      builder: (context, bSnap) {
        final pb = (bSnap.data ?? const <BookingReq>[])
            .where((b) => b.status == 'Menunggu')
            .toList();
        return StreamBuilder<List<Mading>>(
          stream: firebase_service.FirebaseService.i.madingsStream(),
          builder: (context, mSnap) {
        final pm = (mSnap.data ?? const <Mading>[])
            .where((m) => m.status == 'Menunggu')
            .toList();
        return StreamBuilder<List<LfItem>>(
          stream: firebase_service.FirebaseService.i.lfItemsStream(),
          builder: (context, iSnap) {
            final pl = (iSnap.data ?? const <LfItem>[])
                .where((x) => x.status == 'Menunggu validasi')
                .toList();
            return StreamBuilder<List<LfClaim>>(
              stream: firebase_service.FirebaseService.i.lfClaimsStream(),
              builder: (context, kSnap) {
                final pk = (kSnap.data ?? const <LfClaim>[])
                    .where((k) => k.status == 'Menunggu' || k.status == 'Disetujui')
                    .toList();
                final counts = [pm.length, pb.length, pl.length, pk.length];
                return Page('Pusat persetujuan', back: false, [
      Chips([
        'Mading (${counts[0]})',
        'Booking (${counts[1]})',
        'Barang (${counts[2]})',
        'Klaim (${counts[3]})'
      ], f, (i) => setState(() => f = i)),
      const SizedBox(height: 4),
      if (counts[f] == 0) _empty(),
      if (f == 0)
        for (final m in pm) MadingApprovalCard(key: ObjectKey(m), m: m, onDone: refresh),
      if (f == 1)
        for (final b in pb)
          Card2(
              child: Column(children: [
            Row(children: [
              Emoji(b.emoji, bg: kYellowBg, size: 46),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(b.facility, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(b.when, style: const TextStyle(color: kMuted, fontSize: 12))
              ])),
              Pill.status(b.status),
            ]),
            Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text('Pemohon: ${b.who}',
                        style: const TextStyle(color: kMuted, fontSize: 12)))),
            _buttons(
                onNo: () {
                  b.status = 'Ditolak';
                  firebase_service.FirebaseService.i.updateBooking(b);
                  NotifService.i.notify('❌', 'Booking ditolak', '${b.facility} · ${b.when}',
                      bg: kRedBg, to: b.owner);
                  refresh();
                },
                onYes: () {
                  b.status = 'Disetujui';
                  firebase_service.FirebaseService.i.updateBooking(b);
                  NotifService.i.notify('🏟️', 'Booking disetujui', '${b.facility} · ${b.when}',
                      bg: kGreenBg, to: b.owner);
                  refresh();
                }),
          ])),
      if (f == 2)
        for (final x in pl)
          Card2(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Emoji(x.emoji, bg: x.bg, size: 46),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(x.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text('${x.kind} · ${x.where}',
                    style: const TextStyle(color: kMuted, fontSize: 12))
              ])),
              Pill.status(x.kind),
            ]),
            const SizedBox(height: 8),
            Text('Diposting oleh: ${x.owner} (${x.by})',
                style: const TextStyle(color: kMuted, fontSize: 12)),
            Text('Ciri tersembunyi: ${x.hidden.isEmpty ? '-' : x.hidden}',
                style: const TextStyle(color: kMuted, fontSize: 12)),
            const SizedBox(height: 10),
            _buttons(
                no: 'Tolak',
                yes: 'Validasi & tayangkan',
                onNo: () {
                  x.status = 'Ditolak';
                  firebase_service.FirebaseService.i.updateLfItem(x);
                  NotifService.i.notify('❌', 'Postingan barang ditolak', x.name,
                      bg: kRedBg, to: x.owner);
                  refresh();
                },
                onYes: () {
                  x.status = 'Aktif';
                  firebase_service.FirebaseService.i.updateLfItem(x);
                  NotifService.i.notify('✅', 'Postingan barang tervalidasi',
                      '${x.name} sudah tampil di Lost & Found',
                      bg: kGreenBg, to: x.owner);
                  refresh();
                }),
          ])),
      if (f == 3)
        for (final k in pk)
          Card2(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Emoji(k.item.emoji, bg: k.item.bg, size: 46),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(k.item.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text('Klaim #${k.id} · oleh ${k.owner}',
                    style: const TextStyle(color: kMuted, fontSize: 12))
              ])),
              Pill.status(k.status),
            ]),
            const SizedBox(height: 8),
            Card2(
                color: kSoft,
                padding: const EdgeInsets.all(10),
                child: Text(
                    'Ciri dari penemu: ${k.item.hidden.isEmpty ? '-' : k.item.hidden}\nCiri dari pengklaim: ${k.desc}',
                    style: const TextStyle(fontSize: 12))),
            if (k.status == 'Menunggu')
              _buttons(
                  yes: 'Cocok, setujui',
                  onNo: () {
                    k.status = 'Ditolak';
                    firebase_service.FirebaseService.i.updateLfClaim(k);
                    NotifService.i.notify(
                        '❌', 'Klaim ditolak', '${k.item.name} · ciri tidak cocok',
                        bg: kRedBg, to: k.owner);
                    refresh();
                  },
                  onYes: () {
                    k.status = 'Disetujui';
                    k.item.status = 'Diklaim';
                    firebase_service.FirebaseService.i.updateLfClaim(k);
                    firebase_service.FirebaseService.i.updateLfItem(k.item);
                    NotifService.i.notify(
                        '✅', 'Klaim disetujui', '${k.item.name} · ambil di ruang OSIS',
                        bg: kGreenBg, to: k.owner);
                    refresh();
                  })
            else
              Btn('Tandai sudah diserahkan', () {
                k.status = 'Selesai';
                k.item.status = 'Selesai';
                firebase_service.FirebaseService.i.updateLfClaim(k);
                firebase_service.FirebaseService.i.updateLfItem(k.item);
                NotifService.i.notify('🎉', 'Barang sudah diserahkan', k.item.name,
                    bg: kSoft, to: k.owner);
                refresh();
              }),
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
  }
}

class MadingApprovalCard extends StatefulWidget {
  final Mading m;
  final VoidCallback onDone;
  const MadingApprovalCard({super.key, required this.m, required this.onDone});
  @override
  State<MadingApprovalCard> createState() => _MadingApprovalCardState();
}

class _MadingApprovalCardState extends State<MadingApprovalCard> {
  late bool pin = widget.m.reqPin, push = widget.m.reqPush;
  @override
  Widget build(BuildContext c) {
    final m = widget.m;
    return Card2(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Emoji(m.emoji, bg: m.bg, size: 46),
            const SizedBox(width: 12),
            Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(m.title, style: const TextStyle(fontWeight: FontWeight.w700)),
              Text('${m.kind} · ${m.cat} · untuk ${m.target}',
                  style: const TextStyle(color: kMuted, fontSize: 12)),
            ])),
          ]),
          const SizedBox(height: 6),
          Text('Oleh ${m.by}', style: const TextStyle(color: kMuted, fontSize: 12)),
          const SizedBox(height: 6),
          Text(m.body, style: const TextStyle(height: 1.5)),
          if (m.reqPin || m.reqPush)
            Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(spacing: 6, children: [
                  const Text('Pengusul meminta:',
                      style: TextStyle(color: kMuted, fontSize: 12)),
                  if (m.reqPin) const Pill('📌 sematkan', bg: kYellowBg, fg: kAmber),
                  if (m.reqPush) const Pill('🔔 push', bg: kYellowBg, fg: kAmber),
                ])),
          SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('📌 Sematkan di atas'),
              value: pin,
              activeThumbColor: kPrimary,
              onChanged: (v) => setState(() => pin = v)),
          SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('🔔 Kirim notifikasi push'),
              value: push,
              activeThumbColor: kPrimary,
              onChanged: (v) => setState(() => push = v)),
          Row(children: [
            Expanded(
                child: OutlinedButton(
                    onPressed: () {
                      rejectMading(m);
                      widget.onDone();
                    },
                    child: const Text('Tolak'))),
            const SizedBox(width: 8),
            Expanded(
                child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: kPrimary),
                    onPressed: () {
                      approveMading(m, pin: pin, push: push);
                      widget.onDone();
                    },
                    child: const Text('Setujui & terbitkan'))),
          ]),
        ]));
  }
}

// ---------------- LAPORAN ----------------
class LaporanAdminTab extends StatefulWidget {
  const LaporanAdminTab({super.key});
  @override
  State<LaporanAdminTab> createState() => _LaporanAdminState();
}

class _LaporanAdminState extends State<LaporanAdminTab> {
  int seg = 0, f = 0;
  static const tabs = ['Baru', 'Diproses', 'Selesai'];
  @override
  Widget build(BuildContext c) {
    return StreamBuilder<List<Aduan>>(
      stream: firebase_service.FirebaseService.i.aduansStream(),
      builder: (context, aSnap) {
        final allAdu = aSnap.data ?? const <Aduan>[];
        final adu = allAdu.where((x) => x.status == tabs[f]).toList();
        final aduBaru = allAdu.where((x) => x.status == 'Baru').length;
        return StreamBuilder<List<Complaint>>(
          stream: firebase_service.FirebaseService.i.complaintsStream(),
          builder: (context, cSnap) {
            final allCmp = cSnap.data ?? const <Complaint>[];
            final fas = allCmp.where((x) => x.status == tabs[f]).toList();
            final fasBaru = allCmp.where((x) => x.status == 'Baru').length;
            final empty = seg == 0 ? fas.isEmpty : adu.isEmpty;
            return Page('Laporan masuk', back: false, [
              SegmentedButton<int>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(value: 0, label: Text('Fasilitas ($fasBaru)')),
                    ButtonSegment(value: 1, label: Text('Aduan ($aduBaru)')),
                  ],
              selected: {seg},
              onSelectionChanged: (v) => setState(() => seg = v.first)),
          const SizedBox(height: 10),
          Chips(tabs, f, (i) => setState(() => f = i)),
          if (empty)
            const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: Text('Tidak ada laporan', style: TextStyle(color: kMuted)))),
          if (seg == 0)
            for (final x in fas)
              _ComplaintCard(
                  key: ValueKey('${x.id}${x.status}'),
                  x: x,
                  onSaved: () {
                    setState(() {});
                    toast(c, 'Tersimpan, notifikasi dikirim ke pelapor');
                  })
          else
            for (final a in adu)
              AduanCard(
                  key: ValueKey('${a.id}${a.status}'),
                  a: a,
                  onSaved: () {
                    setState(() {});
                    toast(c, 'Tersimpan, notifikasi dikirim ke pelapor');
                  }),
        ]);
          },
        );
      },
    );
  }
}

class _ComplaintCard extends StatefulWidget {
  final Complaint x;
  final VoidCallback onSaved;
  const _ComplaintCard({super.key, required this.x, required this.onSaved});
  @override
  State<_ComplaintCard> createState() => _ComplaintCardState();
}

class _ComplaintCardState extends State<_ComplaintCard> {
  late String status = widget.x.status, pic = widget.x.pic;
  late final reply = TextEditingController(text: widget.x.reply);
  static const pics = ['Pak Joko (Sarpras)', 'Bu Sari (Wakasek)', 'Belum ditentukan'];
  @override
  void dispose() {
    reply.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext c) {
    final x = widget.x;
    return Card2(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Emoji('🛠️', bg: kRedBg, size: 46),
            const SizedBox(width: 12),
            Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(x.title, style: const TextStyle(fontWeight: FontWeight.w700)),
              Text('#${x.id} · oleh ${x.by}',
                  style: const TextStyle(color: kMuted, fontSize: 12))
            ])),
          ]),
          const SizedBox(height: 8),
          Wrap(spacing: 6, children: [
            Pill(x.loc),
            const Pill('Prioritas sedang', bg: kYellowBg, fg: kAmber)
          ]),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
              initialValue: status,
              decoration: const InputDecoration(labelText: 'Ubah status', border: OutlineInputBorder()),
              items: [
                for (final s in ['Baru', 'Diproses', 'Selesai'])
                  DropdownMenuItem(value: s, child: Text(s))
              ],
              onChanged: (v) => setState(() => status = v!)),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
              initialValue: pic,
              decoration:
                  const InputDecoration(labelText: 'Penanggung jawab', border: OutlineInputBorder()),
              items: [for (final s in pics) DropdownMenuItem(value: s, child: Text(s))],
              onChanged: (v) => setState(() => pic = v!)),
          const SizedBox(height: 10),
          TextField(
              controller: reply,
              decoration: const InputDecoration(
                  labelText: 'Balasan untuk pelapor', border: OutlineInputBorder())),
          const SizedBox(height: 10),
          Btn('Simpan & kirim notifikasi', () {
            x.status = status;
            x.pic = pic;
            x.reply = reply.text;
            firebase_service.FirebaseService.i.updateComplaint(x);
            NotifService.i.notify('🛠️', 'Status pengaduan berubah', '${x.title} → ${x.status}',
                bg: kRedBg, to: x.owner);
            widget.onSaved();
          }),
        ]));
  }
}

// ---------------- PENGGUNA ----------------
class UsersTab extends StatefulWidget {
  const UsersTab({super.key});
  @override
  State<UsersTab> createState() => _UsersState();
}

class _UsersState extends State<UsersTab> {
  String q = '';
  int f = 0;
  static const tabs = ['Semua', 'Siswa', 'Guru', 'Ortu', 'Koperasi'];
  static const roles = [null, Role.siswa, Role.guru, Role.ortu, Role.koperasi];

  Future<void> setKetua(AppUser u) async {
    final r = await showDialog<String>(
        context: context,
        builder: (x) => SimpleDialog(title: Text('Ketua ekskul · ${u.name}'), children: [
              for (final e in ekskulList)
                SimpleDialogOption(onPressed: () => Navigator.pop(x, e), child: Text('⭐ $e')),
              SimpleDialogOption(
                  onPressed: () => Navigator.pop(x, ''),
                  child: const Text('Bukan ketua ekskul', style: TextStyle(color: kRed))),
            ]));
    if (r == null) return;
    await firebase_service.FirebaseService.i
        .setUserKetua(uid: u.uid!, ekskul: r.isEmpty ? null : r);
    NotifService.i.notify(
        r.isEmpty ? 'ℹ️' : '⭐',
        r.isEmpty ? 'Peran ketua ekskul dicabut' : 'Kamu ditunjuk Ketua Ekskul $r',
        r.isEmpty
            ? 'Kamu tidak lagi bisa membuat pengumuman ekskul'
            : 'Kamu bisa mengirim pengumuman ekskul (ACC admin)',
        bg: r.isEmpty ? kSoft : kYellowBg,
        to: u.name);
    if (mounted) {
      toast(context,
          r.isEmpty ? '${u.name} bukan lagi ketua ekskul' : '${u.name} menjadi Ketua Ekskul $r');
    }
  }

  @override
  Widget build(BuildContext c) {
    return Page('Pengguna', back: false, [
      Card2(
          onTap: () => toast(
              c, 'Pilih file Excel/CSV (tambahkan file_picker + parser csv di versi lanjut)'),
          padding: const EdgeInsets.all(18),
          child: const Column(children: [
            Text('📄', style: TextStyle(fontSize: 36)),
            Text('Impor dari Excel / CSV', style: TextStyle(fontWeight: FontWeight.w700)),
            Text('Unggah daftar siswa dan guru sekaligus',
                style: TextStyle(color: kMuted, fontSize: 12)),
          ])),
      Field('Cari nama / NIS / Ortu...', onChanged: (v) => setState(() => q = v)),
      Chips(tabs, f, (i) => setState(() => f = i)),
      const SizedBox(height: 8),
      StreamBuilder<List<AppUser>>(
        stream: firebase_service.FirebaseService.i.usersStream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Padding(
                padding: EdgeInsets.all(30),
                child: Center(child: CircularProgressIndicator()));
          }
          if (snap.hasError) {
            return Padding(
              padding: const EdgeInsets.all(30),
              child: Center(
                  child: Text(
                'Gagal memuat pengguna:\n${snap.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: kRed, fontSize: 12),
              )),
            );
          }
          final list = (snap.data ?? const <AppUser>[])
              .where((u) =>
                  u.name.toLowerCase().contains(q.toLowerCase()) &&
                  (roles[f] == null || u.role == roles[f]))
              .toList();
          if (list.isEmpty) {
            return const Padding(
                padding: EdgeInsets.all(30),
                child: Center(
                    child: Text('Belum ada pengguna',
                        style: TextStyle(color: kMuted))));
          }
          return Column(
            children: [for (final u in list) _userCard(c, u)],
          );
        },
      ),
    ]);
  }

  Widget _userCard(BuildContext c, AppUser u) => Card2(
      child: Column(children: [
        Row(children: [
          Emoji(
              switch (u.role) {
                Role.guru => '👩‍🏫',
                Role.koperasi => '🍱',
                Role.ortu => '👨‍👩‍👧',
                _ => '🧑'
              },
              bg: kSoft),
          const SizedBox(width: 12),
          Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(u.name, style: const TextStyle(fontWeight: FontWeight.w700)),
            Text(u.info, style: const TextStyle(color: kMuted, fontSize: 12))
          ])),
          Switch(
              value: u.active,
              activeThumbColor: kPrimary,
              onChanged: (v) async {
                await firebase_service.FirebaseService.i
                    .setUserActive(uid: u.uid!, active: v);
                if (c.mounted) {
                  toast(c, v ? '${u.name} diaktifkan' : '${u.name} dinonaktifkan');
                }
              }),
        ]),
        if (u.role == Role.siswa)
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(
                u.ketuaOf == null
                    ? 'Bukan ketua ekskul'
                    : '⭐ Ketua Ekskul ${u.ketuaOf}',
                style: TextStyle(
                    color: u.ketuaOf == null ? kMuted : kAmber,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
            TextButton(
                onPressed: () => setKetua(u),
                child: Text(u.ketuaOf == null ? 'Jadikan ketua' : 'Ubah')),
          ]),
      ]));
}

// ---------------- MODERASI ----------------
class ModerasiTab extends StatefulWidget {
  const ModerasiTab({super.key});
  @override
  State<ModerasiTab> createState() => _ModerasiState();
}

class _ModerasiState extends State<ModerasiTab> {
  int f = 0;
  static const tabs = ['Dilaporkan', 'Disembunyikan', 'Riwayat'];
  static const keys = ['open', 'hidden', 'ignored'];
  @override
  Widget build(BuildContext c) {
    final list = DataStore.i.reports.where((r) => r.status == keys[f]).toList();
    return Page('Moderasi konten', [
      Chips(tabs, f, (i) => setState(() => f = i)),
      if (list.isEmpty)
        const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: Text('Tidak ada konten', style: TextStyle(color: kMuted)))),
      for (final r in list)
        Card2(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Emoji(r.emoji, bg: kSoft, size: 46),
            const SizedBox(width: 12),
            Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.title, style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(r.sub, style: const TextStyle(color: kMuted, fontSize: 12))
            ])),
            Pill('${r.count} laporan', bg: kRedBg, fg: kRed),
          ]),
          Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('“${r.quote}”', style: const TextStyle(color: kMuted))),
          if (r.status == 'open')
            Row(children: [
              Expanded(
                  child: OutlinedButton(
                      onPressed: () => setState(() => r.status = 'ignored'),
                      child: const Text('Abaikan'))),
              const SizedBox(width: 8),
              Expanded(
                  child: FilledButton(
                      style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFF4566F)),
                      onPressed: () => setState(() => r.status = 'hidden'),
                      child: const Text('Sembunyikan'))),
            ])
          else if (r.status == 'hidden')
            OutlinedButton(
                onPressed: () => setState(() => r.status = 'open'),
                child: const Text('Tampilkan kembali')),
        ])),
    ]);
  }
}