import 'package:sekolahku/models/akademik.dart';

/// Fungsi statistik & filter murni (pure) untuk data nilai akademik.
/// Dipisah dari Firebase supaya bisa diuji tanpa backend hidup.

/// Urutkan nilai terbaru duluan (desc by tanggal). Tidak memutasi input.
List<GradeRecord> sortGradesDesc(List<GradeRecord> grades) =>
    List.of(grades)..sort((a, b) => b.tanggal.compareTo(a.tanggal));

double averageOf(List<GradeRecord> grades) {
  if (grades.isEmpty) return 0;
  return grades.fold<double>(0, (acc, e) => acc + e.nilai) / grades.length;
}

List<MapEntry<String, double>> averageByMapel(List<GradeRecord> grades) {
  final grouped = <String, List<double>>{};
  for (final r in grades) {
    grouped.putIfAbsent(r.mapel, () => []).add(r.nilai);
  }
  final res = <MapEntry<String, double>>[
    for (final e in grouped.entries)
      MapEntry(e.key, e.value.reduce((a, b) => a + b) / e.value.length),
  ];
  res.sort((a, b) => b.value.compareTo(a.value));
  return res;
}

String trendOf(List<GradeRecord> grades) {
  final g = sortGradesDesc(grades);
  if (g.length < 2) return 'Stabil';
  final recent = g.take(3).map((e) => e.nilai).toList();
  final older = g.skip(3).take(3).map((e) => e.nilai).toList();
  if (older.isEmpty) return 'Bagus';
  final avgRecent = recent.reduce((a, b) => a + b) / recent.length;
  final avgOlder = older.reduce((a, b) => a + b) / older.length;
  if (avgRecent - avgOlder >= 2.0) {
    return 'Meningkat (+${(avgRecent - avgOlder).toStringAsFixed(1)})';
  }
  if (avgOlder - avgRecent >= 2.0) {
    return 'Menurun (-${(avgOlder - avgRecent).toStringAsFixed(1)})';
  }
  return 'Stabil';
}

/// Siswa yang menjadi bimbingan guru ini (wali kelas dan/atau mapel yang
/// diampu). Kalau relasi guru tidak ditemukan, kembalikan semua siswa.
List<Student> studentsForGuru(
  List<Student> all,
  List<GuruRelation> rels,
  String guruName,
) {
  GuruRelation? rel;
  for (final g in rels) {
    if (g.guruName == guruName) {
      rel = g;
      break;
    }
  }
  if (rel == null) return all;
  final r = rel;
  if (r.waliKelas != null) {
    final wali = all.where((s) => s.kelas == r.waliKelas).toList();
    final others = all
        .where((s) =>
            s.kelas != r.waliKelas &&
            s.grades.any((g) => r.mapel.contains(g.mapel)))
        .toList();
    return [...wali, ...others];
  }
  final list = all
      .where((s) => s.grades.any((g) => r.mapel.contains(g.mapel)))
      .toList();
  return list.isNotEmpty ? list : all;
}