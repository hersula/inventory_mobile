import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/api_exception.dart';
import '../../models/barang.dart';
import '../../services/barang_service.dart';
import '../../services/opname_service.dart';
import '../../widgets/state_views.dart';

/// Full-screen (bukan modal bottom sheet, seperti Retur) karena daftar barang
/// bisa panjang dan butuh ruang penuh layar untuk kolom cari + input per
/// baris. Barang yang kolom "stok fisik"-nya dikosongkan tidak ikut dikirim
/// ke server (pola sama seperti Retur: baris kosong = dilewati).
class OpnameFormScreen extends StatefulWidget {
  const OpnameFormScreen({super.key});

  @override
  State<OpnameFormScreen> createState() => _OpnameFormScreenState();
}

class _OpnameFormScreenState extends State<OpnameFormScreen> {
  final _barangService = BarangService();
  final _opnameService = OpnameService();
  final _searchCtrl = TextEditingController();
  final _catatanCtrl = TextEditingController();
  final Map<int, TextEditingController> _stokFisikCtrls = {};

  List<Barang> _barangList = [];
  bool _loading = true;
  bool _saving = false;
  String? _error;
  DateTime _tanggal = DateTime.now();

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _catatanCtrl.dispose();
    for (final c in _stokFisikCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _barangService.list();
      setState(() {
        _barangList = items;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e is ApiException ? e.message : 'Gagal memuat data barang';
        _loading = false;
      });
    }
  }

  TextEditingController _ctrlFor(int barangId) => _stokFisikCtrls.putIfAbsent(barangId, () => TextEditingController());

  List<Barang> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return _barangList;
    return _barangList.where((b) => b.nama.toLowerCase().contains(q) || b.kode.toLowerCase().contains(q)).toList();
  }

  Future<void> _pickTanggal() async {
    final picked = await showDatePicker(context: context, initialDate: _tanggal, firstDate: DateTime(2020), lastDate: DateTime(2100));
    if (picked != null) setState(() => _tanggal = picked);
  }

  Future<void> _submit() async {
    final items = <Map<String, dynamic>>[];
    for (final entry in _stokFisikCtrls.entries) {
      final text = entry.value.text.trim();
      if (text.isEmpty) continue;
      final stokFisik = int.tryParse(text);
      if (stokFisik == null) continue;
      items.add({'barangId': entry.key, 'stokFisik': stokFisik});
    }

    if (items.isEmpty) {
      setState(() => _error = 'Isi stok fisik minimal 1 barang yang dihitung.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _opnameService.create({
        'tanggal': _tanggal.toIso8601String(),
        'catatan': _catatanCtrl.text.trim().isEmpty ? null : _catatanCtrl.text.trim(),
        'items': items,
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _error = e is ApiException ? e.message : 'Gagal menyimpan stock opname';
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Opname Baru'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                hintText: 'Cari kode atau nama barang...',
                prefixIcon: Icon(Icons.search, size: 20),
                isDense: true,
              ),
            ),
          ),
        ),
      ),
      body: _loading
          ? const LoadingView()
          : _error != null && _barangList.isEmpty
              ? ErrorView(message: _error!, onRetry: _load)
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _pickTanggal,
                              icon: const Icon(Icons.calendar_today_outlined, size: 16),
                              label: Text('${_tanggal.day}/${_tanggal.month}/${_tanggal.year}'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: _catatanCtrl,
                              decoration: const InputDecoration(hintText: 'Catatan (opsional)', isDense: true),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: Text(
                        'Isi "Stok Fisik" hanya untuk barang yang benar-benar dihitung. Barang yang dikosongkan tidak tersimpan/berubah stoknya.',
                        style: TextStyle(fontSize: 11.5, color: AppColors.slate400),
                      ),
                    ),
                    Expanded(
                      child: _filtered.isEmpty
                          ? const EmptyView(message: 'Barang tidak ditemukan.', icon: Icons.inventory_2_outlined)
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                              itemCount: _filtered.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (context, i) {
                                final b = _filtered[i];
                                final ctrl = _ctrlFor(b.id);
                                return _OpnameRow(barang: b, controller: ctrl, onChanged: () => setState(() {}));
                              },
                            ),
                    ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: Text(_error!, style: const TextStyle(color: AppColors.red600, fontSize: 12.5)),
                      ),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _saving ? null : _submit,
                            child: _saving
                                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('Simpan Opname'),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _OpnameRow extends StatelessWidget {
  final Barang barang;
  final TextEditingController controller;
  final VoidCallback onChanged;

  const _OpnameRow({required this.barang, required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final text = controller.text.trim();
    final selisih = text.isEmpty ? null : int.tryParse(text) != null ? int.parse(text) - barang.stok : null;
    final selisihColor = selisih == null ? AppColors.slate300 : (selisih > 0 ? AppColors.emerald600 : (selisih < 0 ? AppColors.red600 : AppColors.slate400));
    final selisihText = selisih == null ? '-' : (selisih > 0 ? '+$selisih' : '$selisih');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.slate200)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(barang.nama, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                Text('${barang.kode} · Stok sistem: ${barang.stok} ${barang.satuan}', style: const TextStyle(fontSize: 11.5, color: AppColors.slate400)),
              ],
            ),
          ),
          SizedBox(
            width: 72,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              onChanged: (_) => onChanged(),
              decoration: InputDecoration(isDense: true, hintText: '${barang.stok}'),
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(selisihText, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5, color: selisihColor)),
          ),
        ],
      ),
    );
  }
}
