import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/formatters.dart';
import '../../core/api_exception.dart';
import '../../core/rbac.dart';
import '../../models/barang.dart';
import '../../providers/auth_provider.dart';
import '../../services/barang_service.dart';
import '../../widgets/state_views.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/app_feedback.dart';
import 'barang_form_sheet.dart';

class MasterBarangScreen extends StatefulWidget {
  const MasterBarangScreen({super.key});

  @override
  State<MasterBarangScreen> createState() => _MasterBarangScreenState();
}

class _MasterBarangScreenState extends State<MasterBarangScreen> {
  final _service = BarangService();
  final _searchCtrl = TextEditingController();
  List<Barang> _items = [];
  List<Kategori> _kategoris = [];
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
      final results = await Future.wait([_service.list(q: _searchCtrl.text.trim()), _service.listKategori()]);
      setState(() {
        _items = results[0] as List<Barang>;
        _kategoris = results[1] as List<Kategori>;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e is ApiException ? e.message : 'Gagal memuat data barang';
        _loading = false;
      });
    }
  }

  Future<void> _openForm({Barang? existing}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BarangFormSheet(existing: existing, kategoris: _kategoris, onKategoriAdded: (k) => setState(() => _kategoris = [..._kategoris, k])),
    );
    if (saved == true) _load();
  }

  Future<void> _delete(Barang b) async {
    final confirmed = await AppFeedback.confirm(context, title: 'Hapus Barang', message: 'Hapus "${b.nama}"?', danger: true);
    if (!confirmed) return;
    try {
      await _service.delete(b.id);
      if (mounted) AppFeedback.success(context, 'Barang dihapus');
      _load();
    } catch (e) {
      if (mounted) AppFeedback.error(context, e is ApiException ? e.message : 'Gagal menghapus barang');
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthProvider>().currentUser?.role;
    final canManage = can(role, 'barang.manage');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Master Barang'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchCtrl,
              onSubmitted: (_) => _load(),
              decoration: InputDecoration(
                hintText: 'Cari kode atau nama barang...',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                suffixIcon: IconButton(icon: const Icon(Icons.arrow_forward, size: 18), onPressed: _load),
              ),
            ),
          ),
        ),
      ),
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
                    ? const EmptyView(message: 'Belum ada barang.', icon: Icons.inventory_2_outlined)
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final b = _items[i];
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.slate200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(b.nama, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5)),
                                          Text('${b.kode} · ${b.kategori?.nama ?? "Tanpa kategori"}',
                                              style: const TextStyle(fontSize: 12, color: AppColors.slate400)),
                                        ],
                                      ),
                                    ),
                                    StatusBadge(
                                      b.stok == 0 ? 'Habis' : (b.stokMenipis ? 'Menipis' : 'Aman'),
                                      tone: b.stok == 0 ? BadgeTone.red : (b.stokMenipis ? BadgeTone.amber : BadgeTone.green),
                                    ),
                                  ],
                                ),
                                const Divider(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _MiniStat(label: 'Stok', value: '${b.stok} ${b.satuan}'),
                                    _MiniStat(label: 'Beli', value: Formatters.rupiah(b.hargaBeli)),
                                    _MiniStat(label: 'Jual', value: Formatters.rupiah(b.hargaJual)),
                                    if (canManage)
                                      Row(children: [
                                        IconButton(
                                          visualDensity: VisualDensity.compact,
                                          icon: const Icon(Icons.edit_outlined, size: 19, color: AppColors.slate500),
                                          onPressed: () => _openForm(existing: b),
                                        ),
                                        IconButton(
                                          visualDensity: VisualDensity.compact,
                                          icon: const Icon(Icons.delete_outline, size: 19, color: AppColors.red500),
                                          onPressed: () => _delete(b),
                                        ),
                                      ]),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10.5, color: AppColors.slate400)),
        Text(value, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.slate700)),
      ],
    );
  }
}
