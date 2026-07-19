import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/api_exception.dart';
import '../../models/barang.dart';
import '../../services/barang_service.dart';

const String _kNewKategori = '__new__';

class BarangFormSheet extends StatefulWidget {
  final Barang? existing;
  final List<Kategori> kategoris;
  final ValueChanged<Kategori> onKategoriAdded;

  const BarangFormSheet({super.key, this.existing, required this.kategoris, required this.onKategoriAdded});

  @override
  State<BarangFormSheet> createState() => _BarangFormSheetState();
}

class _BarangFormSheetState extends State<BarangFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _service = BarangService();

  late TextEditingController _kodeCtrl;
  late TextEditingController _namaCtrl;
  late TextEditingController _satuanCtrl;
  late TextEditingController _hargaBeliCtrl;
  late TextEditingController _hargaJualCtrl;
  late TextEditingController _stokCtrl;
  late TextEditingController _stokMinCtrl;
  late TextEditingController _deskripsiCtrl;
  int? _kategoriId;
  bool _saving = false;
  String? _error;
  late List<Kategori> _kategoris;

  bool get _editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final b = widget.existing;
    _kategoris = widget.kategoris;
    _kodeCtrl = TextEditingController(text: b?.kode ?? '');
    _namaCtrl = TextEditingController(text: b?.nama ?? '');
    _satuanCtrl = TextEditingController(text: b?.satuan ?? 'pcs');
    _hargaBeliCtrl = TextEditingController(text: b != null ? b.hargaBeli.toStringAsFixed(0) : '');
    _hargaJualCtrl = TextEditingController(text: b != null ? b.hargaJual.toStringAsFixed(0) : '');
    _stokCtrl = TextEditingController(text: b != null ? b.stok.toString() : '0');
    _stokMinCtrl = TextEditingController(text: b != null ? b.stokMinimum.toString() : '5');
    _deskripsiCtrl = TextEditingController(text: b?.deskripsi ?? '');
    _kategoriId = b?.kategoriId;
  }

  @override
  void dispose() {
    _kodeCtrl.dispose();
    _namaCtrl.dispose();
    _satuanCtrl.dispose();
    _hargaBeliCtrl.dispose();
    _hargaJualCtrl.dispose();
    _stokCtrl.dispose();
    _stokMinCtrl.dispose();
    _deskripsiCtrl.dispose();
    super.dispose();
  }

  Future<void> _addKategoriDialog() async {
    final ctrl = TextEditingController();
    final nama = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Kategori Baru'),
        content: TextField(controller: ctrl, autofocus: true, decoration: const InputDecoration(labelText: 'Nama Kategori')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('Simpan')),
        ],
      ),
    );
    if (nama == null || nama.isEmpty) return;
    try {
      final k = await _service.createKategori(nama);
      setState(() {
        _kategoris = [..._kategoris, k];
        _kategoriId = k.id;
      });
      widget.onKategoriAdded(k);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e is ApiException ? e.message : 'Gagal menambah kategori');
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });

    final data = {
      'kode': _kodeCtrl.text.trim(),
      'nama': _namaCtrl.text.trim(),
      'kategoriId': _kategoriId,
      'satuan': _satuanCtrl.text.trim(),
      'hargaBeli': double.tryParse(_hargaBeliCtrl.text) ?? 0,
      'hargaJual': double.tryParse(_hargaJualCtrl.text) ?? 0,
      'stok': int.tryParse(_stokCtrl.text) ?? 0,
      'stokMinimum': int.tryParse(_stokMinCtrl.text) ?? 0,
      'deskripsi': _deskripsiCtrl.text.trim().isEmpty ? null : _deskripsiCtrl.text.trim(),
    };

    try {
      if (_editing) {
        await _service.update(widget.existing!.id, data);
      } else {
        await _service.create(data);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _error = e is ApiException ? e.message : 'Gagal menyimpan barang';
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(_editing ? 'Edit Barang' : 'Tambah Barang',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Expanded(
                            child: TextFormField(
                              controller: _kodeCtrl,
                              decoration: const InputDecoration(labelText: 'Kode Barang'),
                              validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<int?>(
                              value: _kategoriId,
                              isExpanded: true,
                              decoration: const InputDecoration(labelText: 'Kategori'),
                              items: [
                                const DropdownMenuItem(value: null, child: Text('Tanpa kategori')),
                                ..._kategoris.map((k) => DropdownMenuItem(value: k.id, child: Text(k.nama, overflow: TextOverflow.ellipsis))),
                                const DropdownMenuItem(value: -1, child: Text('+ Tambah Kategori Baru...')),
                              ],
                              onChanged: (v) {
                                if (v == -1) {
                                  _addKategoriDialog();
                                } else {
                                  setState(() => _kategoriId = v);
                                }
                              },
                            ),
                          ),
                        ]),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _namaCtrl,
                          decoration: const InputDecoration(labelText: 'Nama Barang'),
                          validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                        ),
                        const SizedBox(height: 14),
                        Row(children: [
                          Expanded(
                            child: TextFormField(controller: _satuanCtrl, decoration: const InputDecoration(labelText: 'Satuan')),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _stokCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Stok Awal'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _stokMinCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Stok Min.'),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 14),
                        Row(children: [
                          Expanded(
                            child: TextFormField(
                              controller: _hargaBeliCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(labelText: 'Harga Beli'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _hargaJualCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(labelText: 'Harga Jual'),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _deskripsiCtrl,
                          maxLines: 2,
                          decoration: const InputDecoration(labelText: 'Deskripsi (opsional)'),
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
                                : const Text('Simpan'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
