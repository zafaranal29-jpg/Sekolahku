import 'package:flutter_test/flutter_test.dart';
import 'package:sekolahku/models/role.dart';
import 'package:sekolahku/services/auth_service.dart';
import 'package:sekolahku/services/relations_service.dart';

void main() {
  group('RelationsService & Data Modeling Test', () {
    final svc = RelationsService.i;

    test('Ortu is linked to specific Student ID (Alex Johnson - 2024-0153)', () {
      final student = svc.getStudentForOrtu('Pak Hendra Johnson');
      expect(student, isNotNull);
      expect(student!.id, '2024-0153');
      expect(student.name, 'Alex Johnson');
      expect(student.kelas, 'XI IPA 3');
    });

    test('Guru is linked to Students by class and subjects', () {
      final guruStudents = svc.getStudentsForGuru('Bu Rina Wulandari');
      expect(guruStudents.isNotEmpty, isTrue);
      // Bu Rina is wali kelas for XI IPA 3, so Alex (XI IPA 3) and Siti (XI IPA 3) must be in her list
      expect(guruStudents.any((s) => s.id == '2024-0153'), isTrue);
      expect(guruStudents.any((s) => s.id == '2024-0111'), isTrue);
    });

    test('Student grades and progress calculation', () {
      final grades = svc.gradesOf('2024-0153');
      expect(grades.isNotEmpty, isTrue);

      final avg = svc.averageOf('2024-0153');
      expect(avg, greaterThan(80.0));

      final byMapel = svc.averageByMapel('2024-0153');
      expect(byMapel.isNotEmpty, isTrue);
      expect(byMapel.any((e) => e.key == 'Matematika'), isTrue);

      final trend = svc.trendOf('2024-0153');
      expect(trend.isNotEmpty, isTrue);
    });

    test('Access control: Ortu can only see their specific child', () {
      final visible = svc.studentsVisibleTo(
          role: Role.ortu, name: 'Pak Hendra Johnson');
      expect(visible.length, 1);
      expect(visible.first.name, 'Alex Johnson');
    });

    test('AuthService maps role labels to Role enum (non-Firebase)', () {
      expect(AuthService.roleFromLabel('Ortu'), Role.ortu);
      expect(AuthService.roleFromLabel('Guru'), Role.guru);
      expect(AuthService.roleFromLabel('Siswa'), Role.siswa);
      expect(AuthService.roleFromLabel('Tidak dikenal'), Role.siswa);
    });
  });
}