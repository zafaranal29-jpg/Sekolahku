import 'package:flutter/material.dart' hide Page;

import 'package:sekolahku/core/theme.dart';
import 'package:sekolahku/models/agenda.dart';
import 'package:sekolahku/models/role.dart';
import 'package:sekolahku/models/session.dart';
import 'package:sekolahku/services/firebase_service.dart' as firebase_service;
import 'package:sekolahku/services/notif_service.dart';
import 'package:sekolahku/widgets/widgets.dart';

/// Kalender agenda: semua role melihat, hanya admin yang menambah/mengubah/menghapus.
class KalenderScreen extends StatefulWidget {
  const KalenderScreen({super.key});
  @override
  State<KalenderScreen> createState() => _KalenderState();
}

class _KalenderState extends State<KalenderScreen> {
  late DateTime month = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? sel;
  bool get admin => Session.role == Role.admin;
  static bool same(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void openForm(BuildContext c, AgendaEvent? e) => go<bool>(c, EventForm(e: e)).then((r) {
        if (r == true && mounted) setState(() {});
      });

  void detail(BuildContext c, AgendaEvent e) => showDialog<void>(
      context: c,
      builder: (x) => AlertDialog(
          title: Text('${e.emoji} ${e.title}'),
          content: Text('${fmtDate(e.date)}\n\n${e.desc}'),
          actions: [TextButton(onPressed: () => Navigator.pop(x), child: const Text('Tutup'))]));

  Widget cell(int n, int days, DateTime today, List<AgendaEvent> events) {
    if (n < 1 || n > days) return const Expanded(child: SizedBox(height: 46));
    final d = DateTime(month.year, month.month, n);
    final has = events.any((e) => same(e.date, d));
    final isSel = sel != null && same(sel!, d);
    final isToday = same(d, today);
    return Expanded(
        child: GestureDetector(
            onTap: () => setState(() => sel = isSel ? null : d),
            child: Container(
                height: 46,
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                    color: isSel ? kPrimary : (isToday ? kSoft : Colors.transparent),
                    borderRadius: BorderRadius.circular(14)),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('$n',
                      style: TextStyle(fontWeight: FontWeight.w700, color: isSel ? Colors.white : kInk)),
                  const SizedBox(height: 2),
                  Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: has ? (isSel ? Colors.white : kPrimary) : Colors.transparent)),
                ]))));
  }

  @override
  Widget build(BuildContext c) {
    final days = DateUtils.getDaysInMonth(month.year, month.month);
    final offset = DateTime(month.year, month.month, 1).weekday - 1;
    final weeks = (offset + days + 6) ~/ 7;
    final today = DateTime.now();
    return StreamBuilder<List<AgendaEvent>>(
      stream: firebase_service.FirebaseService.i.agendasStream(),
      builder: (context, snap) {
        final events = (snap.data ?? const <AgendaEvent>[])
            .where((e) => e.date.year == month.year && e.date.month == month.month)
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));
        final shown = sel == null ? events : events.where((e) => same(e.date, sel!)).toList();
        return Page('Kalender agenda', fab: admin ? fabAdd(() => openForm(c, null)) : null, [
          Card2(
              padding: const EdgeInsets.all(12),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  IconButton(
                      onPressed: () => setState(() { month = DateTime(month.year, month.month - 1); sel = null; }),
                      icon: const Icon(Icons.chevron_left)),
                  Text('${bulan[month.month - 1]} ${month.year}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  IconButton(
                      onPressed: () => setState(() { month = DateTime(month.year, month.month + 1); sel = null; }),
                      icon: const Icon(Icons.chevron_right)),
                ]),
                Row(children: [
                  for (final d in ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'])
                    Expanded(
                        child: Center(child: Text(d, style: const TextStyle(color: kMuted, fontSize: 11)))),
                ]),
                const SizedBox(height: 4),
                for (var w = 0; w < weeks; w++)
                  Row(children: [
                    for (var d = 0; d < 7; d++) cell(w * 7 + d - offset + 1, days, today, events)
                  ]),
              ])),
          if (!admin)
            const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text('Hanya admin yang dapat mengubah agenda.',
                    style: TextStyle(color: kMuted, fontSize: 12))),
          H(sel == null ? 'Agenda ${bulan[month.month - 1]}' : 'Agenda ${fmtDate(sel!)}'),
          if (shown.isEmpty)
            const Padding(
                padding: EdgeInsets.all(30),
                child: Center(child: Text('Tidak ada agenda', style: TextStyle(color: kMuted)))),
          for (final e in shown)
            infoRow(e.emoji, kSoft, e.title, '${fmtDate(e.date)} · ${e.desc}',
                trailing: admin ? const Icon(Icons.edit_outlined, color: kMuted, size: 20) : null,
                onTap: () => admin ? openForm(c, e) : detail(c, e)),
        ]);
      },
    );
  }
}

