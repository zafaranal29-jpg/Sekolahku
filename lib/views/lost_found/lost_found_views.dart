import 'package:flutter/material.dart' hide Page;

import 'package:sekolahku/core/theme.dart';
import 'package:sekolahku/models/lost_found.dart';
import 'package:sekolahku/models/role.dart';
import 'package:sekolahku/models/session.dart';
import 'package:sekolahku/services/data_store.dart';
import 'package:sekolahku/services/firebase_service.dart' as firebase_service;
import 'package:sekolahku/services/notif_service.dart';
import 'package:sekolahku/widgets/widgets.dart';

// ================= LOST & FOUND =================
class LostFoundScreen extends StatefulWidget {
  const LostFoundScreen({super.key});
  @override
  State<LostFoundScreen> createState() => _LostFoundState();
}

class _LostFoundState extends State<LostFoundScreen> {
  int tab = 0;
  @override
  Widget build(BuildContext c) {
    final kind = tab == 0 ? 'Ditemukan' : 'Hilang';
    return StreamBuilder<List<LfItem>>(
      stream: firebase_service.FirebaseService.i.lfItemsStream(),
      builder: (context, snap) {
        final items = (snap.data ?? const <LfItem>[])
            .where((i) => i.kind == kind && (i.status == 'Aktif' || i.status == 'Diklaim'))
            .toList();
        final mine = (snap.data ?? const <LfItem>[])
            .where((i) =>
                i.owner == Session.name &&
                (i.status == 'Menunggu validasi' || i.status == 'Ditolak'))
            .toList();
        return Page('Lost & Found',
            fab: (Session.role == Role.ortu)
                ? null
                : fabAdd(() => go(c, const PostingBarang()).then((_) {
                      if (mounted) setState(() {});
                    })),
            [
              SegmentedButton<int>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: 0, label: Text('Ditemukan')),
                    ButtonSegment(value: 1, label: Text('Hilang'))
                  ],
                  selected: {tab},
                  onSelectionChanged: (s) => setState(() => tab = s.first)),
              const SizedBox(height: 12),
              if (mine.isNotEmpty) ...[
                const H('Postingan saya'),
                for (final i in mine)
                  infoRow(i.emoji, i.bg, i.name, i.kind == 'Hilang' ? 'Hilang · ${i.where}' : i.where,
                      trailing: Pill.status(
                          i.status == 'Ditolak' ? 'Ditolak' : 'Menunggu validasi')),
                const H('Daftar barang'),
              ],
              if (items.isEmpty)
                const Padding(
                    padding: EdgeInsets.all(30),
                    child: Center(child: Text('Belum ada barang', style: TextStyle(color: kMuted)))),
              for (final i in items)
                infoRow(i.emoji, i.bg, i.name, i.where,
                    trailing: Pill.status(i.status == 'Diklaim' ? 'Diklaim' : i.kind),
                    onTap: () => go(c, DetailBarang(i))),
            ]);
      },
    );
  }
}

class DetailBarang extends StatelessWidget {
  final LfItem i;
  const DetailBarang(this.i, {super.key});
  @override
  Widget build(BuildContext c) {
    final mine = i.owner == Session.name;
    return Page('Detail barang', [
      Container(
          height: 180,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: kBlueBg, borderRadius: BorderRadius.circular(24)),
          child: Text(i.emoji, style: const TextStyle(fontSize: 90))),
      const SizedBox(height: 12),
      Text(i.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
      Card2(
          child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('📍 Lokasi/Waktu'),
          Text(i.where, style: const TextStyle(fontWeight: FontWeight.w700))
        ]),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(i.kind == 'Hilang' ? '🧑 Pemilik' : '🧑 Penemu'),
          Text(i.by, style: const TextStyle(fontWeight: FontWeight.w700))
        ]),
        const SizedBox(height: 6),
        Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [const Text('✅ Status'), Pill.status(i.status)]),
      ])),
      if (i.kind == 'Ditemukan')
        const Card2(
            color: kSoft,
            child: Text(
                '🛡️ Detail ciri barang disembunyikan. Pemilik harus menyebutkan ciri khasnya, lalu admin memvalidasi klaim.',
                style: TextStyle(color: kMuted))),
      if (i.kind == 'Ditemukan' && i.status == 'Aktif' && !mine)
        Btn('Ini barangku — ajukan klaim', () => go(c, AjukanKlaim(i))),
      if (i.kind == 'Hilang' && !mine)
        const Card2(
            color: kSoft,
            child: Text(
                'Kalau kamu menemukan barang ini, posting di tab "Ditemukan" — admin akan mencocokkannya.',
                style: TextStyle(color: kMuted))),
      Btn('💬 Chat admin', () => go(c, const ChatScreen()), outlined: true),
    ]);
  }
}

