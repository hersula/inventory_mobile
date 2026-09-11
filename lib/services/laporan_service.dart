import '../core/api_client.dart';
import '../models/kartu_stok.dart';

class LaporanService {
  final _api = ApiClient.instance;

  Future<KartuStok> kartuStok(int barangId, {String? start, String? end}) async {
    final query = <String, dynamic>{'barangId': barangId};
    if (start != null && start.isNotEmpty) query['start'] = start;
    if (end != null && end.isNotEmpty) query['end'] = end;
    final res = await _api.get('/api/laporan/kartu-stok', query: query);
    return KartuStok.fromJson(res as Map<String, dynamic>);
  }
}
