import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'package:sekolahku/core/theme.dart';
import 'package:sekolahku/firebase_options.dart';
import 'package:sekolahku/views/auth/auth_screen.dart';
import 'package:sekolahku/views/home/role_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }
  runApp(const SekolahKuApp());
}

class SekolahKuApp extends StatelessWidget {
  const SekolahKuApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'SekolahKu',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        // Di Chrome/desktop, tampilan dibatasi selebar HP supaya mirip mockup.
        builder: (c, child) => Container(
            color: const Color(0xFFEBE8F8),
            alignment: Alignment.center,
            child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440), child: child)),
        home: const Splash(),
        routes: {
          '/auth': (_) => const AuthScreen(),
          '/home': (_) => const RoleGate(),
        },
      );
}

class Splash extends StatefulWidget {
  const Splash({super.key});
  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) Navigator.pushReplacementNamed(context, '/auth');
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Container(
            decoration: const BoxDecoration(gradient: gradient),
            width: double.infinity,
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                  width: 96,
                  height: 96,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: Colors.white, borderRadius: BorderRadius.circular(30)),
                  child: const Text('🏫', style: TextStyle(fontSize: 52))),
              const SizedBox(height: 20),
              const Text('SekolahKu',
                  style: TextStyle(
                      color: Colors.white, fontSize: 34, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              const Text('Semua urusan sekolah, satu aplikasi.',
                  style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 40),
              const Text('Memuat...', style: TextStyle(color: Colors.white54)),
            ])),
      );
}