class PostingBarang extends StatefulWidget {
  const PostingBarang({super.key});
  @override
  State<PostingBarang> createState() => _PostingBarangState();
}

class _PostingBarangState extends State<PostingBarang> {
  static const emojis = ['🎒', '🧴', '🎧', '📘', '👓', '📦'];
  int kind = 0, emo = 5;
  final name = TextEditingController(), where = TextEditingController(), hidden = TextEditingController();
  @override
  void dispose() {
    name.dispose();
    where.dispose();
    hidden.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (name.text.trim().isEmpty) return toast(context, 'Isi nama barang');
    final isAdmin = Session.role == Role.admin;
    final it = LfItem(
        'LB-00${++DataStore.i.lfSeq}',
        emojis[emo],
        name.text.trim(),
        where.text.trim().isEmpty ? 'Sekolah' : where.text.trim(),
        kind == 0 ? 'Ditemukan' : 'Hilang',
        hidden.text.trim(),
        roleLabel(Session.role),
        Session.name,
        kSoft,
        isAdmin ? 'Aktif' : 'Menunggu validasi');
    await firebase_service.FirebaseService.i.addLfItem(it);
    if (!mounted) return;
    if (!isAdmin) {
      NotifService.i.notify('🎒', 'Postingan barang perlu validasi',
          '${it.name} · ${it.kind} · oleh ${Session.name}',
          bg: kYellowBg, roles: {Role.admin});
    }
    toast(context, isAdmin ? 'Barang diposting' : 'Terkirim. Menunggu validasi admin.');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext c) => Page('Posting barang', bottom: Btn('Posting', submit), [
        const Card2(
            color: kSoft,
            child: Text('🛡️ Postingan tampil setelah divalidasi admin.',
                style: TextStyle(color: kMuted))),
        const Text('Jenis', style: TextStyle(color: kMuted, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Chips(const ['Barang ditemukan', 'Barang hilang'], kind, (i) => setState(() => kind = i)),
        const SizedBox(height: 8),
        const Text('Ikon', style: TextStyle(color: kMuted, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Chips(emojis, emo, (i) => setState(() => emo = i)),
        const SizedBox(height: 8),
        OutlinedButton.icon(
            onPressed: () => toast(c, 'Pilih foto (tambahkan image_picker di versi lanjut)'),
            icon: const Icon(Icons.camera_alt_outlined),
            label: const Text('Tambah foto barang')),
        const SizedBox(height: 12),
        Field('Nama barang', controller: name),
        Field('Lokasi', controller: where),
        Field('Ciri tersembunyi (untuk verifikasi)', controller: hidden),
        const Text('Serah terima lewat admin (ruang OSIS).',
            style: TextStyle(color: kMuted, fontSize: 12)),
      ]);
}

class AjukanKlaim extends StatefulWidget {
  final LfItem i;
  const AjukanKlaim(this.i, {super.key});
  @override
  State<AjukanKlaim> createState() => _AjukanKlaimState();
}

class _AjukanKlaimState extends State<AjukanKlaim> {
  final ciri = TextEditingController();
  @override
  void dispose() {
    ciri.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext c) => Page('Ajukan klaim', [
        infoRow(widget.i.emoji, widget.i.bg, widget.i.name, widget.i.where),
        const Text(
            'Sebutkan ciri khas yang tidak terlihat di foto agar admin yakin barang ini milikmu.',
            style: TextStyle(color: kMuted)),
        const SizedBox(height: 10),
        Field('Ciri khas barang', controller: ciri, maxLines: 3),
        Btn('Kirim klaim', () async {
          if (ciri.text.trim().isEmpty) return toast(c, 'Tulis ciri khas barangnya');
          final k = LfClaim('LF-00${DataStore.i.claimSeq++}', widget.i, Session.name,
              ciri.text.trim(), 'Menunggu');
          await firebase_service.FirebaseService.i.addLfClaim(k);
          if (!c.mounted) return;
          NotifService.i.notify('🧴', 'Klaim barang perlu validasi',
              '${widget.i.name} · oleh ${Session.name}',
              bg: kYellowBg, roles: {Role.admin});
          Navigator.pushReplacement(c, MaterialPageRoute(builder: (_) => StatusKlaim(k)));
        }),
      ]);
}

class StatusKlaim extends StatelessWidget {
  final LfClaim k;
  const StatusKlaim(this.k, {super.key});
  @override
  Widget build(BuildContext c) {
    final ok = k.status == 'Disetujui' || k.status == 'Selesai';
    return Page('Status klaim', [
      infoRow(k.item.emoji, k.item.bg, k.item.name, 'Klaim #${k.id}',
          trailing: Pill.status(k.status)),
      if (k.status == 'Ditolak')
        const Card2(
            color: kRedBg,
            child: Text(
                '❌ Klaim ditolak admin karena ciri tidak cocok. Kamu bisa menghubungi admin lewat chat.',
                style: TextStyle(color: kRed))),
      Card2(
          child: Timeline([
        ('Klaim dikirim', 'Menunggu validasi admin', true),
        ('Divalidasi admin',
            k.status == 'Menunggu'
                ? 'Menunggu...'
                : (k.status == 'Ditolak' ? 'Ditolak' : 'Disetujui'),
            k.status != 'Menunggu'),
        ('Siap diambil', 'Ruang OSIS · jam istirahat', ok),
        ('Selesai', 'Barang diserahkan', k.status == 'Selesai'),
      ])),
      const Card2(
          color: kSoft,
          child: Text(
              'ℹ️ Barang yang tidak diklaim dalam 30 hari akan diserahkan ke sekolah.',
              style: TextStyle(color: kMuted))),
      Btn('Chat admin', () => go(c, const ChatScreen()), outlined: true),
    ]);
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatState();
}

class _ChatState extends State<ChatScreen> {
  final msgs = <(bool, String)>[
    (false, 'Halo, ada yang bisa dibantu soal barang ini?'),
    (true, 'Saya mau tanya soal klaim saya.'),
    (false, 'Baik, admin cek dulu ya. Serah terima di ruang OSIS.')
  ];
  final ctl = TextEditingController();
  @override
  void dispose() {
    ctl.dispose();
    super.dispose();
  }

  void send() {
    if (ctl.text.trim().isEmpty) return;
    setState(() => msgs.add((true, ctl.text.trim())));
    ctl.clear();
  }

  @override
  Widget build(BuildContext c) => Page('Chat · Admin',
          bottom: Row(children: [
            Expanded(
                child: TextField(
                    controller: ctl,
                    onSubmitted: (_) => send(),
                    decoration: InputDecoration(
                        hintText: 'Tulis pesan...',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none)))),
            const SizedBox(width: 8),
            IconButton.filled(
                style: IconButton.styleFrom(backgroundColor: kPrimary),
                onPressed: send,
                icon: const Icon(Icons.send)),
          ]),
          [
            const Card2(
                color: kYellowBg,
                child: Text('🔒 Nomor pribadi tidak dibagikan. Serah terima di ruang OSIS.',
                    style: TextStyle(color: kAmber, fontSize: 12))),
            for (final m in msgs)
              Align(
                  alignment: m.$1 ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                      constraints: const BoxConstraints(maxWidth: 280),
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                          color: m.$1 ? kPrimary : Colors.white,
                          borderRadius: BorderRadius.circular(18)),
                      child: Text(m.$2,
                          style: TextStyle(color: m.$1 ? Colors.white : kInk)))),
          ]);
}