import 'package:flutter/material.dart' hide Page;

import 'package:sekolahku/core/theme.dart';
import 'package:sekolahku/models/complaint.dart';
import 'package:sekolahku/models/role.dart';
import 'package:sekolahku/models/session.dart';
import 'package:sekolahku/services/data_store.dart';
import 'package:sekolahku/services/firebase_service.dart' as firebase_service;
import 'package:sekolahku/services/notif_service.dart';
import 'package:sekolahku/widgets/widgets.dart';

// ================= PENGADUAN FASILITAS =================
class PengaduanScreen extends StatefulWidget {
  const PengaduanScreen({super.key});
  @override
  State<PengaduanScreen> createState() => _PengaduanState();
}

class _PengaduanState extends State<PengaduanScreen> {
  void refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext c) {
    return StreamBuilder<List<Complaint>>(
      stream: firebase_service.FirebaseService.i.complaintsStream(),
      builder: (context, snap) {
        final mine = (snap.data ?? const <Complaint>[])
            .where((x) => x.owner == Session.name)
            .toList();
        final active = mine.where((x) => x.status != 'Selesai').length;
        return Page('Pengaduan fasilitas',
            fab: (Session.role == Role.ortu)
                ? null
                : fabAdd(() => go(c, const BuatLaporan()).then((_) => refresh())),
            [
              Row(children: [
                for (final s in [
                  ('$active', 'Laporan aktif', kRedBg),
                  ('${mine.length - active}', 'Sudah selesai', kGreenBg)
                ])
                  Expanded(
                      child: Container(
                          margin: const EdgeInsets.only(right: 8, bottom: 8),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: s.$3, borderRadius: BorderRadius.circular(20)),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(s.$1, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
                            Text(s.$2, style: const TextStyle(color: kMuted, fontSize: 12)),
                          ]))),
              ]),
              const H('Laporan saya'),
              if (mine.isEmpty)
                const Padding(
                    padding: EdgeInsets.all(30),
                    child: Center(
                        child: Text('Belum ada laporan. Tekan + untuk membuat.',
                            style: TextStyle(color: kMuted)))),
              for (final x in mine)
                infoRow('🛠️', kRedBg, x.title, '${x.loc} · #${x.id}',
                    trailing: Pill.status(x.status), onTap: () => go(c, DetailLaporan(x))),
              H('Papan publik', more: 'Lihat semua', onMore: () => go(c, const PapanPublik())),
              infoRow('💡', kGreenBg, 'Lampu lorong mati', 'Selesai dalam 2 hari',
                  trailing: Pill.status('Selesai')),
            ]);
      },
    );
  }
}

class BuatLaporan extends StatefulWidget {
  const BuatLaporan({super.key});
  @override
  State<BuatLaporan> createState() => _BuatLaporanState();
}

