import 'package:flutter/material.dart' hide Page;

import 'package:sekolahku/core/theme.dart';
import 'package:sekolahku/models/mading.dart';
import 'package:sekolahku/models/role.dart';
import 'package:sekolahku/models/session.dart';
import 'package:sekolahku/services/firebase_service.dart' as firebase_service;
import 'package:sekolahku/services/notif_service.dart';
import 'package:sekolahku/widgets/widgets.dart';

(String, Color) catStyle(String cat) => switch (cat) {
      'Akademik' => ('📌', kRedBg),
      'Prestasi' => ('🏆', kYellowBg),
      'Kegiatan' => ('🎭', kGreenBg),
      'Karya' => ('🎨', kSoft),
      _ => ('📢', kBlueBg),
    };

/// Hanya yang sudah di-ACC admin; yang disematkan admin tampil paling atas.
List<Mading> approvedOf(List<Mading> all) {
  final l = all.where((m) => m.status == 'Disetujui').toList();
  return [...l.where((m) => m.pinned), ...l.where((m) => !m.pinned)];
}

Set<Role>? _audienceFor(Mading m) {
  if (m.target == 'Semua') return null;
  if (m.target == 'Guru') return {Role.guru};
  return {Role.siswa, Role.ortu};
}

/// Push notifikasi (hanya dipanggil oleh admin).
void pushMading(Mading m) => NotifService.i.notify(
    m.emoji, m.kind == 'Mading' ? 'Mading baru' : 'Pengumuman baru', m.title,
    bg: m.bg, roles: _audienceFor(m));

Future<void> approveMading(Mading m, {required bool pin, required bool push}) async {
  m
    ..status = 'Disetujui'
    ..pinned = pin
    ..push = push
    ..time = 'Baru saja';
  await firebase_service.FirebaseService.i.updateMading(m);
  if (m.owner.isNotEmpty) {
    NotifService.i.notify('✅', '${m.kind} disetujui admin', m.title, bg: kGreenBg, to: m.owner);
  }
  if (push) pushMading(m);
}

Future<void> rejectMading(Mading m) async {
  m.status = 'Ditolak';
  await firebase_service.FirebaseService.i.updateMading(m);
  if (m.owner.isNotEmpty) {
    NotifService.i.notify('❌', '${m.kind} ditolak admin', m.title, bg: kRedBg, to: m.owner);
  }
}

/// Mulai buat kiriman. Siswa biasa: Mading saja. Guru/ketua ekskul/admin: bisa Pengumuman juga.
Future<void> startPost(BuildContext c) async {
  final kinds = [if (Session.canAnnounce) 'Pengumuman', 'Mading'];
  final String? k = kinds.length == 1
      ? kinds.first
      : await showModalBottomSheet<String>(
          context: c,
          builder: (x) => SafeArea(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                ListTile(
                    leading: const Text('📢', style: TextStyle(fontSize: 26)),
                    title: const Text('Buat pengumuman'),
                    subtitle: Text(Session.isKetua
                        ? 'Untuk anggota ekskul ${Session.ketuaOf}'
                        : 'Ke siswa, kelas, ekskul, atau guru'),
                    onTap: () => Navigator.pop(x, 'Pengumuman')),
                ListTile(
                    leading: const Text('🎨', style: TextStyle(fontSize: 26)),
                    title: const Text('Upload mading'),
                    subtitle: const Text('Prestasi, kegiatan, karya, info'),
                    onTap: () => Navigator.pop(x, 'Mading')),
              ])));
  if (k == null || !c.mounted) return;
  await go(c, MadingForm(kind: k));
}

class MadingTile extends StatelessWidget {
  final Mading m;
  final bool showStatus;
  const MadingTile(this.m, {super.key, this.showStatus = false});
  @override
  Widget build(BuildContext c) => Card2(
      onTap: () => go(c, MadingDetail(m: m)),
      child: Row(children: [
        Emoji(m.emoji, bg: m.bg),
        const SizedBox(width: 12),
        Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Wrap(spacing: 6, runSpacing: 4, children: [
            Pill(m.cat),
            if (m.kind == 'Mading') const Pill('Mading', bg: kBlueBg, fg: Color(0xFF2F6FBF)),
            if (m.pinned) const Pill('📌 Disematkan', bg: kYellowBg, fg: kAmber),
            if (showStatus) Pill.status(m.status),
          ]),
          const SizedBox(height: 4),
          Text(m.title, style: const TextStyle(fontWeight: FontWeight.w700)),
          Text('Untuk: ${m.target} · ${m.time}',
              style: const TextStyle(color: kMuted, fontSize: 12)),
        ])),
      ]));
}

class MadingList extends StatefulWidget {
  const MadingList({super.key});
  @override
  State<MadingList> createState() => _MadingListState();
}

