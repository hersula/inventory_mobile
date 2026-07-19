import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/formatters.dart';
import '../../core/api_exception.dart';
import '../../core/rbac.dart';
import '../../models/transaksi.dart';
import '../../providers/auth_provider.dart';
import '../../services/pengadaan_service.dart';
import '../../widgets/state_views.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/app_feedback.dart';
import 'pengadaan_form_sheet.dart';
import 'pengadaan_detail_sheet.dart';

class PengadaanScreen extends StatefulWidget {
  final bool embedded;
  const PengadaanScreen({super.key, this.embedded = false});

  @override
  State<PengadaanScreen> createState() => _PengadaanScreenState();
}

class _PengadaanScreenState extends State<PengadaanScreen> {
  final _service = PengadaanService();
  final _searchCtrl = TextEditingController();
  List<Pengadaan> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _service.list(q: _searchCtrl.text.trim());
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e is ApiException ? e.message : 'Gagal memuat data pengadaan';
        _loading = false;
      });
    }
  }

  Future<void> _openForm({Pengadaan? existing}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PengadaanFormSheet(existing: existing),
    );
    if (saved == true) _load();
  }

  Future<void> _openDetail(Pengadaan p) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PengadaanDetailSheet(id: p.id),
    );
  }

  Future<void> _cancel(Pengadaan p) async {
    final confirmed = await AppFeedback.confirm(
      context,
      title: 'Batalkan Transaksi',
      message: 'Batalkan transaksi ${p.nomor}? Stok barang akan dikurangi kembali.',
      danger: true,
    );
    if (!confirmed) return;
    try {
      await _service.cancel(p.id);
      if (mounted) AppFeedback.success(context, 'Transaksi dibatalkan');
      _load();
    } catch (e) {
      if (mounted) AppFeedback.error(context, e is ApiException ? e.message : 'Gagal membatalkan transaksi');
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthProvider>().currentUser?.role;
    final canManage = can(role, 'pengadaan.manage');

    final body = RefreshIndicator(
      onRefresh: _load,
      child: _loading
          ? const LoadingView()
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : _items.isEmpty
                  ? const EmptyView(message: 'Belum ada transaksi pengadaan.', icon: Icons.local_shipping_outlined)
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final p = _items[i];
                        return _TransaksiCard(
                          nomor: p.nomor,
                          tanggal: p.tanggal,
                          pihak: p.supplier?.nama ?? '-',
                          total: p.total,
                          sisa: p.sisa,
                          metodeLabel: metodeBayarLabel(p.metodeBayar),
                          metodeTone: _metodeTone(p.metodeBayar),
                          jumlahItem: p.detail.length,
                          canManage: canManage,
                          onTap: () => _openDetail(p),
                          onEdit: () => _openForm(existing: p),
                          onCancel: () => _cancel(p),
                        );
                      },
                    ),
    );

    return Scaffold(
      appBar: widget.embedded
          ? null
          : AppBar(
              title: const Text('Pengadaan Barang'),
              bottom: _searchBar(),
            ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () => _openForm(),
              backgroundColor: AppColors.brand600,
              icon: const Icon(Icons.add),
              label: const Text('Transaksi'),
            )
          : null,
      body: widget.embedded
          ? Column(children: [Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 0), child: _searchField()), Expanded(child: body)])
          : body,
    );
  }

  PreferredSize _searchBar() => PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 12), child: _searchField()),
      );

  Widget _searchField() => TextField(
        controller: _searchCtrl,
        onSubmitted: (_) => _load(),
        decoration: InputDecoration(
          hintText: 'Cari no. transaksi...',
          prefixIcon: const Icon(Icons.search, size: 20),
          isDense: true,
          suffixIcon: IconButton(icon: const Icon(Icons.arrow_forward, size: 18), onPressed: _load),
        ),
      );

  BadgeTone _metodeTone(MetodeBayar m) => isLunasDiMuka(m) ? BadgeTone.green : BadgeTone.amber;
}

class _TransaksiCard extends StatelessWidget {
  final String nomor;
  final DateTime tanggal;
  final String pihak;
  final double total;
  final double sisa;
  final String metodeLabel;
  final BadgeTone metodeTone;
  final int jumlahItem;
  final bool canManage;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onCancel;

  const _TransaksiCard({
    required this.nomor,
    required this.tanggal,
    required this.pihak,
    required this.total,
    required this.sisa,
    required this.metodeLabel,
    required this.metodeTone,
    required this.jumlahItem,
    required this.canManage,
    required this.onTap,
    required this.onEdit,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
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
                      Text(nomor, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      Text('${Formatters.dateShort(tanggal)} · $pihak', style: const TextStyle(fontSize: 12, color: AppColors.slate500)),
                    ],
                  ),
                ),
                StatusBadge(metodeLabel, tone: metodeTone),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('$jumlahItem item', style: const TextStyle(fontSize: 12, color: AppColors.slate400)),
                Text(Formatters.rupiah(total), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              ],
            ),
            if (sisa > 0) ...[
              const SizedBox(height: 4),
              Text('Sisa ${Formatters.rupiah(sisa)}', style: const TextStyle(fontSize: 12, color: AppColors.red500, fontWeight: FontWeight.w600)),
            ],
            if (canManage) ...[
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Edit'),
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact, foregroundColor: AppColors.slate600),
                  ),
                  TextButton.icon(
                    onPressed: onCancel,
                    icon: const Icon(Icons.cancel_outlined, size: 16),
                    label: const Text('Batalkan'),
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact, foregroundColor: AppColors.red600),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
