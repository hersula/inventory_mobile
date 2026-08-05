import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/formatters.dart';
import '../../core/api_exception.dart';
import '../../models/barang.dart';
import '../../models/partner.dart';
import '../../models/transaksi.dart';
import '../../services/barang_service.dart';
import '../../services/partner_service.dart';
import '../../services/penjualan_service.dart';

const _kNewPelanggan = -1;
const double _kPpnRate = 0.11;

class PenjualanFormSheet extends StatefulWidget {
  final Penjualan? existing;
  const PenjualanFormSheet({super.key, this.existing});

  @override
  State<PenjualanFormSheet> createState() => _PenjualanFormSheetState();
}

class _PenjualanFormSheetState extends State<PenjualanFormSheet> {
  final _barangService = BarangService();
  final _partnerService = PartnerService();
  final _penjualanService = PenjualanService();

  List<Barang> _barangList = [];
  List<Pelanggan> _pelangganList = [];
  int? _pelangganId;
  DateTime _tanggal = DateTime.now();
  final _catatanCtrl = TextEditingController();
  final _diskonCtrl = TextEditingController(text: '0');
  bool _pakaiPpn = true;
  MetodeBayar _metodeBayar = MetodeBayar.tunai;
  final List<ItemInput> _rows = [ItemInput()];
  final Map<int, int> _originalQty = {}; // barangId -> qty asli (saat edit)

  bool _loadingRef = true;
  bool _saving = false;
  String? _error;