class _MadingListState extends State<MadingList> {
  int f = 0;
  static const cats = ['Semua', 'Akademik', 'Kegiatan', 'Prestasi', 'Karya', 'Info'];
  @override
  Widget build(BuildContext c) {
    return StreamBuilder<List<Mading>>(
      stream: firebase_service.FirebaseService.i.madingsStream(),
      builder: (context, snap) {
        final all = snap.data ?? const <Mading>[];
        final mine = all
            .where((m) => m.owner == Session.name && m.status != 'Disetujui')
            .toList();
        final list = approvedOf(all).where((m) => f == 0 || m.cat == cats[f]).toList();
        return Page('Mading & Pengumuman',
            fab: (Session.role == Role.ortu)
                ? null
                : fabAdd(() => startPost(c).then((_) {
                      if (mounted) setState(() {});
                    })),
            [
              Chips(cats, f, (i) => setState(() => f = i)),
              if (mine.isNotEmpty) ...[
                const H('Kiriman saya'),
                for (final m in mine) MadingTile(m, showStatus: true),
              ],
              const H('Terbaru'),
              if (list.isEmpty)
                const Padding(
                    padding: EdgeInsets.all(30),
                    child: Center(
                        child: Text('Belum ada isi',
                            style: TextStyle(color: kMuted)))),
              for (final m in list) MadingTile(m),
            ]);
      },
    );
  }
}

class MadingDetail extends StatefulWidget {
  final Mading? m;
  const MadingDetail({super.key, this.m});
  @override
  State<MadingDetail> createState() => _MadingDetailState();
}

class _MadingDetailState extends State<MadingDetail> {
  bool read = false;
  @override
  Widget build(BuildContext c) {
    final m = widget.m!;
    final admin = Session.role == Role.admin;
    return Page(m.kind == 'Mading' ? 'Mading' : 'Pengumuman', [
      Container(
          height: 150,
          alignment: Alignment.center,
          decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(24)),
          child: Text(m.emoji, style: const TextStyle(fontSize: 70))),
      const SizedBox(height: 14),
      Wrap(spacing: 6, runSpacing: 4, children: [
        Pill(m.cat),
        if (m.pinned) const Pill('📌 Disematkan', bg: kYellowBg, fg: kAmber),
        if (m.cat == 'Akademik') const Pill('Penting', bg: kRedBg, fg: kRed),
        if (m.status != 'Disetujui') Pill.status(m.status),
      ]),
      const SizedBox(height: 8),
      Text(m.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
      Text('Oleh ${m.by} · ${m.time} · Untuk ${m.target}',
          style: const TextStyle(color: kMuted, fontSize: 12)),
      const SizedBox(height: 12),
      Text(m.body, style: const TextStyle(height: 1.6)),
      const SizedBox(height: 12),
      if (m.status == 'Menunggu')
        const Card2(
            color: kYellowBg,
            child: Text('⏳ Menunggu persetujuan admin. Belum tampil untuk yang lain.',
                style: TextStyle(color: kAmber))),
      if (m.status == 'Ditolak')
        const Card2(color: kRedBg, child: Text('❌ Kiriman ini ditolak admin.', style: TextStyle(color: kRed))),
      if (m.status == 'Disetujui' && m.cat == 'Akademik')
        const Card2(
            child: Row(children: [
          Emoji('📎', bg: kBlueBg, size: 44),
          SizedBox(width: 12),
          Text('Lampiran.pdf · 1,2 MB')
        ])),
      // ---- Kontrol admin: hanya admin yang boleh sematkan & push ----
      if (admin && m.status == 'Disetujui') ...[
        const H('Kontrol admin'),
        Btn(m.pinned ? '📌 Lepas sematan' : '📌 Sematkan di atas',
            () => setState(() => m.pinned = !m.pinned),
            outlined: true),
        Btn('🔔 Kirim notifikasi push', () {
          pushMading(m);
          toast(c, 'Notifikasi push dikirim');
        }),
      ],
      if (!admin && m.status == 'Disetujui' && m.kind == 'Pengumuman') ...[
        const Center(
            child: Text('👁️ Dibaca 212 dari 240 siswa', style: TextStyle(color: kMuted, fontSize: 12))),
        const SizedBox(height: 10),
        Btn(read ? '✓ Sudah dibaca' : '✓ Tandai sudah dibaca',
            read ? null : () => setState(() => read = true)),
      ],
    ]);
  }
}

/// Form kirim Pengumuman / Mading.
class MadingForm extends StatefulWidget {
  final String kind;
  const MadingForm({super.key, required this.kind});
  @override
  State<MadingForm> createState() => _MadingFormState();
}

class _MadingFormState extends State<MadingForm> {
  final judul = TextEditingController(), isi = TextEditingController(), ekskul = TextEditingController();
  final kelas = TextEditingController(text: 'XI IPA 1 · XI IPA 2 · XI IPA 3');
  int cat = 0, target = 0;
  bool pin = false, push = false;
  static const targets = ['Semua', 'Per kelas', 'Ekskul', 'Guru'];

