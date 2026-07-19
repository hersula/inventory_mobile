import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/formatters.dart';
import '../../core/api_exception.dart';
import '../../services/akuntansi_service.dart';
import '../../widgets/state_views.dart';
import '../../widgets/status_badge.dart';

class LaporanTab extends StatefulWidget {
  const LaporanTab({super.key});

  @override
  State<LaporanTab> createState() => _LaporanTabState();
}

class _LaporanTabState extends State<LaporanTab> {
  final _service = AkuntansiService();
  String _sub = 'laba-rugi';
  Map<String, dynamic>? _labaRugi;
  Map<String, dynamic>? _neraca;
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
      final results = await Future.wait([_service.labaRugi(), _service.neracaSaldo()]);
      setState(() {
        _labaRugi = results[0];
        _neraca = results[1];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e is ApiException ? e.message : 'Gagal memuat laporan';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'laba-rugi', label: Text('Laba Rugi')),
                ButtonSegment(value: 'neraca-saldo', label: Text('Neraca Saldo')),
              ],
              selected: {_sub},
              onSelectionChanged: (v) => setState(() => _sub = v.first),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: _loading
                  ? const LoadingView()
                  : _error != null
                      ? ErrorView(message: _error!, onRetry: _load)
                      : _sub == 'laba-rugi'
                          ? _LabaRugiView(data: _labaRugi!)
                          : _NeracaSaldoView(data: _neraca!),
            ),
          ),
        ],
      ),
    );
  }
}

class _LabaRugiView extends StatelessWidget {
  final Map<String, dynamic> data;
  const _LabaRugiView({required this.data});

  @override
  Widget build(BuildContext context) {
    final totalPendapatan = Formatters.toDouble(data['totalPendapatan']);
    final totalBeban = Formatters.toDouble(data['totalBeban']);
    final labaRugi = Formatters.toDouble(data['labaRugi']);
    final pendapatan = (data['pendapatan'] as List? ?? []);
    final beban = (data['beban'] as List? ?? []);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        Row(children: [
          Expanded(child: _MiniCard(label: 'Pendapatan', value: Formatters.rupiah(totalPendapatan), color: AppColors.emerald600)),
          const SizedBox(width: 10),
          Expanded(child: _MiniCard(label: 'Beban', value: Formatters.rupiah(totalBeban), color: AppColors.red600)),
        ]),
        const SizedBox(height: 10),
        _MiniCard(label: labaRugi >= 0 ? 'Laba Bersih' : 'Rugi Bersih', value: Formatters.rupiah(labaRugi), color: labaRugi >= 0 ? AppColors.brand600 : AppColors.red600, full: true),
        const SizedBox(height: 16),
        const Text('Pendapatan', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
        const SizedBox(height: 8),
        if (pendapatan.isEmpty) const Text('Belum ada pendapatan.', style: TextStyle(color: AppColors.slate400, fontSize: 12.5)),
        ...pendapatan.map((p) => _LineRow(label: '${p['kode']} · ${p['nama']}', value: Formatters.rupiah(Formatters.toDouble(p['total'])))),
        const SizedBox(height: 16),
        const Text('Beban & HPP', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
        const SizedBox(height: 8),
        if (beban.isEmpty) const Text('Belum ada beban.', style: TextStyle(color: AppColors.slate400, fontSize: 12.5)),
        ...beban.map((b) => _LineRow(label: '${b['kode']} · ${b['nama']}', value: Formatters.rupiah(Formatters.toDouble(b['total'])))),
      ],
    );
  }
}

class _NeracaSaldoView extends StatelessWidget {
  final Map<String, dynamic> data;
  const _NeracaSaldoView({required this.data});

  @override
  Widget build(BuildContext context) {
    final rows = (data['rows'] as List? ?? []);
    final balance = data['balance'] == true;
    final totalDebit = Formatters.toDouble(data['grandTotalDebit']);
    final totalKredit = Formatters.toDouble(data['grandTotalKredit']);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.brand50, borderRadius: BorderRadius.circular(10)),
          child: const Text(
            'Menampilkan akumulasi debit & kredit seluruh akun sejak awal (tidak difilter tanggal).',
            style: TextStyle(fontSize: 12, color: AppColors.brand700),
          ),
        ),
        const SizedBox(height: 12),
        ...rows.map((r) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.slate200)),
              child: Row(children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${r['kode']} · ${r['nama']}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      Text('D: ${Formatters.rupiah(Formatters.toDouble(r['totalDebit']))}  K: ${Formatters.rupiah(Formatters.toDouble(r['totalKredit']))}',
                          style: const TextStyle(fontSize: 11, color: AppColors.slate400)),
                    ],
                  ),
                ),
                Text(Formatters.rupiah(Formatters.toDouble(r['saldo'])), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              ]),
            )),
        const Divider(),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Total', style: TextStyle(fontWeight: FontWeight.w700)),
          Text('${Formatters.rupiah(totalDebit)} / ${Formatters.rupiah(totalKredit)}', style: const TextStyle(fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 6),
        StatusBadge(balance ? 'Balance' : 'Tidak Balance', tone: balance ? BadgeTone.green : BadgeTone.red),
      ],
    );
  }
}

class _MiniCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool full;
  const _MiniCard({required this.label, required this.value, required this.color, this.full = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: full ? double.infinity : null,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.slate200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.slate400)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

class _LineRow extends StatelessWidget {
  final String label;
  final String value;
  const _LineRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.slate600))),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
