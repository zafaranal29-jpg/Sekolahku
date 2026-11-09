import 'package:flutter/material.dart' hide Page;

import 'package:sekolahku/core/theme.dart';
import 'package:sekolahku/models/booking.dart';
import 'package:sekolahku/models/role.dart';
import 'package:sekolahku/models/session.dart';
import 'package:sekolahku/services/firebase_service.dart' as firebase_service;
import 'package:sekolahku/services/notif_service.dart';
import 'package:sekolahku/widgets/widgets.dart';

// ================= BOOKING FASILITAS =================
class BookingScreen extends StatelessWidget {
  const BookingScreen({super.key});
  @override
  Widget build(BuildContext c) => Page('Booking fasilitas',
          action: IconButton(
              onPressed: () => go(c, const RiwayatBooking()), icon: const Icon(Icons.history)),
          [
            for (final f in [
              ('🏀', 'Lapangan Basket', 'Kapasitas 30 orang', 'Tersedia', kYellowBg),
              ('🔬', 'Lab Kimia', 'Kapasitas 36 orang', 'Tersedia', kGreenBg),
              ('🎭', 'Aula Utama', 'Kapasitas 300 orang', 'Terisi sebagian', kRedBg),
              ('💻', 'Lab Komputer', 'Kapasitas 40 orang', 'Penuh hari ini', kBlueBg),
            ])
              infoRow(f.$1, f.$5, f.$2, f.$3,
                  trailing: Pill.status(f.$4), onTap: () => go(c, FasilitasDetail(f.$1, f.$2))),
          ]);
}

class FasilitasDetail extends StatefulWidget {
  final String e, name;
  const FasilitasDetail(this.e, this.name, {super.key});
  @override
  State<FasilitasDetail> createState() => _FasilitasState();
}

class _FasilitasState extends State<FasilitasDetail> {
  int day = 1;
  String? slot;
  static const used = {'10:00', '11:00'};
  @override
  Widget build(BuildContext c) => Page(widget.name,
          bottom: Btn('Ajukan booking',
              slot == null ? null : () => go(c, FormBooking(widget.e, widget.name, 5 + day, slot!))),
          [
            Container(
                height: 120,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: kYellowBg, borderRadius: BorderRadius.circular(24)),
                child: Text(widget.e, style: const TextStyle(fontSize: 64))),
            const SizedBox(height: 12),
            Row(children: [
              for (final (i, d) in ['Kam 5', 'Jum 6', 'Sab 7', 'Min 8'].indexed)
                Expanded(
                    child: GestureDetector(
                        onTap: () => setState(() => day = i),
                        child: Container(
                            margin: const EdgeInsets.all(3),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                                color: day == i ? kPrimary : Colors.white,
                                borderRadius: BorderRadius.circular(18)),
                            child: Text(d,
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: day == i ? Colors.white : kInk))))),
            ]),
            const SizedBox(height: 8),
            for (final t in ['08:00', '09:00', '10:00', '11:00', '13:00', '15:00'])
              Card2(
                  color: used.contains(t) ? kRedBg : Colors.white,
                  border: slot == t ? kPrimary : null,
                  onTap: used.contains(t) ? null : () => setState(() => slot = t),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(t, style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(used.contains(t) ? 'Terpakai · XII IPA 2' : 'Tersedia',
                        style: const TextStyle(color: kMuted, fontSize: 12)),
                  ])),
          ]);
}

class FormBooking extends StatefulWidget {
  final String e, name, slot;
  final int date;
  const FormBooking(this.e, this.name, this.date, this.slot, {super.key});
  @override
  State<FormBooking> createState() => _FormBookingState();
}

class _FormBookingState extends State<FormBooking> {
  late final mulai = TextEditingController(text: widget.slot);
  @override
  void dispose() {
    mulai.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext c) => Page('Ajukan booking', [
        infoRow(widget.e, kYellowBg, widget.name, '${widget.date} Nov 2026 · mulai ${widget.slot}'),
        Field('Jam mulai', controller: mulai),
        const Field('Jam selesai'),
        const Field('Keperluan'),
        const Field('Jumlah peserta'),
        const Card2(
            color: kGreenBg,
            child: Text('✅ Tidak ada jadwal bentrok pada jam ini.',
                style: TextStyle(color: kGreen))),
        Btn('Kirim pengajuan', () async {
          final r = BookingReq(widget.e, widget.name, '${widget.date} Nov · mulai ${mulai.text}',
              '${Session.name} (${roleLabel(Session.role)})', 'Menunggu', Session.name);
          await firebase_service.FirebaseService.i.addBooking(r);
          if (!c.mounted) return;
          NotifService.i.notify('🏟️', 'Pengajuan booking baru', '${r.facility} · oleh ${Session.name}',
              bg: kYellowBg, roles: {Role.admin});
          Navigator.pushReplacement(c, MaterialPageRoute(builder: (_) => StatusBooking(r)));
        }),
      ]);
}

class StatusBooking extends StatefulWidget {
  final BookingReq r;
  const StatusBooking(this.r, {super.key});
  @override
  State<StatusBooking> createState() => _StatusBookingState();
}

class _StatusBookingState extends State<StatusBooking> {
  @override
  Widget build(BuildContext c) {
    final r = widget.r;
    final reviewed = r.status == 'Disetujui' || r.status == 'Ditolak';
    return Page('Status booking', [
      Card2(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Emoji(r.emoji, bg: kYellowBg, size: 44),
          const SizedBox(width: 12),
          Text(r.facility, style: const TextStyle(fontWeight: FontWeight.w700))
        ]),
        const SizedBox(height: 8),
        Pill.status(r.status),
      ])),
      Card2(
          child: Timeline([
        ('Pengajuan dikirim', r.when, true),
        ('Ditinjau admin', reviewed ? 'Sudah ditinjau' : 'Menunggu...', reviewed),
        (r.status == 'Ditolak' ? 'Ditolak' : 'Disetujui', '—', r.status == 'Disetujui'),
      ])),
      if (r.status == 'Menunggu')
        Btn('Batalkan pengajuan', () {
          setState(() => r.status = 'Dibatalkan');
          Navigator.popUntil(c, (x) => x.isFirst);
        }, outlined: true),
    ]);
  }
}

class RiwayatBooking extends StatelessWidget {
  const RiwayatBooking({super.key});
  @override
  Widget build(BuildContext c) {
    return StreamBuilder<List<BookingReq>>(
      stream: firebase_service.FirebaseService.i.bookingsStream(),
      builder: (context, snap) {
        final mine = (snap.data ?? const <BookingReq>[])
            .where((r) => r.owner == Session.name)
            .toList();
        return Page('Riwayat booking', [
          if (mine.isEmpty)
            const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: Text('Belum ada booking', style: TextStyle(color: kMuted)))),
          for (final r in mine)
            infoRow(r.emoji, kYellowBg, r.facility, r.when,
                trailing: Pill.status(r.status), onTap: () => go(c, StatusBooking(r))),
        ]);
      },
    );
  }
}