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

class PembayaranTab extends StatefulWidget {
  const PembayaranTab({super.key});

  @override
  State<PembayaranTab> createState() => _PembayaranTabState();
}

class _PembayaranTabState extends State<PembayaranTab> with SingleTickerProviderStateMixin {
  final _service = AkuntansiService();
  String _tipe = 'HUTANG';
  List<OutstandingItem> _outstanding = [];
  List<RiwayatPembayaran> _riwayat = [];
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
      final results = await Future.wait([_service.outstanding(_tipe), _service.riwayatPembayaran(_tipe)]);
      setState(() {
        _outstanding = results[0] as List<OutstandingItem>;
        _riwayat = results[1] as List<RiwayatPembayaran>;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e is ApiException ? e.message : 'Gagal memuat data';
        _loading = false;
      });
    }
  }

  Future<void> _openBayar(OutstandingItem item) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _BayarFormSheet(tipe: _tipe, item: item),
    );
    if (saved == true) _load();
  }

  Future<void> _batalkan(RiwayatPembayaran r) async {
    final confirmed = await AppFeedback.confirm(
      context,
      title: 'Batalkan Pembayaran',
      message: 'Batalkan pembayaran ${r.nomor}? Jurnal terkait akan ikut dihapus.',
      danger: true,
    );
    if (!confirmed) return;
    try {
      await _service.batalkanPembayaran(r.id);
      if (mounted) AppFeedback.success(context, 'Pembayaran dibatalkan');
      _load();
    } catch (e) {
      if (mounted) AppFeedback.error(context, e is ApiException ? e.message : 'Gagal membatalkan pembayaran');
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthProvider>().currentUser?.role;
    final canManage = can(role, 'akuntansi.manage');

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'HUTANG', label: Text('Hutang'), icon: Icon(Icons.arrow_upward, size: 16)),
                ButtonSegment(value: 'PIUTANG', label: Text('Piutang'), icon: Icon(Icons.arrow_downward, size: 16)),
              ],
              selected: {_tipe},
              onSelectionChanged: (v) {
                setState(() => _tipe = v.first);
                _load();
              },
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: _loading
                  ? const LoadingView()
                  : _error != null
                      ? ErrorView(message: _error!, onRetry: _load)
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          children: [
                            Text(_tipe == 'HUTANG' ? 'Perlu Dibayar ke Supplier' : 'Perlu Ditagih dari Pelanggan',
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                            const SizedBox(height: 8),
                            if (_outstanding.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Text('Tidak ada yang perlu dibayar/ditagih.', style: TextStyle(color: AppColors.slate400, fontSize: 13)),
                              )
                            else
                              ..._outstanding.map((o) => Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.slate200)),
                                    child: Row(children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(o.nomor, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                                            Text(o.pihak, style: const TextStyle(fontSize: 12, color: AppColors.slate500)),
                                            const SizedBox(height: 2),
                                            Text('Sisa ${Formatters.rupiah(o.sisa)}', style: const TextStyle(color: AppColors.red600, fontWeight: FontWeight.w700, fontSize: 12.5)),
                                          ],
                                        ),
                                      ),
                                      if (canManage)
                                        ElevatedButton(
                                          onPressed: () => _openBayar(o),
                                          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8)),
                                          child: const Text('Bayar', style: TextStyle(fontSize: 12.5)),
                                        ),
                                    ]),
                                  )),
                            const SizedBox(height: 20),
                            const Text('Riwayat Pembayaran', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                            const SizedBox(height: 8),
                            if (_riwayat.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Text('Belum ada riwayat pembayaran.', style: TextStyle(color: AppColors.slate400, fontSize: 13)),
                              )
                            else
                              ..._riwayat.map((r) => Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.slate200)),
                                    child: Row(children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(r.nomor, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                            Text('${r.referensiNomor ?? "-"} · ${r.referensiPihak ?? "-"}', style: const TextStyle(fontSize: 11.5, color: AppColors.slate500)),
                                            Text(Formatters.dateShort(r.tanggal), style: const TextStyle(fontSize: 11, color: AppColors.slate400)),
                                          ],
                                        ),
                                      ),
                                      Text(Formatters.rupiah(r.jumlah), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                      if (canManage)
                                        IconButton(
                                          visualDensity: VisualDensity.compact,
                                          icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.red500),
                                          onPressed: () => _batalkan(r),
                                        ),
                                    ]),
                                  )),
                          ],
                        ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BayarFormSheet extends StatefulWidget {
  final String tipe;
  final OutstandingItem item;
  const _BayarFormSheet({required this.tipe, required this.item});

  @override
  State<_BayarFormSheet> createState() => _BayarFormSheetState();
}

class _BayarFormSheetState extends State<_BayarFormSheet> {
  final _service = AkuntansiService();
  late TextEditingController _jumlahCtrl;
  final _keteranganCtrl = TextEditingController();
  String _metode = 'TUNAI';
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _jumlahCtrl = TextEditingController(text: widget.item.sisa.toStringAsFixed(0));
  }

  Future<void> _submit() async {
    final jumlah = double.tryParse(_jumlahCtrl.text) ?? 0;
    if (jumlah <= 0) {
      setState(() => _error = 'Jumlah pembayaran harus lebih dari 0.');
      return;
    }
    if (jumlah > widget.item.sisa + 0.5) {
      setState(() => _error = 'Jumlah melebihi sisa yang belum dilunasi (${Formatters.rupiah(widget.item.sisa)}).');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _service.bayar({
        'tipe': widget.tipe,
        'referensiId': widget.item.id,
        'jumlah': jumlah,
        'metodeBayar': _metode,
        'keterangan': _keteranganCtrl.text.trim().isEmpty ? null : _keteranganCtrl.text.trim(),
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _error = e is ApiException ? e.message : 'Gagal mencatat pembayaran';
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
            Text('Catat Pembayaran ${widget.tipe == "HUTANG" ? "Hutang" : "Piutang"}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.slate50, borderRadius: BorderRadius.circular(10)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('No. Transaksi', style: TextStyle(color: AppColors.slate500, fontSize: 12.5)), Text(widget.item.nomor, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5))]),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Pihak', style: TextStyle(color: AppColors.slate500, fontSize: 12.5)), Text(widget.item.pihak, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5))]),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Sisa', style: TextStyle(color: AppColors.slate500, fontSize: 12.5)), Text(Formatters.rupiah(widget.item.sisa), style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.red600, fontSize: 13))]),
              ]),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _jumlahCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Jumlah Dibayar'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _metode,
              decoration: const InputDecoration(labelText: 'Metode Pembayaran'),
              items: const [DropdownMenuItem(value: 'TUNAI', child: Text('Tunai (Kas)')), DropdownMenuItem(value: 'TRANSFER', child: Text('Transfer Bank'))],
              onChanged: (v) => setState(() => _metode = v ?? 'TUNAI'),
            ),
            const SizedBox(height: 12),
            TextField(controller: _keteranganCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Keterangan (opsional)')),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppColors.red600, fontSize: 12.5)),
            ],
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _submit,
                child: _saving ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Simpan Pembayaran'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
