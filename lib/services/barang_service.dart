import '../core/api_client.dart';
import '../models/barang.dart';

class BarangService {
  final _api = ApiClient.instance;

  Future<List<Barang>> list({String? q}) async {
    final res = await _api.get('/api/barang', query: q != null && q.isNotEmpty ? {'q': q} : null);
    return (res as List).map((e) => Barang.fromJson(e)).toList();
  }

  Future<Barang> create(Map<String, dynamic> data) async {
    final res = await _api.post('/api/barang', body: data);
    return Barang.fromJson(res);
  }

  Future<Barang> update(int id, Map<String, dynamic> data) async {
    final res = await _api.put('/api/barang/$id', body: data);
    return Barang.fromJson(res);
  }

  Future<void> delete(int id) => _api.delete('/api/barang/$id');

  Future<List<Kategori>> listKategori() async {
    final res = await _api.get('/api/kategori');
    return (res as List).map((e) => Kategori.fromJson(e)).toList();
  }

  Future<Kategori> createKategori(String nama) async {
    final res = await _api.post('/api/kategori', body: {'nama': nama});
    return Kategori.fromJson(res);
  }
}
