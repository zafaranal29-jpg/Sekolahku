import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const kPrimary = Color(0xFF7C6AE8);
const kBg = Color(0xFFF6F5FB);
const kInk = Color(0xFF1E1B3A);
const kMuted = Color(0xFF8E8AA8);
const kSoft = Color(0xFFEDE9FC);
const kGreen = Color(0xFF1E9E5A);
const kAmber = Color(0xFFB7791F);
const kRed = Color(0xFFE23D5C);
const kYellowBg = Color(0xFFFFEFD5);
const kGreenBg = Color(0xFFE1F5E9);
const kRedBg = Color(0xFFFDE7EA);
const kBlueBg = Color(0xFFE1EEFF);

ThemeData buildTheme() => ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: kBg,
      colorScheme: ColorScheme.fromSeed(seedColor: kPrimary),
      textTheme:
          GoogleFonts.poppinsTextTheme().apply(bodyColor: kInk, displayColor: kInk),
    );

String rp(int v) =>
    'Rp ${v.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}';

Future<T?> go<T>(BuildContext c, Widget w) =>
    Navigator.push<T>(c, MaterialPageRoute(builder: (_) => w));

void toast(BuildContext c, String m) => ScaffoldMessenger.of(c)
    .showSnackBar(SnackBar(content: Text(m), behavior: SnackBarBehavior.floating));

const gradient = LinearGradient(
    colors: [Color(0xFF9183F3), Color(0xFF6B58DB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight);