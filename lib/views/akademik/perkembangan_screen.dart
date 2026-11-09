import 'package:flutter/material.dart' hide Page;

import 'package:sekolahku/core/theme.dart';
import 'package:sekolahku/models/akademik.dart';
import 'package:sekolahku/models/role.dart';
import 'package:sekolahku/models/session.dart';
import 'package:sekolahku/services/relations_service.dart';
import 'package:sekolahku/widgets/widgets.dart';

/// Halaman Perkembangan Siswa: menampilkan riwayat nilai anak (Ortu)
/// atau siswa bimbingan (Guru), lengkap dengan rata-rata, tren, dan rincian mapel.
class PerkembanganScreen extends StatefulWidget {
  final Student? initialStudent;
  const PerkembanganScreen({super.key, this.initialStudent});

  @override
  State<PerkembanganScreen> createState() => _PerkembanganScreenState();
}

class _PerkembanganScreenState extends State<PerkembanganScreen> {
  final RelationsService _svc = RelationsService.i;
  late List<Student> _available;
  Student? _current;
  String _mapelFilter = 'Semua';

  @override
  void initState() {
    super.initState();
    _available = _svc.studentsVisibleTo(role: Session.role, name: Session.name);
    _current = widget.initialStudent ?? (_available.isNotEmpty ? _available.first : null);
  }

  Color _scoreColor(double v) {
    if (v >= 85) return kGreen;
    if (v >= 75) return kAmber;
    return kRed;
  }

  Color _scoreBg(double v) {
    if (v >= 85) return kGreenBg;
    if (v >= 75) return kYellowBg;
    return kRedBg;
  }

  @override
  Widget build(BuildContext c) {
    final s = _current;
    final isOrtu = Session.role == Role.ortu;
    final isGuru = Session.role == Role.guru;

    if (s == null) {
      return const Page(
        'Perkembangan Siswa',
        [
          SizedBox(height: 40),
          Center(child: Text('👨‍👩‍👧', style: TextStyle(fontSize: 72))),
          SizedBox(height: 16),
          Center(
              child: Text('Data siswa tidak ditemukan',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18))),
          SizedBox(height: 8),
          Center(
              child: Text(
            'Akun ini belum ditautkan ke data siswa sekolah.',
            style: TextStyle(color: kMuted),
            textAlign: TextAlign.center,
          )),
        ],
      );
    }

    final allGrades = _svc.gradesOf(s.id);
    final mapels = ['Semua', ...{for (final g in allGrades) g.mapel}];
    final filteredGrades = _mapelFilter == 'Semua'
        ? allGrades
        : allGrades.where((g) => g.mapel == _mapelFilter).toList();
    final avg = _svc.averageOf(s.id);
    final trend = _svc.trendOf(s.id);
    final byMapel = _svc.averageByMapel(s.id);

    return Page(
      'Perkembangan Siswa',
      [
        // Banner info relasi
        if (isOrtu)
          Card2(
            color: kSoft,
            child: Row(children: [
              const Emoji('👨‍👩‍👧', bg: Colors.white, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Portal Orang Tua / Wali',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  Text(
                    'Memantau perkembangan belajar: ${s.name} (NIS: ${s.id}) · Kelas ${s.kelas}',
                    style: const TextStyle(color: kMuted, fontSize: 12),
                  ),
                ]),
              ),
              const Pill('Read-only', bg: Colors.white, fg: kPrimary),
            ]),
          ),

        // Pemilih siswa jika guru membimbing >1 siswa
        if (isGuru && _available.length > 1) ...[
          const Text('Pilih Siswa', style: TextStyle(color: kMuted, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Card2(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Student>(
                isExpanded: true,
                value: s,
                items: [
                  for (final st in _available)
                    DropdownMenuItem(
                      value: st,
                      child: Text('${st.name} · ${st.kelas} (${st.id})',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                ],
                onChanged: (newSt) {
                  if (newSt != null) setState(() => _current = newSt);
                },
              ),
            ),
          ),
          const SizedBox(height: 6),
        ],

        // Kartu Ringkasan Akademik
        GCard(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.name,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                Text('Kelas ${s.kelas} · NIS ${s.id}',
                    style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ]),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text('📊', style: TextStyle(fontSize: 32)),
              ),
            ]),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                Column(children: [
                  const Text('Rata-rata', style: TextStyle(color: Colors.white70, fontSize: 11)),
                  const SizedBox(height: 2),
                  Text(avg.toStringAsFixed(1),
                      style: const TextStyle(
                          color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                ]),
                Container(width: 1, height: 32, color: Colors.white24),
                Column(children: [
                  const Text('Tren Belajar', style: TextStyle(color: Colors.white70, fontSize: 11)),
                  const SizedBox(height: 2),
                  Text(trend,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                ]),
                Container(width: 1, height: 32, color: Colors.white24),
                Column(children: [
                  const Text('Total Evaluasi', style: TextStyle(color: Colors.white70, fontSize: 11)),
                  const SizedBox(height: 2),
                  Text('${allGrades.length}',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                ]),
              ]),
            ),
          ]),
        ),

        // Rata-rata per Mata Pelajaran
        const H('Capaian per Mata Pelajaran'),
        for (final m in byMapel)
          Card2(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(m.key, style: const TextStyle(fontWeight: FontWeight.w700)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: _scoreBg(m.value),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(m.value.toStringAsFixed(1),
                      style: TextStyle(
                          color: _scoreColor(m.value),
                          fontWeight: FontWeight.w700,
                          fontSize: 12)),
                ),
              ]),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (m.value / 100).clamp(0.0, 1.0),
                  color: _scoreColor(m.value),
                  backgroundColor: kSoft,
                  minHeight: 8,
                ),
              ),
            ]),
          ),

        const SizedBox(height: 8),

        // Filter Mapel
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Riwayat Nilai',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          if (mapels.length > 2)
            DropdownButton<String>(
              value: _mapelFilter,
              underline: const SizedBox(),
              icon: const Icon(Icons.filter_list, color: kPrimary, size: 20),
              style: const TextStyle(color: kPrimary, fontWeight: FontWeight.w600, fontSize: 12),
              items: [for (final mp in mapels) DropdownMenuItem(value: mp, child: Text(mp))],
              onChanged: (v) {
                if (v != null) setState(() => _mapelFilter = v);
              },
            ),
        ]),
        const SizedBox(height: 8),

        if (filteredGrades.isEmpty)
          const Padding(
            padding: EdgeInsets.all(30),
            child: Center(
                child: Text('Belum ada nilai tercatat.', style: TextStyle(color: kMuted))),
          ),

        for (final g in filteredGrades)
          Card2(
            child: Row(children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _scoreBg(g.nilai),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  g.nilai.toStringAsFixed(0),
                  style: TextStyle(
                      color: _scoreColor(g.nilai),
                      fontSize: 18,
                      fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(g.mapel, style: const TextStyle(fontWeight: FontWeight.w700)),
                    Pill(g.jenis, bg: kSoft, fg: kPrimary),
                  ]),
                  const SizedBox(height: 2),
                  Text('${g.semester} · ${fmtDate(g.tanggal)}',
                      style: const TextStyle(color: kMuted, fontSize: 12)),
                ]),
              ),
            ]),
          ),

        const SizedBox(height: 10),
        const Card2(
          color: kYellowBg,
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('💡', style: TextStyle(fontSize: 22)),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Data nilai diperbarui oleh guru mata pelajaran dan diverifikasi wali kelas.',
                style: TextStyle(color: kAmber, fontSize: 12),
              ),
            ),
          ]),
        ),
      ],
    );
  }
}