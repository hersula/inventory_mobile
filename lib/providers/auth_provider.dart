import 'package:flutter/foundation.dart';
import '../core/storage.dart';
import '../core/api_exception.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final _authService = AuthService();

  AuthStatus status = AuthStatus.unknown;
  AppUser? currentUser;
  String? lastError;

  /// Dipanggil sekali saat aplikasi dibuka: cek apakah ada token tersimpan
  /// dan masih valid (lewat GET /api/mobile/me), supaya user tidak perlu
  /// login ulang setiap buka aplikasi.
  Future<void> checkSession() async {
    final token = await TokenStorage.getToken();
    if (token == null) {
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }
    try {
      currentUser = await _authService.me();
      status = AuthStatus.authenticated;
    } catch (_) {
      await TokenStorage.clearToken();
      status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    lastError = null;
    try {
      final result = await _authService.login(email, password);
      await TokenStorage.saveToken(result['token'] as String);
      currentUser = AppUser.fromJson({
        ...result['user'] as Map<String, dynamic>,
        'companyName': (result['user'] as Map<String, dynamic>)['companyName'],
      });
      status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      lastError = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      lastError = 'Tidak bisa terhubung ke server. Periksa koneksi internet Anda.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String companyName,
    required String adminName,
    required String email,
    required String password,
  }) async {
    lastError = null;
    try {
      await _authService.register(companyName: companyName, adminName: adminName, email: email, password: password);
      // Langsung login otomatis setelah daftar berhasil.
      return await login(email, password);
    } on ApiException catch (e) {
      lastError = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      lastError = 'Tidak bisa terhubung ke server. Periksa koneksi internet Anda.';
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await TokenStorage.clearToken();
    currentUser = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
