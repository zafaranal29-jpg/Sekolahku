/// Model data akademik: siswa, riwayat nilai, serta relasi ortu & guru.
class Student {
  final String id; // NIS
  final String name;
  final String kelas;
  final List<GradeRecord> grades;
  Student(this.id, this.name, this.kelas, [List<GradeRecord>? grades])
      : grades = grades ?? [];
}

class GradeRecord {
  final String mapel;
  final String jenis; // UH | UTS | UAS | Rapor
  final String semester;
  final double nilai; // 0–100
  final DateTime tanggal;
  GradeRecord(this.mapel, this.jenis, this.semester, this.nilai, this.tanggal);
}

/// Satu entitas Ortu terhubung ke satu ID Siswa (NIS).
class OrtuLink {
  final String ortuName;
  final String studentId;
  OrtuLink(this.ortuName, this.studentId);
}

/// Guru terhubung ke siswa berdasarkan kelas (wali kelas) dan/atau mapel yang diampu.
class GuruRelation {
  final String guruName;
  final String? waliKelas; // kelas yang diwalikan (opsional)
  final List<String> mapel; // mapel yang diampu
  GuruRelation(this.guruName, {this.waliKelas, this.mapel = const []});
}