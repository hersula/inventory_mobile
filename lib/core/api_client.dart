import 'dart:convert';
import 'package:http/http.dart' as http;
import 'constants.dart';
import 'storage.dart';
import 'api_exception.dart';

/// Client HTTP tipis di atas package `http`. Semua request otomatis
/// menyertakan header `Authorization: Bearer <token>` (kalau ada token
/// tersimpan) dan `Content-Type: application/json`. Response non-2xx
/// otomatis dilempar sebagai [ApiException] dengan pesan dari field
/// `message` yang dikirim backend (lihat pola respons error di semua route
/// Next.js: `NextResponse.json({ message: "..." }, { status: ... })`).
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final base = Uri.parse(AppConfig.apiBaseUrl);
    return Uri(
      scheme: base.scheme,
      host: base.host,
      port: base.port,
      path: path,
      queryParameters: query?.map((k, v) => MapEntry(k, v.toString())),
    );
  }

  Future<Map<String, String>> _headers() async {
    final token = await TokenStorage.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  dynamic _decode(http.Response res) {
    if (res.statusCode == 204 || res.body.isEmpty) return null;
    try {
      return jsonDecode(res.body);
    } catch (_) {
      return null;
    }
  }

  dynamic _handle(http.Response res) {
    final body = _decode(res);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return body;
    }
    final message = (body is Map && body['message'] is String) ? body['message'] as String : 'Terjadi kesalahan (${res.statusCode})';
    throw ApiException(message, statusCode: res.statusCode);
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    final res = await http.get(_uri(path, query), headers: await _headers()).timeout(const Duration(seconds: 20));
    return _handle(res);
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    final res = await http
        .post(_uri(path), headers: await _headers(), body: body != null ? jsonEncode(body) : null)
        .timeout(const Duration(seconds: 20));
    return _handle(res);
  }

  Future<dynamic> put(String path, {Map<String, dynamic>? body}) async {
    final res = await http
        .put(_uri(path), headers: await _headers(), body: body != null ? jsonEncode(body) : null)
        .timeout(const Duration(seconds: 20));
    return _handle(res);
  }

  Future<dynamic> delete(String path) async {
    final res = await http.delete(_uri(path), headers: await _headers()).timeout(const Duration(seconds: 20));
    return _handle(res);
  }
}
