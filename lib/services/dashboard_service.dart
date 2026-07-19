import '../core/api_client.dart';
import '../models/dashboard.dart';
import '../models/user.dart';

class DashboardService {
  final _api = ApiClient.instance;

  Future<DashboardStats> stats() async {
    final res = await _api.get('/api/dashboard/stats');
    return DashboardStats.fromJson(res as Map<String, dynamic>);
  }
}

class UserService {
  final _api = ApiClient.instance;

  Future<List<ManagedUser>> list() async {
    final res = await _api.get('/api/users');
    return (res as List).map((e) => ManagedUser.fromJson(e)).toList();
  }

  Future<void> create(Map<String, dynamic> data) => _api.post('/api/users', body: data);
  Future<void> update(int id, Map<String, dynamic> data) => _api.put('/api/users/$id', body: data);
  Future<void> delete(int id) => _api.delete('/api/users/$id');
}
