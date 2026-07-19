import '../core/api_client.dart';
import '../models/user.dart';

class AuthService {
  final _api = ApiClient.instance;

  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await _api.post('/api/mobile/login', body: {'email': email, 'password': password});
    return res as Map<String, dynamic>;
  }

  Future<void> register({
    required String companyName,
    required String adminName,
    required String email,
    required String password,
  }) async {
    await _api.post('/api/register', body: {
      'companyName': companyName,
      'adminName': adminName,
      'email': email,
      'password': password,
    });
  }

  Future<AppUser> me() async {
    final res = await _api.get('/api/mobile/me');
    return AppUser.fromJson((res as Map<String, dynamic>)['user']);
  }
}
