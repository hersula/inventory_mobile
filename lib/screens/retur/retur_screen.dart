import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/formatters.dart';
import '../../core/api_exception.dart';
import '../../core/rbac.dart';
import '../../models/retur.dart';
import '../../providers/auth_provider.dart';
import '../../services/retur_service.dart';
import '../../widgets/state_views.dart';
import '../../widgets/app_feedback.dart';
import 'retur_form_sheet.dart';

class ReturScreen extends StatefulWidget {
  final bool embedded;
  const ReturScreen({super.key, this.embedded = false});

  @override
  State<ReturScreen> createState() => _ReturScreenState();
}

class _ReturScreenState extends State<ReturScreen> {
  final _service = ReturService();
  JenisRetur _jenis = JenisRetur.pembelian;
  List<Retur> _items = [];
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
      final items = await _service.list(_jenis);
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e is ApiException ? e.message : 'Gagal memuat data retur';
        _loading = false;
      });
    }
  }

  Future<void> _openForm() async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReturFormSheet(jenis: _jenis),
    );
    if (saved == true) _load();
  }

  Future<void> _batalkan(Retur r) async {
    final confirmed = await AppFeedback.confirm(
      context,
      title: 'Batalkan Retur',
      message: 'Batalkan retur ${r.nomor}? Stok & jurnal terkait akan dikembalikan seperti semula.',
      danger: true,
    );
    if (!confirmed) return;
    try {
      await _service.cancel(r.id);
      if (mounted) AppFeedback.success(context, 'Retur dibatalkan');
      _load();
    } catch (e) {
      if (mounted) AppFeedback.error(context, e is ApiException ? e.message : 'Gagal membatalkan retur');
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthProvider>().currentUser?.role;
    final canManage = can(role, 'retur.manage');

    final body = Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: SegmentedButton<JenisRetur>(
            segments: const [
              ButtonSegment(value: JenisRetur.pembelian, label: Text('Pembelian'), icon: Icon(Icons.remove_shopping_cart_outlined, size: 16)),
              ButtonSegment(value: JenisRetur.penjualan, label: Text('Penjualan'), icon: Icon(Icons.add_shopping_cart_outlined, size: 16)),
            ],
            selected: {_jenis},
            onSelectionChanged: (v) {
              setState(() => _jenis = v.first);
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
                    : _items.isEmpty
                        ? const EmptyView(message: 'Belum ada retur.', icon: Icons.undo_outlined)
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            itemCount: _items.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, i) {
                              final r = _items[i];
                              return _ReturCard(retur: r, canManage: canManage, onBatalkan: () => _batalkan(r));
                            },
                          ),
          ),
        ),
      ],
    );

    return Scaffold(
      appBar: widget.embedded ? null : AppBar(title: const Text('Retur Barang')),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: _openForm,
              backgroundColor: AppColors.brand600,
              icon: const Icon(Icons.add),
              label: const Text('Retur'),
            )
          : null,
      body: body,
    );
  }
}

class _ReturCard extends StatelessWidget {
  final Retur retur;
  final bool canManage;
  final VoidCallback onBatalkan;

  const _ReturCard({required this.retur, required this.canManage, required this.onBatalkan});

  @override
  Widget build(BuildContext context) {
    final ringkasBarang = retur.detail.map((d) => '${d.barangNama} (${d.qty})').join(', ');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.slate200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(retur.nomor, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    Text('${Formatters.dateShort(retur.tanggal)} · ${retur.referensiPihak ?? "-"}', style: const TextStyle(fontSize: 12, color: AppColors.slate500)),
                  ],
                ),
              ),
              Text(Formatters.rupiah(retur.total), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 6),
          Text('Untuk transaksi ${retur.referensiNomor ?? "-"}', style: const TextStyle(fontSize: 12, color: AppColors.slate400)),
          if (ringkasBarang.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(ringkasBarang, style: const TextStyle(fontSize: 12.5, color: AppColors.slate600)),
          ],
          if (retur.catatan != null && retur.catatan!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Catatan: ${retur.catatan}', style: const TextStyle(fontSize: 12, color: AppColors.slate400, fontStyle: FontStyle.italic)),
          ],
          if (canManage) ...[
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onBatalkan,
                  icon: const Icon(Icons.cancel_outlined, size: 16),
                  label: const Text('Batalkan'),
                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact, foregroundColor: AppColors.red600),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