  bool get _editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _loadRef();
    final p = widget.existing;
    if (p != null) {
      _pelangganId = p.pelanggan?.id;
      _tanggal = p.tanggal;
      _catatanCtrl.text = p.catatan ?? '';
      _diskonCtrl.text = p.diskonPersen.toStringAsFixed(0);
      _pakaiPpn = p.ppn > 0;
      _metodeBayar = p.metodeBayar;
      _rows
        ..clear()
        ..addAll(p.detail.map((d) => ItemInput(
              barangId: d.barang.id,
              barangLabel: '${d.barang.kode} - ${d.barang.nama}',
              qty: d.qty,
              hargaSatuan: d.hargaSatuan,
            )))
        ..add(ItemInput());
      for (final d in p.detail) {
        _originalQty[d.barang.id] = (_originalQty[d.barang.id] ?? 0) + d.qty;
      }
    }
  }

  @override
  void dispose() {
    _catatanCtrl.dispose();
    _diskonCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRef() async {
    try {
      final results = await Future.wait([_barangService.list(), _partnerService.listPelanggan()]);
      setState(() {
        _barangList = results[0] as List<Barang>;
        _pelangganList = results[1] as List<Pelanggan>;
        _loadingRef = false;
      });
    } catch (_) {
      setState(() => _loadingRef = false);
    }
  }

  /// Batas stok efektif = stok saat ini + qty asli barang tsb di transaksi
  /// ini (kalau sedang edit) — supaya tidak salah tampil "melebihi stok"
  /// untuk qty yang sebenarnya masih "milik" transaksi ini sendiri.
  int? _stokEfektif(int? barangId) {
    if (barangId == null) return null;
    Barang? b;
    for (final x in _barangList) {
      if (x.id == barangId) {
        b = x;
        break;
      }
    }
    if (b == null) return null;
    return b.stok + (_originalQty[barangId] ?? 0);
  }

  Future<void> _addPelangganDialog() async {
    final namaCtrl = TextEditingController();
    final alamatCtrl = TextEditingController();
    final teleponCtrl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Pelanggan Baru'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: namaCtrl, autofocus: true, decoration: const InputDecoration(labelText: 'Nama Pelanggan')),
            const SizedBox(height: 10),
            TextField(controller: alamatCtrl, decoration: const InputDecoration(labelText: 'Alamat (opsional)')),
            const SizedBox(height: 10),
            TextField(controller: teleponCtrl, decoration: const InputDecoration(labelText: 'Telepon (opsional)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Simpan')),
        ],
      ),
    );
    if (result != true || namaCtrl.text.trim().isEmpty) return;
    try {
      final p = await _partnerService.createPelanggan({
        'nama': namaCtrl.text.trim(),
        'alamat': alamatCtrl.text.trim().isEmpty ? null : alamatCtrl.text.trim(),
        'telepon': teleponCtrl.text.trim().isEmpty ? null : teleponCtrl.text.trim(),
      });
      setState(() {
        _pelangganList = [..._pelangganList, p];
        _pelangganId = p.id;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e is ApiException ? e.message : 'Gagal menambah pelanggan');
    }
  }

  void _onBarangSelected(int idx, Barang b) {
    setState(() {
      _rows[idx].barangId = b.id;
      _rows[idx].barangLabel = '${b.kode} - ${b.nama}';
      _rows[idx].hargaSatuan = b.hargaJual;
      if (idx == _rows.length - 1) _rows.add(ItemInput());
    });
  }

  _Ringkasan get _ringkasan {
    final subtotal = _rows.fold<double>(0, (s, r) => s + r.qty * r.hargaSatuan);
    final persen = double.tryParse(_diskonCtrl.text) ?? 0;
    final diskonNominal = (subtotal * persen / 100).round().toDouble();
    final dpp = subtotal - diskonNominal;
    final ppn = _pakaiPpn ? (dpp * _kPpnRate).round().toDouble() : 0.0;
    return _Ringkasan(subtotal: subtotal, diskonNominal: diskonNominal, dpp: dpp, ppn: ppn, total: dpp + ppn);
  }

  Future<void> _submit() async {
    final validRows = _rows.where((r) => r.barangId != null && r.qty > 0).toList();
    if (validRows.isEmpty) {
      setState(() => _error = 'Tambahkan minimal 1 item barang.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });

    final data = {
      'pelangganId': _pelangganId,
      'tanggal': _tanggal.toIso8601String().split('T').first,
      'catatan': _catatanCtrl.text.trim().isEmpty ? null : _catatanCtrl.text.trim(),
      'diskonPersen': double.tryParse(_diskonCtrl.text) ?? 0,
      'pakaiPpn': _pakaiPpn,
      'metodeBayar': metodeBayarToString(_metodeBayar),
      'items': validRows.map((r) => r.toJson()).toList(),
    };

    try {
      if (_editing) {
        await _penjualanService.update(widget.existing!.id, data);
      } else {
        await _penjualanService.create(data);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _error = e is ApiException ? e.message : 'Gagal menyimpan transaksi';
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = _ringkasan;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.92,
        maxChildSize: 0.96,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                child: Row(children: [
                  Expanded(
                      child: Text(_editing ? 'Edit Transaksi Penjualan' : 'Transaksi Penjualan Baru',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ]),
              ),
              const Divider(height: 1),
              Expanded(
                child: _loadingRef
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DropdownButtonFormField<int>(
                              value: _pelangganId,
                              isExpanded: true,
                              decoration: const InputDecoration(labelText: 'Pelanggan'),
                              items: [
                                const DropdownMenuItem(value: null, child: Text('Umum / Walk-in')),
                                ..._pelangganList.map((p) => DropdownMenuItem(value: p.id, child: Text(p.nama, overflow: TextOverflow.ellipsis))),
                                const DropdownMenuItem(value: _kNewPelanggan, child: Text('+ Tambah Pelanggan Baru...')),
                              ],
                              onChanged: (v) => v == _kNewPelanggan ? _addPelangganDialog() : setState(() => _pelangganId = v),
                            ),
                            const SizedBox(height: 14),
                            InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _tanggal,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null) setState(() => _tanggal = picked);
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(labelText: 'Tanggal'),
                                child: Text(Formatters.dateLong(_tanggal)),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Row(children: [
                              Text('Daftar Barang', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.slate700)),
                              const SizedBox(width: 6),
                              Text('(${_rows.where((r) => r.barangId != null).length} dipilih)',
                                  style: const TextStyle(fontSize: 12, color: AppColors.slate400)),
                            ]),
                            const SizedBox(height: 10),
                            ..._rows.asMap().entries.map((entry) {
                              final stok = _stokEfektif(entry.value.barangId);
                              final over = stok != null && entry.value.qty > stok;
                              return _ItemRow(
                                item: entry.value,
                                overStock: over,
                                stokTersedia: stok,
                                onPickBarang: () => _showBarangPicker(entry.key),
                                onQtyChanged: (v) => setState(() => entry.value.qty = v),
                                onHargaChanged: (v) => setState(() => entry.value.hargaSatuan = v),
                                onRemove: _rows.length > 1 ? () => setState(() => _rows.removeAt(entry.key)) : null,
                              );
                            }),
                            TextButton.icon(
                              onPressed: () => setState(() => _rows.add(ItemInput())),
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Tambah baris'),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _catatanCtrl,
                              maxLines: 2,
                              decoration: const InputDecoration(labelText: 'Catatan (opsional)'),
                            ),
                            const SizedBox(height: 14),
                            DropdownButtonFormField<MetodeBayar>(
                              value: _metodeBayar,
                              decoration: const InputDecoration(labelText: 'Metode Pembayaran'),
                              items: MetodeBayar.values.map((m) => DropdownMenuItem(value: m, child: Text(metodeBayarLabel(m)))).toList(),
                              onChanged: (v) => setState(() => _metodeBayar = v ?? MetodeBayar.tunai),
                            ),
                            if (_metodeBayar == MetodeBayar.kredit || _metodeBayar == MetodeBayar.tempo)
                              const Padding(
                                padding: EdgeInsets.only(top: 6),
                                child: Text(
                                  'Transaksi ini akan tercatat sebagai piutang dari pelanggan — bisa ditagih lewat menu Akuntansi > Hutang & Piutang.',
                                  style: TextStyle(fontSize: 11.5, color: AppColors.amber500),
                                ),
                              ),
                            const SizedBox(height: 14),
                            Row(children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _diskonCtrl,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(labelText: 'Diskon (%)'),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: CheckboxListTile(
                                  value: _pakaiPpn,
                                  onChanged: (v) => setState(() => _pakaiPpn = v ?? true),
                                  title: const Text('PPN 11%', style: TextStyle(fontSize: 13)),
                                  contentPadding: EdgeInsets.zero,
                                  controlAffinity: ListTileControlAffinity.leading,
                                ),
                              ),
                            ]),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(color: AppColors.slate50, borderRadius: BorderRadius.circular(12)),
                              child: Column(children: [
                                _RingkasanRow('Subtotal', Formatters.rupiah(r.subtotal)),
                                if (r.diskonNominal > 0) _RingkasanRow('Diskon', '- ${Formatters.rupiah(r.diskonNominal)}'),
                                if (r.ppn > 0) _RingkasanRow('PPN 11%', '+ ${Formatters.rupiah(r.ppn)}'),
                                const Divider(),
                                _RingkasanRow('Total', Formatters.rupiah(r.total), bold: true),
                              ]),
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 14),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: AppColors.red500.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                                child: Text(_error!, style: const TextStyle(color: AppColors.red600, fontSize: 12.5)),
                              ),
                            ],
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _saving ? null : _submit,
                                child: _saving
                                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : Text(_editing ? 'Simpan Perubahan' : 'Simpan Transaksi'),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showBarangPicker(int idx) async {
    final selected = await showModalBottomSheet<Barang>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _BarangPickerSheet(barangList: _barangList),
    );
    if (selected != null) _onBarangSelected(idx, selected);
  }
}

