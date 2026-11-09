import 'package:flutter/material.dart' hide Page;

import 'package:sekolahku/core/theme.dart';
import 'package:sekolahku/models/aduan.dart';
import 'package:sekolahku/models/role.dart';
import 'package:sekolahku/models/session.dart';
import 'package:sekolahku/services/data_store.dart';
import 'package:sekolahku/services/firebase_service.dart' as firebase_service;
import 'package:sekolahku/services/notif_service.dart';
import 'package:sekolahku/widgets/widgets.dart';

(String, Color) aduanStyle(String kind) => switch (kind) {
      'Perundungan' => ('🛑', kRedBg),
      'Kekerasan / pelecehan' => ('🚨', kRedBg),
      'Aspirasi / saran' => ('💌', kSoft),
      _ => ('📝', kYellowBg),
    };

// ================= LAPOR & ASPIRASI (siswa & guru) =================
class AduanScreen extends StatefulWidget {
  const AduanScreen({super.key});
  @override
  State<AduanScreen> createState() => _AduanScreenState();
}

class _AduanScreenState extends State<AduanScreen> {
  @override
  Widget build(BuildContext c) {
    return StreamBuilder<List<Aduan>>(
      stream: firebase_service.FirebaseService.i.aduansStream(),
      builder: (context, snap) {
        final mine = (snap.data ?? const <Aduan>[])
            .where((a) => a.owner == Session.name)
            .toList();
        return Page('Lapor & Aspirasi',
            fab: (Session.role == Role.ortu)
                ? null
                : fabAdd(() => go(c, const AduanForm()).then((_) {
                      if (mounted) setState(() {});
                    })),
            [
              const GCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Aman & rahasia', style: TextStyle(color: Colors.white70)),
                Text('Laporkan perundungan, kekerasan, atau sampaikan aspirasimu',
                    style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
                SizedBox(height: 6),
                Text('Bisa dikirim anonim. Hanya admin sekolah yang menindaklanjuti.',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
              ])),
              const H('Kiriman saya'),
              if (mine.isEmpty)
                const Padding(
                    padding: EdgeInsets.all(30),
                    child: Center(
                        child: Text('Belum ada kiriman. Tekan + untuk membuat.',
                            style: TextStyle(color: kMuted)))),
              for (final a in mine)
                infoRow(aduanStyle(a.kind).$1, aduanStyle(a.kind).$2, a.kind,
                    '#${a.id} · ${a.anon ? 'Anonim' : 'Dengan nama'}',
                    trailing: Pill.status(a.status), onTap: () => go(c, AduanDetail(a))),
            ]);
      },
    );
  }
}

class AduanForm extends StatefulWidget {
  const AduanForm({super.key});
  @override
  State<AduanForm> createState() => _AduanFormState();
}

class _AduanFormState extends State<AduanForm> {
  int kind = 0;
  bool anon = true;
  final when = TextEditingController(), who = TextEditingController(), body = TextEditingController();
  @override
  void dispose() {
    when.dispose();
    who.dispose();
    body.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (body.text.trim().isEmpty) return toast(context, 'Ceritakan dulu laporanmu');
    final isAspirasi = kind == 2;
    final text = [
      if (!isAspirasi && when.text.trim().isNotEmpty) 'Waktu/lokasi: ${when.text.trim()}',
      if (!isAspirasi && who.text.trim().isNotEmpty) 'Pihak terkait: ${who.text.trim()}',
      body.text.trim(),
    ].join('\n');
    final a = Aduan('AD-00${DataStore.i.aduanSeq++}', aduanKinds[kind], text, Session.name, anon,
        'Baru', '');
    await firebase_service.FirebaseService.i.addAduan(a);
    if (!mounted) return;
    NotifService.i.notify(
        '🛡️', 'Laporan baru: ${a.kind}', '#${a.id} · ${anon ? 'Anonim' : Session.name}',
        bg: kRedBg, roles: {Role.admin});
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => AduanDetail(a, justSent: true)));
  }

  @override
  Widget build(BuildContext c) => Page('Buat laporan / aspirasi', bottom: Btn('Kirim', submit), [
        const Text('Jenis', style: TextStyle(color: kMuted, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Wrap(spacing: 8, runSpacing: 0, children: [
          for (final (i, k) in aduanKinds.indexed)
            ChoiceChip(
                label: Text(k),
                selected: kind == i,
                showCheckmark: false,
                selectedColor: kPrimary,
                labelStyle: TextStyle(color: kind == i ? Colors.white : kInk),
                shape: const StadiumBorder(),
                onSelected: (_) => setState(() => kind = i)),
        ]),
        const SizedBox(height: 12),
        if (kind != 2) ...[
          Field('Waktu & lokasi kejadian (opsional)', controller: when),
          Field('Pihak terkait (opsional)', controller: who),
        ],
        Field(kind == 2 ? 'Tulis aspirasi / sarangmu' : 'Ceritakan apa yang terjadi',
            controller: body, maxLines: 5),
        Card2(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('🕶️ Kirim anonim'),
                subtitle: const Text(
                    'Admin tidak melihat namamu. Kamu tetap dapat notifikasi status.',
                    style: TextStyle(fontSize: 12)),
                value: anon,
                activeThumbColor: kPrimary,
                onChanged: (v) => setState(() => anon = v))),
        if (kind == 0 || kind == 1)
          const Card2(
              color: kYellowBg,
              child: Text(
                  '🆘 Kalau kamu atau temanmu dalam bahaya sekarang, segera hubungi guru/BK terdekat.',
                  style: TextStyle(color: kAmber, fontSize: 12))),
      ]);
}

