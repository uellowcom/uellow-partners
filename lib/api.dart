// =============================================================================
// Slim Uellow API client for the Partners app — auth + affiliate endpoints.
// Same backend as the main app (uellow_mobile_manager + uellow_affiliate).
// =============================================================================
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiException implements Exception {
  ApiException(this.code, this.message);
  final String code;
  final String message;
  @override
  String toString() => message;
}

class PartnersApi {
  PartnersApi._();
  static final PartnersApi instance = PartnersApi._();

  static const baseUrl = String.fromEnvironment('UELLOW_API_BASE',
      defaultValue: 'https://www.uellow.com');

  String lang = 'ar';
  String? _token;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('partner_token');
    lang = prefs.getString('partner_lang') ?? 'ar';
  }

  bool get signedIn => _token != null && _token!.isNotEmpty;

  Future<void> setLang(String l) async {
    lang = l;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('partner_lang', l);
  }

  Future<void> _saveToken(String? t) async {
    _token = t;
    final prefs = await SharedPreferences.getInstance();
    if (t == null) {
      await prefs.remove('partner_token');
    } else {
      await prefs.setString('partner_token', t);
    }
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-Lang': lang,
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<Map<String, dynamic>> _req(String method, String path,
      {Map<String, dynamic>? query, Object? body}) async {
    var uri = Uri.parse('$baseUrl$path');
    if (query != null) {
      uri = uri.replace(queryParameters:
          query.map((k, v) => MapEntry(k, '$v')));
    }
    late http.Response r;
    if (method == 'GET') {
      r = await http.get(uri, headers: _headers)
          .timeout(const Duration(seconds: 25));
    } else {
      r = await http.post(uri, headers: _headers,
              body: body == null ? null : jsonEncode(body))
          .timeout(const Duration(seconds: 25));
    }
    final j = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
    if (j['success'] != true) {
      throw ApiException((j['code'] ?? 'ERROR').toString(),
          (j['error'] ?? 'Request failed').toString());
    }
    return j;
  }

  Future<Map<String, dynamic>> _get(String path,
          {Map<String, dynamic>? query}) =>
      _req('GET', path, query: query);
  Future<Map<String, dynamic>> _post(String path, {Object? body}) =>
      _req('POST', path, body: body);

  // ── auth ──
  Future<void> login(String email, String password) async {
    final res = await _post('/api/mobile/v2/auth/login', body: {
      'email': email, 'password': password,
      'device_name': 'Partners app',
    });
    await _saveToken((res['data']?['token'] ?? '').toString());
  }

  Future<void> register(
      {required String name, required String email,
       required String password, String phone = ''}) async {
    final res = await _post('/api/mobile/v2/auth/register', body: {
      'name': name, 'email': email, 'password': password,
      if (phone.isNotEmpty) 'phone': phone,
    });
    await _saveToken((res['data']?['token'] ?? '').toString());
  }

  Future<void> logout() async {
    try {
      await _post('/api/mobile/v2/auth/logout');
    } catch (_) {}
    await _saveToken(null);
  }

  // ── affiliate ──
  Future<Map<String, dynamic>> me() async =>
      ((await _get('/api/mobile/v2/affiliate/me'))['data'] as Map)
          .cast<String, dynamic>();

  Future<Map<String, dynamic>> apply() async =>
      ((await _post('/api/mobile/v2/affiliate/apply'))['data'] as Map)
          .cast<String, dynamic>();

  Future<List<Map<String, dynamic>>> products({String q = ''}) async {
    final res = await _get('/api/mobile/v2/affiliate/products',
        query: {if (q.isNotEmpty) 'q': q, 'per_page': 40});
    return List<Map<String, dynamic>>.from(
        (res['data']?['products'] as List?) ?? const []);
  }

  Future<List<Map<String, dynamic>>> orders() async {
    final res = await _get('/api/mobile/v2/affiliate/orders');
    return List<Map<String, dynamic>>.from(
        (res['data']?['orders'] as List?) ?? const []);
  }

  Future<void> submitOrder({
    required String customerName, required String customerPhone,
    String area = '', String address = '', String note = '',
    required List<Map<String, dynamic>> lines,
  }) async {
    await _post('/api/mobile/v2/affiliate/orders', body: {
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'customer_area': area,
      'customer_address': address,
      'customer_note': note,
      'lines': lines,
    });
  }

  Future<List<Map<String, dynamic>>> commissions() async {
    final res = await _get('/api/mobile/v2/affiliate/commissions');
    return List<Map<String, dynamic>>.from(
        (res['data']?['commissions'] as List?) ?? const []);
  }

  Future<List<Map<String, dynamic>>> payouts() async {
    final res = await _get('/api/mobile/v2/affiliate/payouts');
    return List<Map<String, dynamic>>.from(
        (res['data']?['payouts'] as List?) ?? const []);
  }

  Future<void> requestPayout(
      {required double amount, required String method,
       String details = ''}) async {
    await _post('/api/mobile/v2/affiliate/payouts', body: {
      'amount': amount, 'method': method, 'details': details,
    });
  }

  // v1.1.0 — affiliate 2.0 endpoints
  Future<List<Map<String, dynamic>>> sales() async {
    final res = await _get('/api/mobile/v2/affiliate/sales');
    return List<Map<String, dynamic>>.from(
        (res['data']?['sales'] as List?) ?? const []);
  }

  Future<List<Map<String, dynamic>>> campaigns() async {
    final res = await _get('/api/mobile/v2/affiliate/campaigns');
    return List<Map<String, dynamic>>.from(
        (res['data']?['campaigns'] as List?) ?? const []);
  }

  Future<List<Map<String, dynamic>>> news() async {
    final res = await _get('/api/mobile/v2/affiliate/news');
    return List<Map<String, dynamic>>.from(
        (res['data']?['news'] as List?) ?? const []);
  }

  Future<List<Map<String, dynamic>>> activity() async {
    final res = await _get('/api/mobile/v2/affiliate/activity');
    return List<Map<String, dynamic>>.from(
        (res['data']?['events'] as List?) ?? const []);
  }

  Future<Map<String, dynamic>> series() async =>
      ((await _get('/api/mobile/v2/affiliate/series'))['data'] as Map)
          .cast<String, dynamic>();

  Future<Map<String, dynamic>> leaderboard() async =>
      ((await _get('/api/mobile/v2/affiliate/leaderboard'))['data'] as Map)
          .cast<String, dynamic>();
}
