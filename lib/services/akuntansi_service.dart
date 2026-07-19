import '../core/api_client.dart';
import '../models/akuntansi.dart';

class AkuntansiService {
  final _api = ApiClient.instance;

  // --- Chart of Akun ---
  Future<List<Akun>> listAkun({String? q}) async {
    final res = await _api.get('/api/akun', query: q != null && q.isNotEmpty ? {'q': q} : null);
    return (res as List).map((e) => Akun.fromJson(e)).toList();
  }

  Future<void> createAkun(Map<String, dynamic> data) => _api.post('/api/akun', body: data);
  Future<void> updateAkun(int id, Map<String, dynamic> data) => _api.put('/api/akun/$id', body: data);
  Future<void> deleteAkun(int id) => _api.delete('/api/akun/$id');

  // --- Jurnal Umum ---
  Future<List<JurnalEntry>> listJurnal({String? q, String? start, String? end}) async {
    final query = <String, dynamic>{};
    if (q != null && q.isNotEmpty) query['q'] = q;
    if (start != null) query['start'] = start;
    if (end != null) query['end'] = end;
    final res = await _api.get('/api/jurnal', query: query.isEmpty ? null : query);
    return (res as List).map((e) => JurnalEntry.fromJson(e)).toList();
  }

  Future<void> createJurnal(Map<String, dynamic> data) => _api.post('/api/jurnal', body: data);
  Future<void> deleteJurnal(int id) => _api.delete('/api/jurnal/$id');

  // --- Pembayaran Hutang / Piutang ---
  Future<List<OutstandingItem>> outstanding(String tipe) async {
    final res = await _api.get('/api/pembayaran/outstanding', query: {'tipe': tipe});
    return (res as List).map((e) => OutstandingItem.fromJson(e)).toList();
  }

  Future<List<RiwayatPembayaran>> riwayatPembayaran(String tipe) async {
    final res = await _api.get('/api/pembayaran', query: {'tipe': tipe});
    return (res as List).map((e) => RiwayatPembayaran.fromJson(e)).toList();
  }

  Future<void> bayar(Map<String, dynamic> data) => _api.post('/api/pembayaran', body: data);
  Future<void> batalkanPembayaran(int id) => _api.delete('/api/pembayaran/$id');

  // --- Laporan ---
  Future<Map<String, dynamic>> neracaSaldo() async => (await _api.get('/api/laporan/neraca-saldo')) as Map<String, dynamic>;

  Future<Map<String, dynamic>> labaRugi({String? start, String? end}) async {
    final query = <String, dynamic>{};
    if (start != null) query['start'] = start;
    if (end != null) query['end'] = end;
    return (await _api.get('/api/laporan/laba-rugi', query: query.isEmpty ? null : query)) as Map<String, dynamic>;
  }
}
