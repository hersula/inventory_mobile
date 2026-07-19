import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/api_exception.dart';
import '../../core/rbac.dart';
import '../../models/akuntansi.dart';
import '../../providers/auth_provider.dart';
import '../../services/akuntansi_service.dart';
import '../../widgets/state_views.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/app_feedback.dart';

class AkunTab extends StatefulWidget {
  const AkunTab({super.key});

  @override
  State<AkunTab> createState() => _AkunTabState();
}

class _AkunTabState extends State<AkunTab> {
  final _service = AkuntansiService();
  List<Akun> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _service.listAkun();
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e is ApiException ? e.message : 'Gagal memuat akun';
        _loading = false;
      });
    }
  }

  Future<void> _openForm({Akun? existing}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AkunFormSheet(existing: existing),
    );
    if (saved == true) _load();
  }

  Future<void> _delete(Akun a) async {
    final confirmed = await AppFeedback.confirm(context, title: 'Hapus Akun', message: 'Hapus akun "${a.kode} - ${a.nama}"?', danger: true);
    if (!confirmed) return;
    try {
      await _service.deleteAkun(a.id);
      if (mounted) AppFeedback.success(context, 'Akun dihapus');
      _load();
    } catch (e) {
      if (mounted) AppFeedback.error(context, e is ApiException ? e.message : 'Gagal menghapus akun');
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthProvider>().currentUser?.role;
    final canManage = can(role, 'akuntansi.manage');

    return Scaffold(
      floatingActionButton: canManage
          ? FloatingActionButton(onPressed: () => _openForm(), backgroundColor: AppColors.brand600, child: const Icon(Icons.add))
          : null,
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const LoadingView()
            : _error != null
                ? ErrorView(message: _error!, onRetry: _load)
                : _items.isEmpty
                    ? const EmptyView(message: 'Belum ada akun.')
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final a = _items[i];
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.slate200)),
                            child: Row(children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${a.kode} · ${a.nama}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                                    const SizedBox(height: 4),
                                    Row(children: [
                                      StatusBadge(tipeAkunLabel(a.tipe), tone: BadgeTone.brand),
                                      const SizedBox(width: 6),
                                      Text(a.saldoNormal == 'DEBIT' ? 'Debit' : 'Kredit', style: const TextStyle(fontSize: 11.5, color: AppColors.slate400)),
                                      if (!a.isActive) ...[const SizedBox(width: 6), const StatusBadge('Nonaktif')],
                                    ]),
                                  ],
                                ),
                              ),
                              if (canManage) ...[
                                IconButton(icon: const Icon(Icons.edit_outlined, size: 18), onPressed: () => _openForm(existing: a)),
                                IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.red500), onPressed: () => _delete(a)),
                              ],
                            ]),
                          );
                        },
                      ),
      ),
    );
  }
}

class _AkunFormSheet extends StatefulWidget {
  final Akun? existing;
  const _AkunFormSheet({this.existing});

  @override
  State<_AkunFormSheet> createState() => _AkunFormSheetState();
}

class _AkunFormSheetState extends State<_AkunFormSheet> {
  final _service = AkuntansiService();
  late TextEditingController _kodeCtrl;
  late TextEditingController _namaCtrl;
  TipeAkun _tipe = TipeAkun.aset;
  String _saldoNormal = 'DEBIT';
  bool _saving = false;
  String? _error;

  bool get _editing => widget.existing != null;

  static const _defaultSaldo = {
    TipeAkun.aset: 'DEBIT',
    TipeAkun.kewajiban: 'KREDIT',
    TipeAkun.modal: 'KREDIT',
    TipeAkun.pendapatan: 'KREDIT',
    TipeAkun.beban: 'DEBIT',
  };

  @override
  void initState() {
    super.initState();
    final a = widget.existing;
    _kodeCtrl = TextEditingController(text: a?.kode ?? '');
    _namaCtrl = TextEditingController(text: a?.nama ?? '');
    _tipe = a?.tipe ?? TipeAkun.aset;
    _saldoNormal = a?.saldoNormal ?? 'DEBIT';
  }

  Future<void> _submit() async {
    if (_kodeCtrl.text.trim().isEmpty || _namaCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Kode dan nama akun wajib diisi.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final data = {
      'kode': _kodeCtrl.text.trim(),
      'nama': _namaCtrl.text.trim(),
      'tipe': _tipe.name.toUpperCase(),
      'saldoNormal': _saldoNormal,
    };
    try {
      if (_editing) {
        await _service.updateAkun(widget.existing!.id, data);
      } else {
        await _service.createAkun(data);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _error = e is ApiException ? e.message : 'Gagal menyimpan akun';
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_editing ? 'Edit Akun' : 'Tambah Akun', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextField(controller: _kodeCtrl, decoration: const InputDecoration(labelText: 'Kode Akun'), keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            DropdownButtonFormField<TipeAkun>(
              value: _tipe,
              decoration: const InputDecoration(labelText: 'Tipe Akun'),
              items: TipeAkun.values.map((t) => DropdownMenuItem(value: t, child: Text(tipeAkunLabel(t)))).toList(),
              onChanged: (v) => setState(() {
                _tipe = v ?? TipeAkun.aset;
                _saldoNormal = _defaultSaldo[_tipe]!;
              }),
            ),
            const SizedBox(height: 12),
            TextField(controller: _namaCtrl, decoration: const InputDecoration(labelText: 'Nama Akun')),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _saldoNormal,
              decoration: const InputDecoration(labelText: 'Saldo Normal'),
              items: const [DropdownMenuItem(value: 'DEBIT', child: Text('Debit')), DropdownMenuItem(value: 'KREDIT', child: Text('Kredit'))],
              onChanged: (v) => setState(() => _saldoNormal = v ?? 'DEBIT'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppColors.red600, fontSize: 12.5)),
            ],
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _submit,
                child: _saving ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Simpan'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
