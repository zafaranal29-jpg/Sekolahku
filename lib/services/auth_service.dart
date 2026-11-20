import 'package:sekolahku/models/role.dart';
import 'package:sekolahku/models/user.dart';
import 'package:sekolahku/services/firebase_service.dart';

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
  }) {
    // Admin melihat akun nonaktif (menunggu aktivasi) langsung di tab
    // Pengguna + angka dashboard. Tidak perlu notifikasi browser: aturan
    // `notifications` hanya mengizinkan user AKTIF menulis, sedangkan
    // pendaftar baru masih nonaktif (jadi notif di sini selalu gagal).
    return FirebaseService.i.register(
      name: name,
      email: email,
      password: password,
      role: roleFromLabel(roleStr),
      studentNis: studentNis,
    );
  }

  /// Login: verifikasi kredensial ke Firebase Auth, baca role dari
  /// Firestore (users/{uid}/role), dan tolak akun yang belum aktif.
  Future<AppUser> login({required String email, required String password}) {
    return FirebaseService.i.login(email: email, password: password);
  }

  Future<void> logout() => FirebaseService.i.logout();
}