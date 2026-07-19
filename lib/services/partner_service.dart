import '../core/api_client.dart';
import '../models/partner.dart';

class PartnerService {
  final _api = ApiClient.instance;

  Future<List<Supplier>> listSupplier() async {
    final res = await _api.get('/api/supplier');
    return (res as List).map((e) => Supplier.fromJson(e)).toList();
  }

  Future<Supplier> createSupplier(Map<String, dynamic> data) async {
    final res = await _api.post('/api/supplier', body: data);
    return Supplier.fromJson(res);
  }

  Future<List<Pelanggan>> listPelanggan() async {
    final res = await _api.get('/api/pelanggan');
    return (res as List).map((e) => Pelanggan.fromJson(e)).toList();
  }

  Future<Pelanggan> createPelanggan(Map<String, dynamic> data) async {
    final res = await _api.post('/api/pelanggan', body: data);
    return Pelanggan.fromJson(res);
  }
}
