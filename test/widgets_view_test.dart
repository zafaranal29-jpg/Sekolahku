import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sekolahku/models/role.dart';
import 'package:sekolahku/models/session.dart';
import 'package:sekolahku/views/akademik/perkembangan_screen.dart';
import 'package:sekolahku/views/admin/admin_shell.dart';
import 'package:sekolahku/views/auth/auth_screen.dart';
import 'package:sekolahku/views/home/ortu_shell.dart';
import 'package:sekolahku/views/home/role_gate.dart';
import 'package:sekolahku/views/home/shell.dart';
import 'package:sekolahku/views/koperasi/koperasi_views.dart' show KoperasiShell;

void main() {
  testWidgets(
      'Login form only asks Email & Password; role selector appears on Daftar',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const MaterialApp(home: AuthScreen()));
    await tester.pump();

    // Halaman Masuk: tidak ada pilihan role manual, hanya Email + Password.
    expect(find.text('Masuk sebagai:'), findsNothing);
    expect(find.text('Daftar sebagai:'), findsNothing);
    expect(find.text('Siswa'), findsNothing);
    expect(find.byType(TextField), findsNWidgets(2)); // Email + Password

    // Pindah ke Daftar: pilihan role muncul (tanpa Admin & Koperasi).
    await tester.tap(find.text('Daftar'));
    await tester.pump();

    expect(find.text('Daftar sebagai:'), findsOneWidget);
    expect(find.text('Siswa'), findsOneWidget);
    expect(find.text('Orang Tua / Wali'), findsOneWidget);
    expect(find.text('Guru'), findsOneWidget);
    expect(find.text('Admin'), findsNothing);
    expect(find.text('Koperasi'), findsNothing);
    expect(find.byType(TextField), findsNWidgets(4)); // Nama + NIS + Email + Password
  });

  test('RoleGate routes each role to the right shell', () {
    expect(RoleGate.shellFor(Role.siswa), isA<Shell>());
    expect(RoleGate.shellFor(Role.guru), isA<Shell>());
    expect(RoleGate.shellFor(Role.ortu), isA<OrtuShell>());
    expect(RoleGate.shellFor(Role.admin), isA<AdminShell>());
    expect(RoleGate.shellFor(Role.koperasi), isA<KoperasiShell>());
  });

  testWidgets('PerkembanganScreen renders student grade history and averages',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    Session.role = Role.ortu;
    Session.name = 'Pak Hendra Johnson';

    await tester.pumpWidget(const MaterialApp(home: PerkembanganScreen()));
    await tester.pump();

    expect(find.text('Perkembangan Siswa'), findsOneWidget);
    expect(find.text('Alex Johnson'), findsWidgets);
    expect(find.text('Rata-rata'), findsOneWidget);
    expect(find.text('Riwayat Nilai'), findsOneWidget);
    expect(find.text('Matematika'), findsWidgets);
  });

  testWidgets('OrtuShell renders read-only parent dashboard', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    Session.role = Role.ortu;
    Session.name = 'Pak Hendra Johnson';

    await tester.pumpWidget(const MaterialApp(home: OrtuShell()));
    await tester.pump();

    expect(find.textContaining('Portal Orang Tua'), findsOneWidget);
    expect(find.text('Read-only'), findsWidgets);
    expect(find.text('Alex Johnson'), findsWidgets);
    expect(find.text('Perkembangan Siswa'), findsWidgets);
  });
}