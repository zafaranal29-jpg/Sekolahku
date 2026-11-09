import 'dart:async';

import 'package:flutter/material.dart' hide Page;

import 'package:sekolahku/core/theme.dart';
import 'package:sekolahku/services/auth_service.dart';
import 'package:sekolahku/widgets/widgets.dart';

/// Layar Masuk + Daftar dengan pemilihan role vertikal (Column / Card)
/// dan dukungan role Ortu (read-only).
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool login = true, hide = true;
  final id = TextEditingController(), pass = TextEditingController();
  final name = TextEditingController(), email = TextEditingController();
  String role = 'Siswa';
  bool busy = false;
  final pc = PageController(viewportFraction: .92);
  int page = 0;
  Timer? timer;

  static const prestasi = [
    ('🏆', 'Juara 1 Basket Antarsekolah', 'Tim basket putra · Okt 2026', Color(0xFFFFB84D)),
    ('🥇', 'Medali Emas Olimpiade Sains', 'Fisika tingkat provinsi', Color(0xFF5BC59A)),
    ('🎭', 'Pentas Seni Terbaik 2026', 'Ekskul Teater · Aula Utama', Color(0xFFEF7C9B)),
  ];

  static const roleDescriptions = {
    'Siswa': ('🧑‍🎓', 'Akses mading, koperasi, fasilitas, dan kegiatan'),
    'Ortu': ('👨‍👩‍👧', 'Akses read-only perkembangan & nilai siswa'),
    'Guru': ('👩‍🏫', 'Kelola pengumuman & pantau perkembangan siswa'),
    'Admin': ('🏫', 'Pusat persetujuan, moderasi, & manajemen pengguna'),
    'Koperasi': ('🍱', 'Kelola pesanan, stok, & scan QR'),
  };

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!pc.hasClients) return;
      pc.animateToPage((page + 1) % prestasi.length,
          duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    pc.dispose();
    for (final t in [id, pass, name, email]) {
      t.dispose();
    }
    super.dispose();
  }

  Future<void> submit() async {
    if (email.text.trim().isEmpty ||
        pass.text.isEmpty ||
        (!login && name.text.trim().isEmpty)) {
      toast(context, 'Lengkapi data dulu ya');
      return;
    }
    setState(() => busy = true);
    try {
      if (!login) {
        await AuthService.i.register(
          name: name.text.trim(),
          roleStr: role,
          email: email.text.trim(),
          password: pass.text,
          studentNis: id.text.trim().isEmpty ? null : id.text.trim(),
        );
        if (!mounted) return;
        toast(context, 'Pendaftaran terkirim. Akun menunggu aktivasi admin.');
        setState(() => login = true);
        return;
      }
      await AuthService.i.login(email: email.text.trim(), password: pass.text);
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      if (mounted) toast(context, _friendlyError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  /// Terjemahkan pesan error Firebase Auth menjadi teks ramah pengguna.
  String _friendlyError(Object e) {
    final m = e.toString();
    if (m.contains('belum diaktifkan')) {
      return 'Akun belum di-ACC admin. Hubungi pihak sekolah.';
    }
    if (m.contains('invalid-credential') || m.contains('wrong-password')) {
      return 'Email atau password salah.';
    }
    if (m.contains('user-not-found')) {
      return 'Email belum terdaftar.';
    }
    if (m.contains('email-already-in-use')) {
      return 'Email sudah terdaftar.';
    }
    if (m.contains('weak-password')) {
      return 'Password terlalu lemah (min. 6 karakter).';
    }
    if (m.contains('invalid-email')) {
      return 'Format email tidak valid.';
    }
    if (m.contains('network-request-failed')) {
      return 'Gagal terhubung. Periksa koneksi internet.';
    }
    return 'Terjadi kesalahan. Coba lagi.';
  }

  // Role yang boleh dipilih saat DAFTAR (Admin & Koperasi dibuat oleh admin).
  static const availableRoles = ['Siswa', 'Ortu', 'Guru'];

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
            child: ListView(padding: const EdgeInsets.symmetric(vertical: 16), children: [
          const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                Emoji('🏫', size: 52),
                SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('SekolahKu', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                  Text('Semua urusan sekolah, satu aplikasi', style: TextStyle(color: kMuted, fontSize: 12)),
                ]),
              ])),
          const SizedBox(height: 16),

          // ---- Carousel Prestasi ----
          SizedBox(
              height: 150,
              child: PageView.builder(
                  controller: pc,
                  itemCount: prestasi.length,
                  onPageChanged: (i) => setState(() => page = i),
                  itemBuilder: (_, i) {
                    final p = prestasi[i];
                    return Container(
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                            gradient: LinearGradient(
                                colors: [p.$4, p.$4.withValues(alpha: 0.7)]),
                            borderRadius: BorderRadius.circular(24)),
                        child: Row(children: [
                          Expanded(
                              child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                const Pill('🌟 Prestasi sekolah', bg: Colors.white24, fg: Colors.white),
                                const SizedBox(height: 8),
                                Text(p.$2,
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
                                Text(p.$3, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                              ])),
                          Text(p.$1, style: const TextStyle(fontSize: 56)),
                        ]));
                  })),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (var i = 0; i < prestasi.length; i++)
              AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.all(3),
                  width: i == page ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                      color: i == page ? kPrimary : kSoft, borderRadius: BorderRadius.circular(6))),
          ]),
          const SizedBox(height: 8),

          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(children: [
                Row(children: [
                  for (final s in [
                    ('1.248', 'Siswa aktif', kSoft),
                    ('85', 'Prestasi', kYellowBg),
                    ('42', 'Ekskul', kGreenBg)
                  ])
                    Expanded(
                        child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration:
                                BoxDecoration(color: s.$3, borderRadius: BorderRadius.circular(18)),
                            child: Column(children: [
                              Text(s.$1, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                              Text(s.$2, style: const TextStyle(color: kMuted, fontSize: 11)),
                            ]))),
                ]),
                const SizedBox(height: 16),

                // ---- Form Masuk / Daftar ----
                Card2(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(16)),
                          child: Row(children: [
                            for (final (i, t) in ['Masuk', 'Daftar'].indexed)
                              Expanded(
                                  child: GestureDetector(
                                      onTap: () => setState(() => login = i == 0),
                                      child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          padding: const EdgeInsets.symmetric(vertical: 10),
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                              color: (i == 0) == login ? kPrimary : Colors.transparent,
                                              borderRadius: BorderRadius.circular(12)),
                                          child: Text(t,
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  color:
                                                      (i == 0) == login ? Colors.white : kMuted))))),
                          ])),
                      const SizedBox(height: 14),

                      if (!login) Field('Nama lengkap', controller: name),

                      // ---- Form Daftar: pilihan role (Siswa / Ortu / Guru) ----
                      if (!login) ...[
                        const Text(
                          'Daftar sebagai:',
                          style: TextStyle(
                              color: kMuted, fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),

                        Column(
                          children: [
                            for (final r in availableRoles)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Material(
                                  color: role == r ? kSoft : Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(
                                      color: role == r ? kPrimary : const Color(0xFFE6E3F5),
                                      width: role == r ? 2 : 1,
                                    ),
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () => setState(() => role = r),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                      child: Row(
                                        children: [
                                          Text(roleDescriptions[r]?.$1 ?? '👤',
                                              style: const TextStyle(fontSize: 22)),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Text(
                                                      r == 'Ortu' ? 'Orang Tua / Wali' : r,
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.w700,
                                                        color: role == r ? kPrimary : kInk,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                    if (r == 'Ortu') ...[
                                                      const SizedBox(width: 8),
                                                      const Pill('Read-only', bg: Colors.white, fg: kPrimary),
                                                    ],
                                                  ],
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  roleDescriptions[r]?.$2 ?? '',
                                                  style: const TextStyle(color: kMuted, fontSize: 11),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Icon(
                                            role == r
                                                ? Icons.radio_button_checked
                                                : Icons.radio_button_off,
                                            color: role == r ? kPrimary : const Color(0xFFCBD5E1),
                                            size: 20,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        Field(
                          switch (role) {
                            'Ortu' => 'NIS Anak (opsional)',
                            'Guru' => 'NIP (opsional)',
                            _ => 'NIS (opsional)',
                          },
                          controller: id,
                        ),
                      ],

                      // ---- Form Masuk: hanya Email & Password (tanpa pilihan role) ----
                      Field('Email', controller: email),
                      Field(
                        'Password',
                        controller: pass,
                        obscure: hide,
                        suffix: IconButton(
                          icon: Icon(hide ? Icons.visibility_off : Icons.visibility, size: 20),
                          onPressed: () => setState(() => hide = !hide),
                        ),
                      ),
                      if (login)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => go(context, const ForgotScreen()),
                            child: const Text('Lupa password?'),
                          ),
                        ),
                      Btn(
                        login
                            ? (busy ? 'Memproses...' : 'Masuk')
                            : (busy ? 'Mendaftar...' : 'Buat akun'),
                        busy ? null : submit,
                      ),
                    ])),
                const SizedBox(height: 6),
              ])),
        ])),
      );
}

