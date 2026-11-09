import 'package:flutter/foundation.dart';

import 'package:sekolahku/models/akademik.dart';
import 'package:sekolahku/models/session.dart';
import 'package:sekolahku/services/relations_service.dart';

/// ViewModel untuk layar Perkembangan Siswa. Membungkus RelationsService.
class PerkembanganController extends ChangeNotifier {
  final RelationsService _svc = RelationsService.i;
  Student? _selected;

  /// Siswa yang tampak untuk role yang sedang login (ortu → anaknya; guru → kelas/mapel).
  List<Student> get students =>
      _svc.studentsVisibleTo(role: Session.role, name: Session.name);

  Student? get selected {
    if (_selected != null) return _selected;
    return students.length == 1 ? students.first : null;
  }

  void select(Student s) {
    _selected = s;
    notifyListeners();
  }

  List<GradeRecord> get grades =>
      selected == null ? const <GradeRecord>[] : _svc.gradesOf(selected!.id);

  double get average => selected == null ? 0 : _svc.averageOf(selected!.id);

  List<MapEntry<String, double>> get perMapel =>
      selected == null ? const [] : _svc.averageByMapel(selected!.id);

  String get trend => selected == null ? '—' : _svc.trendOf(selected!.id);
}