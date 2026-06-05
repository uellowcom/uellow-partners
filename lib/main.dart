// =============================================================================
// Uellow Partners — standalone affiliate companion app (v1.0.0).
// Sign in with the SAME Uellow customer account; the home is the partner
// dashboard (board / products / orders / wallet).
// =============================================================================
import 'dart:async';

import 'package:flutter/material.dart';

import 'api.dart';
import 'fcm_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

// Brand palette
const kDark = Color(0xFF412402);
const kGold = Color(0xFFF5C320);
const kGoldLight = Color(0xFFFFD75E);
const kBg = Color(0xFFF7F4EC);
const kGreen = Color(0xFF1F8A40);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PartnersApi.instance.init();
  unawaited(FcmService.instance.init());
  runApp(const PartnersApp());
}

class PartnersApp extends StatefulWidget {
  const PartnersApp({super.key});
  static _PartnersAppState? of(BuildContext c) =>
      c.findAncestorStateOfType<_PartnersAppState>();
  @override
  State<PartnersApp> createState() => _PartnersAppState();
}

class _PartnersAppState extends State<PartnersApp> {
  void rebuild() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final ar = PartnersApi.instance.lang == 'ar';
    return MaterialApp(
      title: 'Uellow Partners',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Tajawal',
        scaffoldBackgroundColor: kBg,
        colorScheme: ColorScheme.fromSeed(
            seedColor: kGold, primary: kDark, secondary: kGold),
        appBarTheme: const AppBarTheme(
          backgroundColor: kDark, foregroundColor: kGoldLight,
          elevation: 0, centerTitle: false,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: kGold, foregroundColor: kDark,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(
                fontFamily: 'Tajawal', fontWeight: FontWeight.w900),
          ),
        ),
      ),
      builder: (c, child) => Directionality(
        textDirection: ar ? TextDirection.rtl : TextDirection.ltr,
        child: child ?? const SizedBox.shrink(),
      ),
      home: PartnersApi.instance.signedIn
          ? const HomeScreen() : const LoginScreen(),
    );
  }
}
