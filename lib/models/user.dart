import 'role.dart';

class AppUser {
  final String name, info;
  final Role role;
  bool active;
  String? ketuaOf; // diisi admin kalau siswa ini ketua ekskul
  final String? uid; // id dokumen Firestore users/{uid}
  AppUser(this.name, this.info, this.role, this.active,
      {this.ketuaOf, this.uid});
}