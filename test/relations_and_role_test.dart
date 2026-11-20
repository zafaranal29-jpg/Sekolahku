import 'package:flutter_test/flutter_test.dart';
import 'package:sekolahku/models/akademik.dart';
import 'package:sekolahku/models/role.dart';
import 'package:sekolahku/services/academic_stats.dart';
import 'package:sekolahku/services/auth_service.dart';

void main() {
  group('Academic stats & data modeling (pure)', () {
    final grades = [
      GradeRecord('Matematika', 'UH 1', 'Ganjil 2026/2027', 85, DateTime(2026, 8, 15)),
      GradeRecord('Matematika', 'UTS', 'Ganjil 2026/2027', 88, DateTime(2026, 9, 20)),
      GradeRecord('Fisika', 'UH 1', 'Ganjil 2026/2027', 80, DateTime(2026, 8, 18)),
    ];

    test('averageOf computes the mean', () {
      expect(averageOf(grades), closeTo((85 + 88 + 80) / 3, 0.001));
      expect(averageOf(const <GradeRecord>[]), 0);
    });

    test('averageByMapel groups by subject', () {
      final byMapel = averageByMapel(grades);
      final m = byMapel.where((e) => e.key == 'Matematika');
      expect(m, isNotEmpty);
      expect(m.first.value, closeTo((85 + 88) / 2, 0.001));
    });

    test('trendOf returns a label', () {
      expect(trendOf(const <GradeRecord>[]), 'Stabil');
      expect(trendOf(grades), isNotEmpty);
    });

    test('studentsForGuru matches by wali kelas & mapel', () {
      final alex = Student('2024-0153', 'Alex Johnson', 'XI IPA 3', [
        GradeRecord('Matematika', 'UH 1', '', 85, DateTime(2026, 8, 15)),
      ]);
      final siti = Student('2024-0111', 'Siti Rahma', 'XI IPA 3', []);
      final bella = Student('2024-0120', 'Bella Anindya', 'XI IPA 2', [
        GradeRecord('Kimia', 'UH 1', '', 86, DateTime(2026, 8, 20)),
      ]);
      final rels = [
        GuruRelation('Bu Rina Wulandari', waliKelas: 'XI IPA 3', mapel: const ['Matematika']),
        GuruRelation('Bu Maya', mapel: const ['Kimia']),
      ];

      final rina = studentsForGuru([alex, siti, bella], rels, 'Bu Rina Wulandari');
      expect(rina.any((s) => s.id == '2024-0153'), isTrue); // wali kelas
      expect(rina.any((s) => s.id == '2024-0111'), isTrue); // sekelas wali

      final maya = studentsForGuru([alex, siti, bella], rels, 'Bu Maya');
      expect(maya.any((s) => s.id == '2024-0120'), isTrue); // diampu mapel Kimia
    });

    test('AuthService maps role labels to Role enum (non-Firebase)', () {
      expect(AuthService.roleFromLabel('Ortu'), Role.ortu);
      expect(AuthService.roleFromLabel('Guru'), Role.guru);
      expect(AuthService.roleFromLabel('Siswa'), Role.siswa);
      expect(AuthService.roleFromLabel('Tidak dikenal'), Role.siswa);
    });
  });
}