class _BuatLaporanState extends State<BuatLaporan> {
  int cat = 0;
  final loc = TextEditingController(), title = TextEditingController(), desc = TextEditingController();
  @override
  void dispose() {
    loc.dispose();
    title.dispose();
    desc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext c) => Page('Buat laporan',
          bottom: Btn('Kirim laporan', () async {
            if (title.text.trim().isEmpty) return toast(c, 'Isi judul laporan');
            final x = Complaint(
                'PF-00${DataStore.i.complaintSeq++}',
                title.text.trim(),
                loc.text.trim().isEmpty ? 'Sekolah' : loc.text.trim(),
                Session.name,
                'Baru',
                'Belum ditentukan',
                '',
                Session.name);
            await firebase_service.FirebaseService.i.addComplaint(x);
            if (!c.mounted) return;
            NotifService.i.notify('🛠️', 'Pengaduan fasilitas baru', '${x.title} · oleh ${Session.name}',
                bg: kRedBg, roles: {Role.admin});
            Navigator.pushReplacement(c, MaterialPageRoute(builder: (_) => LaporanTerkirim(x)));
          }),
          [
            const Text('Kategori', style: TextStyle(color: kMuted, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Chips(const ['Kelas', 'Toilet', 'Lab', 'Lapangan', 'Lainnya'], cat,
                (i) => setState(() => cat = i)),
            const SizedBox(height: 8),
            Field('Lokasi', controller: loc),
            Field('Judul', controller: title),
            Field('Deskripsi', controller: desc, maxLines: 3),
            const Text('Foto bukti', style: TextStyle(color: kMuted, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            OutlinedButton.icon(
                onPressed: () => toast(c, 'Pilih foto (tambahkan image_picker di versi lanjut)'),
                icon: const Icon(Icons.add_a_photo_outlined),
                label: const Text('Tambah foto')),
          ]);
}

class LaporanTerkirim extends StatelessWidget {
  final Complaint x;
  const LaporanTerkirim(this.x, {super.key});
  @override
  Widget build(BuildContext c) => Page('', back: false,
          bottom: Btn('Lacak laporan',
              () => Navigator.pushReplacement(c, MaterialPageRoute(builder: (_) => DetailLaporan(x)))),
          [
            const SizedBox(height: 50),
            const Center(child: Text('📨', style: TextStyle(fontSize: 80))),
            const Center(
                child: Text('Laporan terkirim',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700))),
            const Center(
                child: Text(
                    'Terima kasih sudah peduli.\nKamu akan dapat notifikasi saat status berubah.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: kMuted))),
            const SizedBox(height: 20),
            Card2(
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Nomor laporan', style: TextStyle(color: kMuted)),
              Text('#${x.id}', style: const TextStyle(fontWeight: FontWeight.w700))
            ])),
          ]);
}

class DetailLaporan extends StatelessWidget {
  final Complaint x;
  const DetailLaporan(this.x, {super.key});
  @override
  Widget build(BuildContext c) {
    final started = x.status != 'Baru';
    return Page('Detail laporan', [
      Card2(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(x.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        Text('#${x.id} · ${x.loc}', style: const TextStyle(color: kMuted, fontSize: 12)),
        const SizedBox(height: 8),
        Pill.status(x.status),
        const SizedBox(height: 8),
        LinearProgressIndicator(
            value: switch (x.status) {
              'Baru' => .25,
              'Diproses' => .66,
              _ => 1.0,
            },
            color: kPrimary,
            backgroundColor: kSoft),
        const SizedBox(height: 6),
        Text('Penanggung jawab: ${x.pic}', style: const TextStyle(color: kMuted, fontSize: 12)),
      ])),
      Card2(
          child: Timeline([
        ('Laporan diterima', 'Masuk ke admin', true),
        ('Diverifikasi admin', started ? 'Sudah diverifikasi' : 'Menunggu...', started),
        ('Sedang diproses', started ? x.pic : '—', started),
        ('Selesai', '—', x.status == 'Selesai'),
      ])),
      if (x.reply.isNotEmpty)
        Card2(
            child: Row(children: [
          const Emoji('🧑‍🔧', bg: kBlueBg, size: 44),
          const SizedBox(width: 12),
          Expanded(child: Text('Balasan petugas\n${x.reply}'))
        ])),
    ]);
  }
}

class PapanPublik extends StatelessWidget {
  const PapanPublik({super.key});
  @override
  Widget build(BuildContext c) => Page('Papan publik', [
        const GCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Rata-rata penanganan bulan ini', style: TextStyle(color: Colors.white70)),
          Text('2,4 hari',
              style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w700)),
          Text('18 laporan selesai · 3 masih berjalan',
              style: TextStyle(color: Colors.white70, fontSize: 12)),
        ])),
        infoRow('💡', kGreenBg, 'Lampu lorong mati', 'Gedung A · Selesai 2 hari',
            trailing: const Icon(Icons.check, color: kMuted)),
        infoRow('🚪', kGreenBg, 'Engsel pintu lab patah', 'Lab Kimia · Selesai 1 hari',
            trailing: const Icon(Icons.check, color: kMuted)),
        infoRow('🪑', kGreenBg, 'Kursi patah kelas X-2', 'Gedung C · Selesai 3 hari',
            trailing: const Icon(Icons.check, color: kMuted)),
        infoRow('🚰', kYellowBg, 'Keran toilet bocor', 'Toilet lt. 2 · Hari ke-1',
            trailing: const Icon(Icons.more_horiz, color: kMuted)),
      ]);
}