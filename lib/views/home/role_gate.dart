import 'package:flutter/material.dart';

import 'package:sekolahku/models/role.dart';
import 'package:sekolahku/models/session.dart';
import 'package:sekolahku/views/admin/admin_shell.dart';
import 'package:sekolahku/views/home/ortu_shell.dart';
import 'package:sekolahku/views/home/shell.dart';
import 'package:sekolahku/views/koperasi/koperasi_views.dart' show KoperasiShell;

/// Menentukan beranda berdasarkan role yang login:
/// - Siswa & Guru -> Shell (Guru memiliki menu Perkembangan Siswa, analitik & buat pengumuman)
/// - Ortu -> OrtuShell (read-only portal perkembangan siswa & nilai)
/// - Admin -> AdminShell
/// - Koperasi -> KoperasiShell
class RoleGate extends StatelessWidget {
  const RoleGate({super.key});

  /// Pemetaan murni role -> shell (dipisah agar mudah diuji tanpa render).
  static Widget shellFor(Role role) => switch (role) {
        Role.siswa || Role.guru => const Shell(),
        Role.ortu => const OrtuShell(),
        Role.admin => const AdminShell(),
        Role.koperasi => const KoperasiShell(),
      };

  @override
  Widget build(BuildContext context) => shellFor(Session.role);
}