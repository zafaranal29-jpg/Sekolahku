import 'dart:math';

/// Generator kode pendek untuk ID yang ditampilkan ke user (mis. `KP-3F8K2QV9`).
///
/// Dipakai menggantikan `DataStore.*Seq++` yang dulu di-reset tiap aplikasi
/// restart dan rawan bentrok saat dua klien generate bersamaan. Kode ini acak
/// (bukan berurutan), 8 karakter dari alfabet tanpa karakter ambigu
/// (0/O, 1/I), sehingga unik secara praktis tanpa counter global.
final Random _rng = Random();

const String _alphabet = '23456789ABCDEFGHJKMNPQRSTUVWXYZ';

/// `shortId('KP')` → `KP-3F8K2QV9`.
String shortId(String prefix) {
  final buf = StringBuffer();
  for (var i = 0; i < 8; i++) {
    buf.write(_alphabet[_rng.nextInt(_alphabet.length)]);
  }
  return '$prefix-$buf';
}