class AduanDetail extends StatelessWidget {
  final Aduan a;
  final bool justSent;
  const AduanDetail(this.a, {super.key, this.justSent = false});
  @override
  Widget build(BuildContext c) {
    final s = aduanStyle(a.kind);
    return Page('Detail laporan', [
      if (justSent)
        const Card2(
            color: kGreenBg,
            child: Text('✅ Terkirim. Kamu akan dapat notifikasi saat admin menindaklanjuti.',
                style: TextStyle(color: kGreen))),
      Card2(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Emoji(s.$1, bg: s.$2, size: 44),
          const SizedBox(width: 12),
          Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(a.kind, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            Text('#${a.id} · ${a.anon ? 'Anonim' : 'Dengan nama'}',
                style: const TextStyle(color: kMuted, fontSize: 12)),
          ])),
          Pill.status(a.status),
        ]),
        const SizedBox(height: 10),
        Text(a.body, style: const TextStyle(height: 1.5)),
      ])),
      Card2(
          child: Timeline([
        ('Laporan diterima', 'Masuk ke admin sekolah', true),
        ('Ditinjau & ditindaklanjuti',
            a.status == 'Baru' ? 'Menunggu admin...' : 'Sedang ditangani', a.status != 'Baru'),
        ('Selesai', '—', a.status == 'Selesai'),
      ])),
      if (a.reply.isNotEmpty)
        Card2(
            child: Row(children: [
          const Emoji('🛡️', bg: kBlueBg, size: 44),
          const SizedBox(width: 12),
          Expanded(child: Text('Balasan admin\n${a.reply}'))
        ])),
    ]);
  }
}

// ================= KARTU ADMIN: tindak lanjut laporan =================
class AduanCard extends StatefulWidget {
  final Aduan a;
  final VoidCallback onSaved;
  const AduanCard({super.key, required this.a, required this.onSaved});
  @override
  State<AduanCard> createState() => _AduanCardState();
}

class _AduanCardState extends State<AduanCard> {
  late String status = widget.a.status;
  late final reply = TextEditingController(text: widget.a.reply);
  @override
  void dispose() {
    reply.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext c) {
    final a = widget.a;
    final s = aduanStyle(a.kind);
    return Card2(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Emoji(s.$1, bg: s.$2, size: 46),
            const SizedBox(width: 12),
            Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(a.kind, style: const TextStyle(fontWeight: FontWeight.w700)),
              Text('#${a.id} · ${a.anon ? '🕶️ Anonim (identitas disembunyikan)' : 'oleh ${a.owner}'}',
                  style: const TextStyle(color: kMuted, fontSize: 12)),
            ])),
          ]),
          const SizedBox(height: 10),
          Text(a.body, style: const TextStyle(height: 1.5)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
              initialValue: status,
              decoration: const InputDecoration(labelText: 'Ubah status', border: OutlineInputBorder()),
              items: [
                for (final st in ['Baru', 'Diproses', 'Selesai'])
                  DropdownMenuItem(value: st, child: Text(st))
              ],
              onChanged: (v) => setState(() => status = v!)),
          const SizedBox(height: 10),
          TextField(
              controller: reply,
              decoration: const InputDecoration(
                  labelText: 'Balasan untuk pelapor', border: OutlineInputBorder())),
          const SizedBox(height: 10),
          Btn('Simpan & kirim notifikasi', () {
            a.status = status;
            a.reply = reply.text;
            firebase_service.FirebaseService.i.updateAduan(a);
            NotifService.i.notify(
                '🛡️', 'Laporanmu diperbarui', '#${a.id} → ${a.status}',
                bg: kBlueBg, to: a.owner);
            widget.onSaved();
          }),
        ]));
  }
}