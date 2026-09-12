import '../core/api_client.dart';
import '../models/stok_opname.dart';

class OpnameService {
  final _api = ApiClient.instance;

  Future<List<StokOpname>> list() async {
    final res = await _api.get('/api/opname');
    return (res as List).map((e) => StokOpname.fromJson(e)).toList();
  }

  Future<void> create(Map<String, dynamic> data) => _api.post('/api/opname', body: data);

  Future<void> cancel(int id) => _api.delete('/api/opname/$id');
}