  bool get isAdmin => Session.role == Role.admin;
  bool get isPeng => widget.kind == 'Pengumuman';
  bool get ketuaMode => isPeng && Session.role == Role.siswa;
  List<String> get cats =>
      isPeng ? ['Akademik', 'Kegiatan', 'Info'] : ['Prestasi', 'Kegiatan', 'Karya', 'Info'];

  @override
  void dispose() {
    judul.dispose();
    isi.dispose();
    ekskul.dispose();
    kelas.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (judul.text.trim().isEmpty || isi.text.trim().isEmpty) {
      return toast(context, 'Judul dan isi wajib diisi');
    }
    final t = !isPeng
        ? 'Semua'
        : ketuaMode
            ? 'Ekskul ${Session.ketuaOf}'
            : switch (target) {
                0 => 'Semua',
                1 => kelas.text.trim().isEmpty ? 'Per kelas' : kelas.text.trim(),
                2 => ekskul.text.trim().isEmpty ? 'Ekskul' : 'Ekskul ${ekskul.text.trim()}',
                _ => 'Guru',
              };
    final st = catStyle(cats[cat]);
    final by = Session.isKetua && isPeng ? '${Session.name} · Ketua ${Session.ketuaOf}' : Session.name;
    final m = Mading(
      emoji: st.$1,
      bg: st.$2,
      cat: cats[cat],
      title: judul.text.trim(),
      target: t,
      body: isi.text.trim(),
      by: by,
      owner: Session.name,
      kind: widget.kind,
      status: isAdmin ? 'Disetujui' : 'Menunggu',
      pinned: isAdmin && pin,
      push: isAdmin && push,
      reqPin: !isAdmin && pin,
      reqPush: !isAdmin && push,
    );
    await firebase_service.FirebaseService.i.addMading(m);
    if (!mounted) return;
    if (isAdmin) {
      if (push) pushMading(m);
      toast(context, '${widget.kind} terbit${push ? ' + notifikasi dikirim' : ''}');
    } else {
      NotifService.i.notify('📥', 'Kiriman baru perlu ACC',
          '${widget.kind}: ${m.title} · oleh ${Session.name}',
          bg: kYellowBg, roles: {Role.admin});
      toast(context, 'Terkirim. Menunggu persetujuan admin.');
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext c) => Page(isPeng ? 'Buat pengumuman' : 'Upload mading',
          bottom: Btn(isAdmin ? 'Terbitkan' : 'Kirim ke admin', submit),
          [
            if (!isAdmin)
              const Card2(
                  color: kSoft,
                  child: Text('🛡️ Kirimanmu ditinjau admin dulu sebelum tampil untuk yang lain.',
                      style: TextStyle(color: kMuted))),
            Field('Judul', controller: judul),
            Field(isPeng ? 'Isi pengumuman' : 'Isi / keterangan', controller: isi, maxLines: 4),
            const Text('Kategori', style: TextStyle(color: kMuted, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Chips(cats, cat, (i) => setState(() => cat = i)),
            const SizedBox(height: 8),
            if (!isPeng)
              OutlinedButton.icon(
                  onPressed: () => toast(c, 'Pilih foto (tambahkan image_picker di versi lanjut)'),
                  icon: const Icon(Icons.add_a_photo_outlined),
                  label: const Text('Tambah foto / lampiran')),
            if (isPeng) ...[
              const Text('Target audiens', style: TextStyle(color: kMuted, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              if (ketuaMode)
                Card2(
                    color: kYellowBg,
                    child: Text('⭐ Kamu Ketua Ekskul ${Session.ketuaOf}. Pengumuman hanya untuk ekskul ini.',
                        style: const TextStyle(color: kAmber)))
              else ...[
                Chips(targets, target, (i) => setState(() => target = i)),
                const SizedBox(height: 8),
                if (target == 1) Field('Kelas dipilih', controller: kelas),
                if (target == 2) Field('Nama ekskul', controller: ekskul),
              ],
            ],
            if (isPeng || isAdmin) ...[
              const SizedBox(height: 6),
              Card2(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Column(children: [
                    SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(isAdmin ? '📌 Sematkan di atas' : '📌 Usulkan disematkan'),
                        value: pin,
                        activeThumbColor: kPrimary,
                        onChanged: (v) => setState(() => pin = v)),
                    SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(isAdmin ? '🔔 Kirim notifikasi push' : '🔔 Usulkan notifikasi push'),
                        value: push,
                        activeThumbColor: kPrimary,
                        onChanged: (v) => setState(() => push = v)),
                  ])),
              if (!isAdmin)
                const Text('Sematkan & push notifikasi hanya bisa diputuskan admin. Ini hanya usulan.',
                    style: TextStyle(color: kMuted, fontSize: 12)),
            ],
          ]);
}