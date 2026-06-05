// Premium sign-in / register for partners — same Uellow customer account.
import 'dart:async';

import 'package:flutter/material.dart';

import '../api.dart';
import '../fcm_service.dart';
import '../main.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  bool _registerMode = false;
  bool _busy = false;
  bool _hide = true;

  Future<void> _go() async {
    final ar = PartnersApi.instance.lang == 'ar';
    final email = _email.text.trim();
    final pass = _pass.text;
    if (email.isEmpty || pass.isEmpty ||
        (_registerMode && _name.text.trim().isEmpty)) {
      _snack(ar ? 'أكمل البيانات المطلوبة' : 'Fill the required fields');
      return;
    }
    setState(() => _busy = true);
    try {
      if (_registerMode) {
        await PartnersApi.instance.register(
            name: _name.text.trim(), email: email, password: pass,
            phone: _phone.text.trim());
      } else {
        await PartnersApi.instance.login(email, pass);
      unawaited(FcmService.instance.register());
      }
      if (!mounted) return;
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const HomeScreen()));
    } on ApiException catch (e) {
      _snack(e.message);
    } catch (_) {
      _snack(ar ? 'تعذّر الاتصال — حاول مرة أخرى'
                : 'Connection failed — try again');
    }
    if (mounted) setState(() => _busy = false);
  }

  void _snack(String m) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    final ar = PartnersApi.instance.lang == 'ar';
    return Scaffold(
      backgroundColor: kDark,
      body: SafeArea(child: Center(child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          // language toggle
          Align(
            alignment: AlignmentDirectional.topEnd,
            child: TextButton(
              onPressed: () async {
                await PartnersApi.instance.setLang(ar ? 'en' : 'ar');
                PartnersApp.of(context)?.rebuild();
              },
              child: Text(ar ? 'English' : 'العربية',
                  style: const TextStyle(color: kGoldLight,
                      fontWeight: FontWeight.w800)),
            ),
          ),
          Image.asset('assets/images/logo.png', width: 88,
              errorBuilder: (_, __, ___) => const Text('🟡',
                  style: TextStyle(fontSize: 60))),
          const SizedBox(height: 10),
          Text(ar ? 'شركاء يلو' : 'Uellow Partners',
              style: const TextStyle(color: kGoldLight, fontSize: 26,
                  fontWeight: FontWeight.w900)),
          Text(ar ? 'بِع لصالح يلو واربح عمولة على كل طلب ناجح'
                  : 'Sell for Uellow & earn on every delivered order',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white60, fontSize: 12.5)),
          const SizedBox(height: 26),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(children: [
              if (_registerMode) ...[
                _field(_name, ar ? 'الاسم الكامل' : 'Full name'),
                _field(_phone, ar ? 'رقم الهاتف' : 'Phone',
                    keyboard: TextInputType.phone),
              ],
              _field(_email, ar ? 'البريد الإلكتروني' : 'Email',
                  keyboard: TextInputType.emailAddress),
              TextField(
                controller: _pass, obscureText: _hide,
                decoration: InputDecoration(
                  labelText: ar ? 'كلمة المرور' : 'Password',
                  isDense: true,
                  suffixIcon: IconButton(
                    icon: Icon(_hide
                        ? Icons.visibility_off : Icons.visibility,
                        size: 18),
                    onPressed: () => setState(() => _hide = !_hide),
                  ),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, child: ElevatedButton(
                onPressed: _busy ? null : _go,
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                child: _busy
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5))
                    : Text(_registerMode
                        ? (ar ? 'إنشاء حساب' : 'Create account')
                        : (ar ? 'تسجيل الدخول' : 'Sign in')),
              )),
              TextButton(
                onPressed: () =>
                    setState(() => _registerMode = !_registerMode),
                child: Text(_registerMode
                    ? (ar ? 'عندي حساب — تسجيل الدخول'
                          : 'Have an account? Sign in')
                    : (ar ? 'جديد؟ أنشئ حساباً' : 'New? Create an account'),
                    style: const TextStyle(fontWeight: FontWeight.w700,
                        fontSize: 12.5, color: kDark)),
              ),
            ]),
          ),
          const SizedBox(height: 14),
          Text(ar ? 'نفس حساب تطبيق يلو — سجّل بنفس بياناتك'
                  : 'Same account as the Uellow shopping app',
              style: const TextStyle(color: Colors.white38, fontSize: 11)),
        ]),
      ))),
    );
  }

  Widget _field(TextEditingController c, String label,
      {TextInputType? keyboard}) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          controller: c, keyboardType: keyboard,
          decoration: InputDecoration(
            labelText: label, isDense: true,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
}
