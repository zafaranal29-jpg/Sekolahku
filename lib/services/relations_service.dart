import 'package:sekolahku/models/akademik.dart';
import 'package:sekolahku/models/role.dart';

/// Service untuk relasi Siswa - Guru - Ortu dan database nilai perkembangan.
class RelationsService {
  static final RelationsService i = RelationsService._();
  RelationsService._() {
    _seed();
  }

  final Map<String, Student> _students = {}; // key: studentId (NIS)
  final List<OrtuLink> _ortuLinks = [];
  final List<GuruRelation> _guruRelations = [];

  void _seed() {
    // 1. Data Siswa & Riwayat Nilai
    final s1 = Student('2024-0153', 'Alex Johnson', 'XI IPA 3', [
      GradeRecord('Matematika', 'UH 1', 'Semester Ganjil 2026/2027', 85, DateTime(2026, 8, 15)),
      GradeRecord('Matematika', 'UTS', 'Semester Ganjil 2026/2027', 88, DateTime(2026, 9, 20)),
      GradeRecord('Matematika', 'UH 2', 'Semester Ganjil 2026/2027', 92, DateTime(2026, 10, 14)),
      GradeRecord('Fisika', 'UH 1', 'Semester Ganjil 2026/2027', 78, DateTime(2026, 8, 18)),
      GradeRecord('Fisika', 'UTS', 'Semester Ganjil 2026/2027', 82, DateTime(2026, 9, 22)),
      GradeRecord('Kimia', 'UH 1', 'Semester Ganjil 2026/2027', 90, DateTime(2026, 8, 20)),
      GradeRecord('Kimia', 'UTS', 'Semester Ganjil 2026/2027', 91, DateTime(2026, 9, 25)),
      GradeRecord('Bahasa Indonesia', 'UH 1', 'Semester Ganjil 2026/2027', 88, DateTime(2026, 8, 12)),
      GradeRecord('Bahasa Inggris', 'UH 1', 'Semester Ganjil 2026/2027', 94, DateTime(2026, 8, 14)),
    ]);

    final s2 = Student('2024-0120', 'Bella Anindya', 'XI IPA 2', [
      GradeRecord('Matematika', 'UH 1', 'Semester Ganjil 2026/2027', 90, DateTime(2026, 8, 15)),
      GradeRecord('Matematika', 'UTS', 'Semester Ganjil 2026/2027', 94, DateTime(2026, 9, 20)),
      GradeRecord('Kimia', 'UH 1', 'Semester Ganjil 2026/2027', 86, DateTime(2026, 8, 20)),
      GradeRecord('Biologi', 'UH 1', 'Semester Ganjil 2026/2027', 92, DateTime(2026, 8, 22)),
      GradeRecord('Bahasa Indonesia', 'UH 1', 'Semester Ganjil 2026/2027', 95, DateTime(2026, 8, 12)),
    ]);

    final s3 = Student('2024-0144', 'Dimas Pratama', 'XI IPA 2', [
      GradeRecord('Matematika', 'UH 1', 'Semester Ganjil 2026/2027', 72, DateTime(2026, 8, 15)),
      GradeRecord('Matematika', 'UTS', 'Semester Ganjil 2026/2027', 75, DateTime(2026, 9, 20)),
      GradeRecord('Fisika', 'UH 1', 'Semester Ganjil 2026/2027', 70, DateTime(2026, 8, 18)),
      GradeRecord('Kimia', 'UH 1', 'Semester Ganjil 2026/2027', 74, DateTime(2026, 8, 20)),
    ]);

    final s4 = Student('2024-0111', 'Siti Rahma', 'XI IPA 3', [
      GradeRecord('Matematika', 'UH 1', 'Semester Ganjil 2026/2027', 91, DateTime(2026, 8, 15)),
      GradeRecord('Matematika', 'UTS', 'Semester Ganjil 2026/2027', 93, DateTime(2026, 9, 20)),
      GradeRecord('Kimia', 'UH 1', 'Semester Ganjil 2026/2027', 89, DateTime(2026, 8, 20)),
    ]);

    for (final s in [s1, s2, s3, s4]) {
      _students[s.id] = s;
    }

    // 2. Relasi Ortu -> Siswa (1 entitas ortu terhubung ke spesifik ID Siswa)
    _ortuLinks.add(OrtuLink('Pak Hendra Johnson', '2024-0153')); // orang tua dari Alex

    // 3. Relasi Guru -> Kelas / Mapel
    // Bu Rina Wulandari: Wali kelas XI IPA 3 & Pengampu Matematika (mengajar XI IPA 2 & 3)
    _guruRelations.add(GuruRelation(
      'Bu Rina Wulandari',
      waliKelas: 'XI IPA 3',
      mapel: const ['Matematika'],
    ));

    // Bu Maya: Pengampu Kimia (mengajar semua kelas XI)
    _guruRelations.add(GuruRelation(
      'Bu Maya',
      waliKelas: null,
      mapel: const ['Kimia'],
    ));
  }

