import '../core/api_client.dart';
import '../models/retur.dart';

class ReturService {
  final _api = ApiClient.instance;

  Future<List<Retur>> list(JenisRetur jenis) async {
    final res = await _api.get('/api/retur', query: {'jenis': jenisReturToString(jenis)});
    return (res as List).map((e) => Retur.fromJson(e)).toList();
  }

  Future<SumberRetur> sumber(JenisRetur jenis, int referensiId) async {
    final res = await _api.get('/api/retur/sumber', query: {'jenis': jenisReturToString(jenis), 'referensiId': referensiId});
    return SumberRetur.fromJson(res as Map<String, dynamic>);
  }

  Future<void> create(Map<String, dynamic> data) => _api.post('/api/retur', body: data);

  Future<void> cancel(int id) => _api.delete('/api/retur/$id');
}