class EventForm extends StatefulWidget {
  final AgendaEvent? e;
  const EventForm({super.key, this.e});
  @override
  State<EventForm> createState() => _EventFormState();
}

class _EventFormState extends State<EventForm> {
  static const emojis = ['📅', '📝', '🏆', '🎭', '🏖️', '🏫'];
  late final title = TextEditingController(text: widget.e?.title);
  late final desc = TextEditingController(text: widget.e?.desc);
  late DateTime date = widget.e?.date ?? DateTime.now();
  late int emo = widget.e == null ? 0 : emojis.indexOf(widget.e!.emoji).clamp(0, emojis.length - 1);
  bool notif = false;

  @override
  void dispose() {
    title.dispose();
    desc.dispose();
    super.dispose();
  }

  Future<void> pick() async {
    final d = await showDatePicker(
        context: context,
        initialDate: date,
        firstDate: DateTime(2024),
        lastDate: DateTime(2032));
    if (d != null) setState(() => date = d);
  }

  Future<void> save() async {
    if (title.text.trim().isEmpty) return toast(context, 'Judul agenda wajib diisi');
    final e = widget.e;
    if (e == null) {
      await firebase_service.FirebaseService.i.addAgenda(
          AgendaEvent(date, title.text.trim(), desc.text.trim(), emojis[emo]));
    } else {
      e
        ..date = date
        ..title = title.text.trim()
        ..desc = desc.text.trim()
        ..emoji = emojis[emo];
      await firebase_service.FirebaseService.i.updateAgenda(e);
    }
    if (notif) {
      NotifService.i.notify(emojis[emo], e == null ? 'Agenda baru' : 'Agenda diperbarui',
          '${title.text.trim()} · ${fmtDate(date)}',
          bg: kBlueBg);
    }
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext c) => Page(widget.e == null ? 'Tambah agenda' : 'Ubah agenda',
          bottom: Column(children: [
            Btn('Simpan', save),
            if (widget.e != null)
              Btn('Hapus agenda', () async {
                await firebase_service.FirebaseService.i.deleteAgenda(widget.e!);
                if (c.mounted) Navigator.pop(c, true);
              }, outlined: true),
          ]),
          [
            Field('Judul agenda', controller: title),
            Field('Keterangan (lokasi, jam, dll)', controller: desc, maxLines: 3),
            const Text('Tanggal', style: TextStyle(color: kMuted, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            OutlinedButton.icon(
                onPressed: pick,
                icon: const Icon(Icons.calendar_month_outlined),
                label: Text(fmtDate(date))),
            const SizedBox(height: 12),
            const Text('Ikon', style: TextStyle(color: kMuted, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Chips(emojis, emo, (i) => setState(() => emo = i)),
            Card2(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('🔔 Kirim notifikasi ke semua'),
                    value: notif,
                    activeThumbColor: kPrimary,
                    onChanged: (v) => setState(() => notif = v))),
          ]);
}