import 'dart:math';

import 'package:flutter/material.dart' hide Page;

import 'package:sekolahku/core/theme.dart';

class GCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const GCard({super.key, required this.child, this.padding = const EdgeInsets.all(18)});
  @override
  Widget build(BuildContext c) => Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: padding,
      decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(24)),
      child: child);
}

class Card2 extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color color;
  final VoidCallback? onTap;
  final Color? border;
  const Card2({super.key, required this.child, this.padding = const EdgeInsets.all(14),
    this.color = Colors.white, this.onTap, this.border});
  @override
  Widget build(BuildContext c) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
          color: color,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: border == null ? BorderSide.none : BorderSide(color: border!, width: 2)),
          child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: onTap,
              child: Padding(padding: padding, child: child))));
}

class Emoji extends StatelessWidget {
  final String e;
  final Color bg;
  final double size;
  const Emoji(this.e, {super.key, this.bg = kSoft, this.size = 52});
  @override
  Widget build(BuildContext c) => Container(
      width: size, height: size, alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(size * .3)),
      child: Text(e, style: TextStyle(fontSize: size * .5)));
}

class Pill extends StatelessWidget {
  final String t;
  final Color bg, fg;
  const Pill(this.t, {super.key, this.bg = kSoft, this.fg = kPrimary});
  factory Pill.status(String s) {
    final (bg, fg) = switch (s) {
      'Selesai' || 'Disetujui' || 'Tersedia' || 'Ditemukan' || 'Diverifikasi' || 'Aktif' => (kGreenBg, kGreen),
      'Dibatalkan' || 'Ditolak' || 'Penuh' => (kRedBg, kRed),
      'Diterima' || 'Diklaim' || 'Sudah memilih' => (kSoft, kPrimary),
      _ => (kYellowBg, kAmber),
    };
    return Pill(s, bg: bg, fg: fg);
  }
  @override
  Widget build(BuildContext c) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(t, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w700)));
}

class Btn extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool outlined;
  const Btn(this.label, this.onTap, {super.key, this.outlined = false});
  @override
  Widget build(BuildContext c) {
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(18));
    return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: SizedBox(
            width: double.infinity, height: 52,
            child: outlined
                ? OutlinedButton(
                    style: OutlinedButton.styleFrom(
                        shape: shape, foregroundColor: kPrimary, side: const BorderSide(color: kPrimary)),
                    onPressed: onTap,
                    child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)))
                : FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: kPrimary, shape: shape),
                    onPressed: onTap,
                    child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)))));
  }
}

class Field extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final bool obscure;
  final int maxLines;
  final Widget? suffix;
  final void Function(String)? onChanged;
  const Field(this.label, {super.key, this.controller, this.obscure = false,
    this.maxLines = 1, this.suffix, this.onChanged});
  @override
  Widget build(BuildContext c) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
          controller: controller, obscureText: obscure, maxLines: maxLines, onChanged: onChanged,
          decoration: InputDecoration(
              labelText: label, filled: true, fillColor: Colors.white, suffixIcon: suffix,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: Color(0xFFE6E3F5))))));
}

class H extends StatelessWidget {
  final String t;
  final String? more;
  final VoidCallback? onMore;
  const H(this.t, {super.key, this.more, this.onMore});
  @override
  Widget build(BuildContext c) => Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 10),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(t, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        if (more != null)
          GestureDetector(onTap: onMore,
              child: Text(more!, style: const TextStyle(color: kPrimary, fontWeight: FontWeight.w500))),
      ]));
}

class Chips extends StatelessWidget {
  final List<String> items;
  final int selected;
  final void Function(int) onSelect;
  const Chips(this.items, this.selected, this.onSelect, {super.key});
  @override
  Widget build(BuildContext c) => SizedBox(
      height: 46,
      child: ListView(scrollDirection: Axis.horizontal, children: [
        for (var i = 0; i < items.length; i++)
          Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                  label: Text(items[i]),
                  selected: i == selected,
                  showCheckmark: false,
                  selectedColor: kPrimary,
                  labelStyle: TextStyle(color: i == selected ? Colors.white : kInk, fontWeight: FontWeight.w500),
                  shape: const StadiumBorder(),
                  onSelected: (_) => onSelect(i)))
      ]));
}