  // --- QUERY ORTU ---
  /// Mengambil anak dari Ortu berdasarkan nama ortu.
  Student? getStudentForOrtu(String ortuName) {
    final link = _ortuLinks.where((l) => l.ortuName == ortuName).firstOrNull;
    if (link == null) return null;
    return _students[link.studentId];
  }

  void linkOrtuToStudent({required String ortuName, required String studentId}) {
    _ortuLinks.removeWhere((l) => l.ortuName == ortuName);
    _ortuLinks.add(OrtuLink(ortuName, studentId));
  }

  // --- QUERY GURU ---
  GuruRelation? getGuruRelation(String guruName) =>
      _guruRelations.where((g) => g.guruName == guruName).firstOrNull;

  /// Daftar siswa yang relevan untuk guru tertentu:
  /// - Siswa dari kelas binaan (wali kelas)
  /// - Atau seluruh siswa kelas XI jika guru pengampu mapel
  List<Student> getStudentsForGuru(String guruName) {
    final rel = getGuruRelation(guruName);
    if (rel == null) return _students.values.toList();
    if (rel.waliKelas != null) {
      final waliStudents =
          _students.values.where((s) => s.kelas == rel.waliKelas).toList();
      // Siswa kelas lain yang diajar mapelnya juga disertakan
      final others = _students.values
          .where((s) => s.kelas != rel.waliKelas && s.grades.any((g) => rel.mapel.contains(g.mapel)))
          .toList();
      return [...waliStudents, ...others];
    }
    // Guru mapel umum: siswa yang punya nilai mapel terkait
    final list = _students.values
        .where((s) => s.grades.any((g) => rel.mapel.contains(g.mapel)))
        .toList();
    return list.isNotEmpty ? list : _students.values.toList();
  }

  // --- FILTER MULTI-ROLE UNTUK HALAMAN PERKEMBANGAN SISWA ---
  List<Student> studentsVisibleTo({required Role role, required String name}) {
    switch (role) {
      case Role.ortu:
        final s = getStudentForOrtu(name);
        return s != null ? [s] : [];
      case Role.guru:
        return getStudentsForGuru(name);
      case Role.siswa:
        // Siswa hanya boleh melihat nilainya sendiri
        final s = _students.values.where((x) => x.name == name).firstOrNull;
        return s != null ? [s] : [];
      case Role.admin:
      case Role.koperasi:
        return _students.values.toList();
    }
  }

  // --- DATA NILAI & STATISTIK ---
  Student? findStudentById(String id) => _students[id];

  List<GradeRecord> gradesOf(String studentId) {
    final s = _students[studentId];
    if (s == null) return [];
    return List.unmodifiable(s.grades..sort((a, b) => b.tanggal.compareTo(a.tanggal)));
  }

  double averageOf(String studentId) {
    final g = gradesOf(studentId);
    if (g.isEmpty) return 0;
    final sum = g.fold<double>(0, (acc, e) => acc + e.nilai);
    return sum / g.length;
  }

  List<MapEntry<String, double>> averageByMapel(String studentId) {
    final g = gradesOf(studentId);
    final grouped = <String, List<double>>{};
    for (final r in g) {
      grouped.putIfAbsent(r.mapel, () => []).add(r.nilai);
    }
    final res = <MapEntry<String, double>>[];
    for (final e in grouped.entries) {
      final avg = e.value.reduce((a, b) => a + b) / e.value.length;
      res.add(MapEntry(e.key, avg));
    }
    res.sort((a, b) => b.value.compareTo(a.value));
    return res;
  }

  String trendOf(String studentId) {
    final g = gradesOf(studentId);
    if (g.length < 2) return 'Stabil';
    final recent = g.take(3).map((e) => e.nilai).toList();
    final older = g.skip(3).take(3).map((e) => e.nilai).toList();
    if (older.isEmpty) return 'Bagus';
    final avgRecent = recent.reduce((a, b) => a + b) / recent.length;
    final avgOlder = older.reduce((a, b) => a + b) / older.length;
    if (avgRecent - avgOlder >= 2.0) return 'Meningkat (+${(avgRecent - avgOlder).toStringAsFixed(1)})';
    if (avgOlder - avgRecent >= 2.0) return 'Menurun (-${(avgOlder - avgRecent).toStringAsFixed(1)})';
    return 'Stabil';
  }

  void addGrade(String studentId, GradeRecord grade) {
    final s = _students[studentId];
    if (s != null) {
      s.grades.add(grade);
    }
  }
}