class ForgotScreen extends StatelessWidget {
  const ForgotScreen({super.key});
  @override
  Widget build(BuildContext c) => Page('Lupa password', [
        const SizedBox(height: 20),
        const Center(child: Text('🔐', style: TextStyle(fontSize: 80))),
        const SizedBox(height: 20),
        const Text('Atur ulang password', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const Text(
          'Masukkan NIS/NIP atau email. Kami kirim tautan atur ulang ke email yang terdaftar.',
          style: TextStyle(color: kMuted),
        ),
        const SizedBox(height: 16),
        const Field('NIS / NIP / Email'),
        Btn('Kirim tautan', () {
          toast(c, 'Tautan dikirim ke email terdaftar');
          Navigator.pop(c);
        }),
      ]);
}

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});
  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordState();
}

class _ChangePasswordState extends State<ChangePasswordScreen> {
  String p = '';
  @override
  Widget build(BuildContext c) {
    final rules = [
      ('Minimal 8 karakter', p.length >= 8),
      ('Mengandung angka', p.contains(RegExp(r'\d'))),
      ('Mengandung huruf besar', p.contains(RegExp(r'[A-Z]'))),
    ];
    return Page('Buat password baru', [
      Field('Password baru', obscure: true, onChanged: (v) => setState(() => p = v)),
      const Field('Ulangi password', obscure: true),
      Card2(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Syarat password', style: TextStyle(fontWeight: FontWeight.w700)),
        for (final r in rules)
          Text('${r.$2 ? '✅' : '⬜'} ${r.$1}', style: const TextStyle(color: kMuted)),
      ])),
      Btn(
          'Simpan & lanjut',
          rules.every((r) => r.$2)
              ? () {
                  toast(c, 'Password diperbarui');
                  Navigator.pop(c);
                }
              : null),
    ]);
  }
}