class Page extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final Widget? bottom, action, fab;
  final bool back;
  const Page(this.title, this.children, {super.key, this.bottom, this.action, this.fab, this.back = true});
  @override
  Widget build(BuildContext c) => Scaffold(
      floatingActionButton: fab,
      body: SafeArea(
          child: Column(children: [
        Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: SizedBox(
                height: 44,
                child: Stack(alignment: Alignment.center, children: [
                  Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                  if (back && Navigator.canPop(c))
                    Align(
                        alignment: Alignment.centerLeft,
                        child: Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () => Navigator.maybePop(c),
                                child: const SizedBox(width: 44, height: 44, child: Icon(Icons.chevron_left))))),
                  if (action != null) Align(alignment: Alignment.centerRight, child: action),
                ]))),
        Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 20), children: children)),
        if (bottom != null) Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 16), child: bottom),
      ])));
}

Widget fabAdd(VoidCallback f) => FloatingActionButton(
    backgroundColor: kPrimary, onPressed: f, child: const Icon(Icons.add, color: Colors.white));

class Timeline extends StatelessWidget {
  final List<(String, String, bool)> steps;
  const Timeline(this.steps, {super.key});
  @override
  Widget build(BuildContext c) => Column(children: [
        for (var i = 0; i < steps.length; i++)
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Column(children: [
              CircleAvatar(
                  radius: 14,
                  backgroundColor: steps[i].$3 ? kPrimary : kSoft,
                  child: steps[i].$3 ? const Icon(Icons.check, size: 16, color: Colors.white) : null),
              if (i < steps.length - 1) Container(width: 3, height: 34, color: steps[i].$3 ? kPrimary : kSoft),
            ]),
            const SizedBox(width: 12),
            Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(steps[i].$1,
                  style: TextStyle(fontWeight: FontWeight.w700, color: steps[i].$3 ? kInk : kMuted)),
              Text(steps[i].$2, style: const TextStyle(color: kMuted, fontSize: 12)),
            ])),
          ])
      ]);
}

/// QR dummy untuk mockup (ganti dengan package qr_flutter di produksi).
class QrBox extends StatelessWidget {
  final int seed;
  const QrBox(this.seed, {super.key});
  @override
  Widget build(BuildContext c) => CustomPaint(size: const Size(200, 200), painter: _QrPainter(seed));
}

class _QrPainter extends CustomPainter {
  final int seed;
  _QrPainter(this.seed);
  @override
  void paint(Canvas canvas, Size s) {
    const n = 21;
    final cell = s.width / n;
    final dark = Paint()..color = kInk;
    final white = Paint()..color = Colors.white;
    final rnd = Random(seed);
    bool finder(int r, int col) =>
        (r < 7 && col < 7) || (r < 7 && col >= n - 7) || (r >= n - 7 && col < 7);
    for (var r = 0; r < n; r++) {
      for (var col = 0; col < n; col++) {
        if (!finder(r, col) && rnd.nextBool()) {
          canvas.drawRect(Rect.fromLTWH(col * cell, r * cell, cell, cell), dark);
        }
      }
    }
    for (final o in [const Offset(0, 0), Offset((n - 7) * cell, 0), Offset(0, (n - 7) * cell)]) {
      canvas.drawRect(Rect.fromLTWH(o.dx, o.dy, 7 * cell, 7 * cell), dark);
      canvas.drawRect(Rect.fromLTWH(o.dx + cell, o.dy + cell, 5 * cell, 5 * cell), white);
      canvas.drawRect(Rect.fromLTWH(o.dx + 2 * cell, o.dy + 2 * cell, 3 * cell, 3 * cell), dark);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

/// Baris kartu: emoji + judul + subjudul + trailing (dipakai banyak layar).
Widget infoRow(String e, Color bg, String title, String sub, {Widget? trailing, VoidCallback? onTap}) => Card2(
    onTap: onTap,
    child: Row(children: [
      Emoji(e, bg: bg),
      const SizedBox(width: 12),
      Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        Text(sub, style: const TextStyle(color: kMuted, fontSize: 12)),
      ])),
      if (trailing != null) trailing,
    ]));

class MiniBars extends StatelessWidget {
  final String title;
  final List<double> v;
  final List<String> l;
  const MiniBars(this.title, this.v, this.l, {super.key});
  @override
  Widget build(BuildContext c) => Card2(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        SizedBox(
            height: 110,
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              for (var i = 0; i < v.length; i++)
                Expanded(
                    child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                  Container(
                      height: 85 * v[i],
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(color: kPrimary.withValues(alpha: .4 + .6 * v[i]), borderRadius: BorderRadius.circular(8))),
                  const SizedBox(height: 4),
                  Text(l[i], style: const TextStyle(fontSize: 10, color: kMuted)),
                ]))
            ])),
      ]));
}

Widget statBox(String n, String label, Color bg) => Expanded(
    child: Container(
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(n, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
          Text(label, style: const TextStyle(color: kMuted, fontSize: 12)),
        ])));