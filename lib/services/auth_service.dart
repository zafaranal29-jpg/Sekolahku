import 'package:sekolahku/core/theme.dart';
import 'package:sekolahku/models/role.dart';
import 'package:sekolahku/models/user.dart';
import 'package:sekolahku/services/firebase_service.dart';
import 'package:sekolahku/services/notif_service.dart';

/// Controller autentikasi aplikasi. Menghubungkan UI (AuthScreen) ke
/// FirebaseService untuk autentikasi riil via Firebase Auth + Firestore.
class AuthService {
  static final AuthService i = AuthService._();
  AuthService._();

  /// Petakan label role dari form Daftar ke enum [Role].
  static Role roleFromLabel(String roleStr) {
    return switch (roleStr) {
      'Guru' => Role.guru,
      'Ortu' => Role.ortu,
      _ => Role.siswa,
    };
  }

  /// Daftar akun baru. Disimpan ke Firebase Auth + Firestore dengan
  /// `active: false` (menunggu aktivasi admin).
  Future<AppUser> register({
    required String name,
    required String roleStr,
    required String email,
    required String password,
    String? studentNis,
  }) async {
    final user = await FirebaseService.i.register(
      name: name,
      email: email,
      password: password,
      role: roleFromLabel(roleStr),
      studentNis: studentNis,
    );
    // Beri tahu admin (dalam sesi berjalan) bahwa ada pendaftaran baru.
    NotifService.i.notify('👥', 'Pendaftaran akun baru',
        '${user.name} (${roleLabel(user.role)}) menunggu aktivasi',
        bg: kYellowBg, roles: {Role.admin});
    return user;
  }

  /// Login: verifikasi kredensial ke Firebase Auth, baca role dari
  /// Firestore (users/{uid}/role), dan tolak akun yang belum aktif.
  Future<AppUser> login({required String email, required String password}) {
    return FirebaseService.i.login(email: email, password: password);
  }

  Future<void> logout() => FirebaseService.i.logout();
}