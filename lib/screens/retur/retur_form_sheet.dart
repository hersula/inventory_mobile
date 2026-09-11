import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/formatters.dart';
import '../../core/api_exception.dart';
import '../../models/retur.dart';
import '../../services/pengadaan_service.dart';
import '../../services/penjualan_service.dart';
import '../../services/retur_service.dart';
import '../../widgets/state_views.dart';

class ReturFormSheet extends StatefulWidget {
  final JenisRetur jenis;
  const ReturFormSheet({super.key, required this.jenis});

  @override
  State<ReturFormSheet> createState() => _ReturFormSheetState();
}

class _ReturFormSheetState extends State<ReturFormSheet> {
  final _service = ReturService();
  final _catatanCtrl = TextEditingController();
  DateTime _tanggal = DateTime.now();

  List<TrxRingkas> _trxList = [];
  bool _loadingTrx = true;
  String? _loadError;

  int? _referensiId;
  SumberRetur? _sumber;
  bool _loadingSumber = false;
  final Map<int, TextEditingController> _qtyCtrls = {};

  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTrxList();
  }

  @override
  void dispose() {
    _catatanCtrl.dispose();
    for (final c in _qtyCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadTrxList() async {
    try {
      if (widget.jenis == JenisRetur.pembelian) {
        final list = await PengadaanService().list();
        setState(() {
          _trxList = list.map((p) => TrxRingkas(id: p.id, nomor: p.nomor, tanggal: p.tanggal, pihak: p.supplier?.nama ?? '-')).toList();
          _loadingTrx = false;
        });
      } else {
        final list = await PenjualanService().list();
        setState(() {
          _trxList = list.map((p) => TrxRingkas(id: p.id, nomor: p.nomor, tanggal: p.tanggal, pihak: p.pelanggan?.nama ?? 'Umum')).toList();
          _loadingTrx = false;
        });
      }
    } catch (e) {
      setState(() {
        _loadError = e is ApiException ? e.message : 'Gagal memuat daftar transaksi';
        _loadingTrx = false;
      });
    }
  }

  Future<void> _pilihTransaksi(int? id) async {
    setState(() {
      _referensiId = id;
      _sumber = null;
      _error = null;
      for (final c in _qtyCtrls.values) {
        c.dispose();
      }
      _qtyCtrls.clear();
    });
    if (id == null) return;
    setState(() => _loadingSumber = true);
    try {
      final sumber = await _service.sumber(widget.jenis, id);
      setState(() {
        _sumber = sumber;
        _loadingSumber = false;
      });
    } catch (e) {
      setState(() {
        _error = e is ApiException ? e.message : 'Gagal memuat detail transaksi';
        _loadingSumber = false;
      });
    }
  }

  TextEditingController _qtyCtrlFor(int barangId) => _qtyCtrls.putIfAbsent(barangId, () => TextEditingController());

  Future<void> _submit() async {
    if (_sumber == null || _referensiId == null) return;

    final items = <Map<String, dynamic>>[];
    for (final it in _sumber!.items) {
      final qty = int.tryParse(_qtyCtrls[it.barangId]?.text ?? '') ?? 0;
      if (qty > 0) items.add({'barangId': it.barangId, 'qty': qty});
    }

    if (items.isEmpty) {
      setState(() => _error = 'Isi qty minimal 1 barang yang mau diretur.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _service.create({
        'jenis': jenisReturToString(widget.jenis),
        'referensiId': _referensiId,
        'tanggal': _tanggal.toIso8601String(),
        'catatan': _catatanCtrl.text.trim().isEmpty ? null : _catatanCtrl.text.trim(),
        'items': items,
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _error = e is ApiException ? e.message : 'Gagal menyimpan retur';
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final judulJenis = widget.jenis == JenisRetur.pembelian ? 'Pembelian' : 'Penjualan';
    final labelTrx = widget.jenis == JenisRetur.pembelian ? 'Transaksi Pengadaan' : 'Transaksi Penjualan';

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(children: [
                Expanded(child: Text('Buat Retur $judulJenis', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ]),
            ),
            const Divider(height: 1),
            Expanded(
              child: _loadingTrx
                  ? const LoadingView()
                  : _loadError != null
                      ? ErrorView(message: _loadError!, onRetry: _loadTrxList)
                      : ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                          children: [
                            DropdownButtonFormField<int>(
                              value: _referensiId,
                              isExpanded: true,
                              decoration: InputDecoration(labelText: labelTrx),
                              items: _trxList
                                  .map((t) => DropdownMenuItem(
                                        value: t.id,
                                        child: Text('${t.nomor} — ${t.pihak} (${Formatters.dateShort(t.tanggal)})', overflow: TextOverflow.ellipsis),
                                      ))
                                  .toList(),
                              onChanged: _pilihTransaksi,
                            ),
                            const SizedBox(height: 12),
                            if (_loadingSumber) const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: LoadingView()),
                            if (_sumber != null) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: AppColors.slate50, borderRadius: BorderRadius.circular(10)),
                                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                  const Text('Pihak', style: TextStyle(color: AppColors.slate500, fontSize: 12.5)),
                                  Text(_sumber!.pihak, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
                                ]),
                              ),
                              const SizedBox(height: 12),
                              const Text('Barang', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                              const SizedBox(height: 6),
                              ..._sumber!.items.map((it) {
                                final ctrl = _qtyCtrlFor(it.barangId);
                                final habis = it.sisaBisaDiretur == 0;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(it.nama, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                                            Text(
                                              'Qty asal ${it.qtyAsal} · sudah diretur ${it.sudahDiretur} · sisa ${it.sisaBisaDiretur}',
                                              style: const TextStyle(fontSize: 11.5, color: AppColors.slate400),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(
                                        width: 72,
                                        child: TextField(
                                          controller: ctrl,
                                          enabled: !habis,
                                          keyboardType: TextInputType.number,
                                          textAlign: TextAlign.center,
                                          decoration: const InputDecoration(isDense: true, hintText: '0'),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                              const SizedBox(height: 12),
                              InkWell(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: _tanggal,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime.now(),
                                  );
                                  if (picked != null) setState(() => _tanggal = picked);
                                },
                                child: InputDecorator(
                                  decoration: const InputDecoration(labelText: 'Tanggal Retur'),
                                  child: Text(Formatters.dateLong(_tanggal)),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _catatanCtrl,
                                maxLines: 2,
                                decoration: const InputDecoration(labelText: 'Catatan (opsional)', hintText: 'Contoh: barang rusak'),
                              ),
                            ],
                            if (_error != null) ...[
                              const SizedBox(height: 12),
                              Text(_error!, style: const TextStyle(color: AppColors.red600, fontSize: 12.5)),
                            ],
                            const SizedBox(height: 18),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: (_sumber == null || _saving) ? null : _submit,
                                child: _saving
                                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Text('Simpan Retur'),
                              ),
                            ),
                            SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 20),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
