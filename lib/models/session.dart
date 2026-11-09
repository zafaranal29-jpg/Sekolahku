import 'role.dart';
import 'user.dart';

/// State login saat ini. `user` diisi AuthService ketika login berhasil.
class Session {
  static Role role = Role.siswa;
  static String name = 'Alex Johnson';
  static AppUser? user;

  /// Nama ekskul yang diketuai pengguna ini (hanya siswa). Diatur admin.
  static String? get ketuaOf => role == Role.siswa ? user?.ketuaOf : null;
  static bool get isKetua => ketuaOf != null;

  /// Yang boleh membuat PENGUMUMAN: admin, guru, dan siswa ketua ekskul.
  static bool get canAnnounce => role == Role.guru || role == Role.admin || isKetua;
}