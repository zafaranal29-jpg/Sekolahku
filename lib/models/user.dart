import 'role.dart';

class AppUser {
  final String name, info;
  final Role role;
  bool active;
  String? ketuaOf; // diisi admin kalau siswa ini ketua ekskul
  final String? uid; // id dokumen Firestore users/{uid}
  String? nis; // NIS siswa (untuk akses data akademiknya sendiri)
  AppUser(this.name, this.info, this.role, this.active,
      {this.ketuaOf, this.uid, this.nis});
}