class _Ringkasan {
  final double subtotal, diskonNominal, dpp, ppn, total;
  _Ringkasan({required this.subtotal, required this.diskonNominal, required this.dpp, required this.ppn, required this.total});
}

class _RingkasanRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  const _RingkasanRow(this.label, this.value, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: bold ? 14 : 12.5,
      fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
      color: bold ? AppColors.slate800 : AppColors.slate500,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: style), Text(value, style: style)]),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final ItemInput item;
  final bool overStock;
  final int? stokTersedia;
  final VoidCallback onPickBarang;
  final ValueChanged<int> onQtyChanged;
  final ValueChanged<double> onHargaChanged;
  final VoidCallback? onRemove;

  const _ItemRow({
    required this.item,
    required this.overStock,
    required this.stokTersedia,
    required this.onPickBarang,
    required this.onQtyChanged,
    required this.onHargaChanged,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: overStock ? AppColors.red500 : AppColors.slate200),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: InkWell(
                onTap: onPickBarang,
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Barang', isDense: true),
                  child: Text(item.barangLabel.isEmpty ? 'Pilih barang...' : item.barangLabel,
                      overflow: TextOverflow.ellipsis, style: TextStyle(color: item.barangLabel.isEmpty ? AppColors.slate400 : AppColors.slate800)),
                ),
              ),
            ),
            if (onRemove != null) IconButton(icon: const Icon(Icons.close, size: 18), onPressed: onRemove, color: AppColors.slate400),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: TextFormField(
                key: ValueKey('qty-${item.barangId}'),
                initialValue: item.qty.toString(),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Qty', isDense: true),
                onChanged: (v) => onQtyChanged(int.tryParse(v) ?? 0),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: TextFormField(
                key: ValueKey('harga-${item.barangId}'),
                initialValue: item.hargaSatuan.toStringAsFixed(0),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Harga Satuan', isDense: true),
                onChanged: (v) => onHargaChanged(double.tryParse(v) ?? 0),
              ),
            ),
          ]),
          if (overStock) ...[
            const SizedBox(height: 4),
            Text('Qty melebihi stok tersedia ($stokTersedia).', style: const TextStyle(fontSize: 11, color: AppColors.red500)),
          ],
        ],
      ),
    );
  }
}

class _BarangPickerSheet extends StatefulWidget {
  final List<Barang> barangList;
  const _BarangPickerSheet({required this.barangList});

  @override
  State<_BarangPickerSheet> createState() => _BarangPickerSheetState();
}

class _BarangPickerSheetState extends State<_BarangPickerSheet> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.barangList
        .where((b) => b.nama.toLowerCase().contains(_q.toLowerCase()) || b.kode.toLowerCase().contains(_q.toLowerCase()))
        .toList();
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Cari barang...', prefixIcon: Icon(Icons.search)),
              onChanged: (v) => setState(() => _q = v),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: filtered.length,
                itemBuilder: (context, i) {
                  final b = filtered[i];
                  return ListTile(
                    title: Text(b.nama),
                    subtitle: Text('${b.kode} · Stok: ${b.stok}'),
                    onTap: () => Navigator.pop(context, b),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
