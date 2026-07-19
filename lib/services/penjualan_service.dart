import '../core/api_client.dart';
import '../models/transaksi.dart';

class PenjualanService {
  final _api = ApiClient.instance;

  Future<List<Penjualan>> list({String? q}) async {
    final res = await _api.get('/api/penjualan', query: q != null && q.isNotEmpty ? {'q': q} : null);
    return (res as List).map((e) => Penjualan.fromJson(e)).toList();
  }

  Future<Penjualan> detail(int id) async {
    final res = await _api.get('/api/penjualan/$id');
    return Penjualan.fromJson(res);
  }

  Future<void> create(Map<String, dynamic> data) => _api.post('/api/penjualan', body: data);

  Future<void> update(int id, Map<String, dynamic> data) => _api.put('/api/penjualan/$id', body: data);

  Future<void> cancel(int id) => _api.delete('/api/penjualan/$id');
}
