import '../core/api_client.dart';
import '../models/transaksi.dart';

class PengadaanService {
  final _api = ApiClient.instance;

  Future<List<Pengadaan>> list({String? q}) async {
    final res = await _api.get('/api/pengadaan', query: q != null && q.isNotEmpty ? {'q': q} : null);
    return (res as List).map((e) => Pengadaan.fromJson(e)).toList();
  }

  Future<Pengadaan> detail(int id) async {
    final res = await _api.get('/api/pengadaan/$id');
    return Pengadaan.fromJson(res);
  }

  Future<void> create(Map<String, dynamic> data) => _api.post('/api/pengadaan', body: data);

  Future<void> update(int id, Map<String, dynamic> data) => _api.put('/api/pengadaan/$id', body: data);

  Future<void> cancel(int id) => _api.delete('/api/pengadaan/$id');
}
