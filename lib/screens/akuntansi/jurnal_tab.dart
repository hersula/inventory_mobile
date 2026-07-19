import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/formatters.dart';
import '../../core/api_exception.dart';
import '../../core/rbac.dart';
import '../../models/akuntansi.dart';
import '../../providers/auth_provider.dart';
import '../../services/akuntansi_service.dart';
import '../../widgets/state_views.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/app_feedback.dart';

const _refLabel = {
  'manual': 'Manual',
  'pengadaan': 'Otomatis · Pengadaan',
  'penjualan': 'Otomatis · Penjualan',
  'pembayaran-hutang': 'Otomatis · Bayar Hutang',
  'pembayaran-piutang': 'Otomatis · Terima Piutang',
};

class JurnalTab extends StatefulWidget {
  const JurnalTab({super.key});

  @override
  State<JurnalTab> createState() => _JurnalTabState();
}

class _JurnalTabState extends State<JurnalTab> {
  final _service = AkuntansiService();
  List<JurnalEntry> _items = [];
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
      final items = await _service.listJurnal();
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e is ApiException ? e.message : 'Gagal memuat jurnal';
        _loading = false;
      });
    }
  }

  Future<void> _openManualForm() async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _JurnalManualFormSheet(),
    );
    if (saved == true) _load();
  }

  void _openDetail(JurnalEntry j) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(j.nomor, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              Text(j.keterangan ?? '-', style: const TextStyle(color: AppColors.slate500, fontSize: 13)),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: j.detail
                      .map((d) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(children: [
                              Expanded(child: Text('${d.akun.kode} · ${d.akun.nama}', style: const TextStyle(fontSize: 13))),
                              Text(d.debit > 0 ? Formatters.rupiah(d.debit) : '-', style: const TextStyle(fontSize: 12.5)),
                              const SizedBox(width: 12),
                              Text(d.kredit > 0 ? Formatters.rupiah(d.kredit) : '-', style: const TextStyle(fontSize: 12.5)),
                            ]),
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _delete(JurnalEntry j) async {
    if (j.referensiTipe != 'manual') {
      AppFeedback.error(context, 'Jurnal otomatis tidak bisa dihapus langsung — ubah lewat transaksi sumbernya.');
      return;
    }
    final confirmed = await AppFeedback.confirm(context, title: 'Hapus Jurnal', message: 'Hapus jurnal ${j.nomor}?', danger: true);
    if (!confirmed) return;
    try {
      await _service.deleteJurnal(j.id);
      if (mounted) AppFeedback.success(context, 'Jurnal dihapus');
      _load();
    } catch (e) {
      if (mounted) AppFeedback.error(context, e is ApiException ? e.message : 'Gagal menghapus jurnal');
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthProvider>().currentUser?.role;
    final canManage = can(role, 'akuntansi.manage');

    return Scaffold(
      floatingActionButton: canManage
          ? FloatingActionButton.extended(onPressed: _openManualForm, backgroundColor: AppColors.brand600, icon: const Icon(Icons.add), label: const Text('Jurnal Manual'))
          : null,
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const LoadingView()
            : _error != null
                ? ErrorView(message: _error!, onRetry: _load)
                : _items.isEmpty
                    ? const EmptyView(message: 'Belum ada jurnal.')
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final j = _items[i];
                          return InkWell(
                            onTap: () => _openDetail(j),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.slate200)),
                              child: Row(children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(j.nomor, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                                      Text(j.keterangan ?? '-', style: const TextStyle(fontSize: 12, color: AppColors.slate500)),
                                      const SizedBox(height: 4),
                                      StatusBadge(_refLabel[j.referensiTipe] ?? j.referensiTipe,
                                          tone: j.referensiTipe == 'manual' ? BadgeTone.slate : BadgeTone.brand),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(Formatters.rupiah(j.totalDebit), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                    if (canManage && j.referensiTipe == 'manual')
                                      IconButton(
                                        visualDensity: VisualDensity.compact,
                                        icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.red500),
                                        onPressed: () => _delete(j),
                                      ),
                                  ],
                                ),
                              ]),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}

class _JurnalLineInput {
  int? akunId;
  String akunLabel = '';
  String debit = '';
  String kredit = '';
}

class _JurnalManualFormSheet extends StatefulWidget {
  const _JurnalManualFormSheet();

  @override
  State<_JurnalManualFormSheet> createState() => _JurnalManualFormSheetState();
}

class _JurnalManualFormSheetState extends State<_JurnalManualFormSheet> {
  final _service = AkuntansiService();
  final _keteranganCtrl = TextEditingController();
  List<Akun> _akunList = [];
  final List<_JurnalLineInput> _rows = [_JurnalLineInput(), _JurnalLineInput()];
  bool _loadingRef = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service.listAkun().then((v) => setState(() {
          _akunList = v;
          _loadingRef = false;
        }));
  }

  double get _totalDebit => _rows.fold(0, (s, r) => s + (double.tryParse(r.debit) ?? 0));
  double get _totalKredit => _rows.fold(0, (s, r) => s + (double.tryParse(r.kredit) ?? 0));
  bool get _balance => _totalDebit == _totalKredit && _totalDebit > 0;

  Future<void> _submit() async {
    final validRows = _rows.where((r) => r.akunId != null && ((double.tryParse(r.debit) ?? 0) > 0 || (double.tryParse(r.kredit) ?? 0) > 0)).toList();
    if (validRows.length < 2) {
      setState(() => _error = 'Jurnal minimal terdiri dari 2 baris.');
      return;
    }
    if (!_balance) {
      setState(() => _error = 'Jurnal belum balance. Total debit harus sama dengan total kredit.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _service.createJurnal({
        'keterangan': _keteranganCtrl.text.trim(),
        'lines': validRows
            .map((r) => {
                  'akunId': r.akunId,
                  'debit': double.tryParse(r.debit) ?? 0,
                  'kredit': double.tryParse(r.kredit) ?? 0,
                })
            .toList(),
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _error = e is ApiException ? e.message : 'Gagal menyimpan jurnal';
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          padding: const EdgeInsets.all(20),
          child: _loadingRef
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Row(children: [
                      const Expanded(child: Text('Input Jurnal Manual', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                    ]),
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        children: [
                          TextField(controller: _keteranganCtrl, decoration: const InputDecoration(labelText: 'Keterangan')),
                          const SizedBox(height: 14),
                          ..._rows.asMap().entries.map((entry) {
                            final row = entry.value;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(border: Border.all(color: AppColors.slate200), borderRadius: BorderRadius.circular(10)),
                              child: Column(children: [
                                DropdownButtonFormField<int>(
                                  value: row.akunId,
                                  isExpanded: true,
                                  decoration: const InputDecoration(labelText: 'Akun', isDense: true),
                                  items: _akunList.map((a) => DropdownMenuItem(value: a.id, child: Text('${a.kode} - ${a.nama}', overflow: TextOverflow.ellipsis))).toList(),
                                  onChanged: (v) => setState(() => row.akunId = v),
                                ),
                                const SizedBox(height: 8),
                                Row(children: [
                                  Expanded(
                                    child: TextFormField(
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      decoration: const InputDecoration(labelText: 'Debit', isDense: true),
                                      onChanged: (v) => setState(() {
                                        row.debit = v;
                                        if (v.isNotEmpty) row.kredit = '';
                                      }),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextFormField(
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      decoration: const InputDecoration(labelText: 'Kredit', isDense: true),
                                      onChanged: (v) => setState(() {
                                        row.kredit = v;
                                        if (v.isNotEmpty) row.debit = '';
                                      }),
                                    ),
                                  ),
                                  if (_rows.length > 2)
                                    IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => setState(() => _rows.removeAt(entry.key))),
                                ]),
                              ]),
                            );
                          }),
                          TextButton.icon(
                            onPressed: () => setState(() => _rows.add(_JurnalLineInput())),
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Tambah baris'),
                          ),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _balance ? AppColors.emerald500.withOpacity(0.08) : AppColors.amber500.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${Formatters.rupiah(_totalDebit)} / ${Formatters.rupiah(_totalKredit)} ${_balance ? "✓ Balance" : "— belum balance"}',
                              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: _balance ? AppColors.emerald600 : const Color(0xFFB45309)),
                            ),
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 10),
                            Text(_error!, style: const TextStyle(color: AppColors.red600, fontSize: 12.5)),
                          ],
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _saving ? null : _submit,
                              child: _saving ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Simpan Jurnal'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
