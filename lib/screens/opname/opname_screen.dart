import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/formatters.dart';
import '../../core/api_exception.dart';
import '../../core/rbac.dart';
import '../../models/stok_opname.dart';
import '../../providers/auth_provider.dart';
import '../../services/opname_service.dart';
import '../../widgets/state_views.dart';
import '../../widgets/app_feedback.dart';
import 'opname_form_screen.dart';

class OpnameScreen extends StatefulWidget {
  final bool embedded;
  const OpnameScreen({super.key, this.embedded = false});

  @override
  State<OpnameScreen> createState() => _OpnameScreenState();
}

class _OpnameScreenState extends State<OpnameScreen> {
  final _service = OpnameService();
  List<StokOpname> _items = [];
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
      final items = await _service.list();
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e is ApiException ? e.message : 'Gagal memuat data stock opname';
        _loading = false;
      });
    }
  }

  Future<void> _openForm() async {
    final saved = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const OpnameFormScreen()));
    if (saved == true) _load();
  }

  Future<void> _batalkan(StokOpname o) async {
    final confirmed = await AppFeedback.confirm(
      context,
      title: 'Batalkan Stock Opname',
      message: 'Batalkan opname ${o.nomor}? Stok & jurnal terkait akan dikembalikan seperti semula.',
      danger: true,
    );
    if (!confirmed) return;
    try {
      await _service.cancel(o.id);
      if (mounted) AppFeedback.success(context, 'Stock opname dibatalkan');
      _load();
    } catch (e) {
      if (mounted) AppFeedback.error(context, e is ApiException ? e.message : 'Gagal membatalkan stock opname');
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthProvider>().currentUser?.role;
    final canManage = can(role, 'opname.manage');

    final body = RefreshIndicator(
      onRefresh: _load,
      child: _loading
          ? const LoadingView()
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : _items.isEmpty
                  ? const EmptyView(message: 'Belum ada stock opname.', icon: Icons.fact_check_outlined)
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final o = _items[i];
                        return _OpnameCard(opname: o, canManage: canManage, onBatalkan: () => _batalkan(o));
                      },
                    ),
    );

    return Scaffold(
      appBar: widget.embedded ? null : AppBar(title: const Text('Stock Opname')),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: _openForm,
              backgroundColor: AppColors.brand600,
              icon: const Icon(Icons.add),
              label: const Text('Opname'),
            )
          : null,
      body: body,
    );
  }
}

class _OpnameCard extends StatelessWidget {
  final StokOpname opname;
  final bool canManage;
  final VoidCallback onBatalkan;

  const _OpnameCard({required this.opname, required this.canManage, required this.onBatalkan});

  @override
  Widget build(BuildContext context) {
    final berselisih = opname.berselisih;
    final ringkasan = berselisih.isEmpty
        ? 'Tidak ada selisih'
        : berselisih.map((d) => '${d.barangNama} (${d.selisih > 0 ? "+" : ""}${d.selisih})').join(', ');
    final nilai = opname.totalNilaiSelisih;
    final nilaiColor = nilai > 0 ? AppColors.emerald600 : (nilai < 0 ? AppColors.red600 : AppColors.slate400);
    final nilaiText = nilai == 0 ? 'Rp 0' : '${nilai > 0 ? '+' : '-'}${Formatters.rupiah(nilai.abs())}';

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
                    Text(opname.nomor, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    Text('${Formatters.dateShort(opname.tanggal)} · ${opname.userName}', style: const TextStyle(fontSize: 12, color: AppColors.slate500)),
                  ],
                ),
              ),
              Text(nilaiText, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: nilaiColor)),
            ],
          ),
          const SizedBox(height: 6),
          Text('${opname.detail.length} barang dihitung · ${berselisih.length} berselisih', style: const TextStyle(fontSize: 12, color: AppColors.slate400)),
          if (ringkasan.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(ringkasan, style: const TextStyle(fontSize: 12.5, color: AppColors.slate600)),
          ],
          if (opname.catatan != null && opname.catatan!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Catatan: ${opname.catatan}', style: const TextStyle(fontSize: 12, color: AppColors.slate400, fontStyle: FontStyle.italic)),
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
