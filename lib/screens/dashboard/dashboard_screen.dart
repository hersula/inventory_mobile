import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme.dart';
import '../../core/formatters.dart';
import '../../core/api_exception.dart';
import '../../models/dashboard.dart';
import '../../services/dashboard_service.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/state_views.dart';
import '../../widgets/status_badge.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _service = DashboardService();
  Future<DashboardStats>? _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() => _future = _service.stats());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: RefreshIndicator(
        onRefresh: () async {
          _load();
          await _future;
        },
        child: FutureBuilder<DashboardStats>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const LoadingView();
            if (snapshot.hasError) {
              final msg = snapshot.error is ApiException ? (snapshot.error as ApiException).message : 'Gagal memuat data';
              return ListView(children: [SizedBox(height: 200, child: ErrorView(message: msg, onRetry: _load))]);
            }
            final stats = snapshot.data!;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.35,
                  children: [
                    StatCard(
                      label: 'Total Jenis Barang',
                      value: stats.totalBarang.toString(),
                      hint: '${stats.totalStok} unit di gudang',
                      icon: Icons.inventory_2_outlined,
                      tone: AppColors.brand600,
                    ),
                    StatCard(
                      label: 'Nilai Stok Gudang',
                      value: Formatters.rupiah(stats.totalNilaiStok),
                      hint: 'Berdasarkan harga beli',
                      icon: Icons.account_balance_wallet_outlined,
                      tone: AppColors.emerald600,
                    ),
                    StatCard(
                      label: 'Penjualan Bulan Ini',
                      value: Formatters.rupiah(stats.penjualanBulanIniTotal),
                      hint: '${stats.penjualanBulanIniJumlah} transaksi',
                      icon: Icons.trending_up,
                      tone: AppColors.brand600,
                    ),
                    StatCard(
                      label: 'Pengadaan Bulan Ini',
                      value: Formatters.rupiah(stats.pengadaanBulanIniTotal),
                      hint: '${stats.pengadaanBulanIniJumlah} transaksi',
                      icon: Icons.trending_down,
                      tone: AppColors.amber500,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (stats.chartMonthly.isNotEmpty) _ChartCard(stats: stats),
                const SizedBox(height: 16),
                _LowStockCard(items: stats.lowStockItems),
                const SizedBox(height: 16),
                if (stats.topBarang.isNotEmpty) _TopBarangCard(items: stats.topBarang),
                const SizedBox(height: 24),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final DashboardStats stats;
  const _ChartCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final maxVal = stats.chartMonthly
        .fold<double>(0, (m, e) => [m, e.penjualan, e.pengadaan].reduce((a, b) => a > b ? a : b));
    final safeMax = maxVal <= 0 ? 1.0 : maxVal;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.slate200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tren Penjualan vs Pengadaan (6 Bulan)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
          const SizedBox(height: 4),
          Row(children: [
            _LegendDot(color: AppColors.brand600, label: 'Penjualan'),
            const SizedBox(width: 12),
            _LegendDot(color: AppColors.amber500, label: 'Pengadaan'),
          ]),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                maxY: safeMax * 1.2,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= stats.chartMonthly.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(stats.chartMonthly[i].bulan, style: const TextStyle(fontSize: 10, color: AppColors.slate500)),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: [
                  for (int i = 0; i < stats.chartMonthly.length; i++)
                    BarChartGroupData(x: i, barRods: [
                      BarChartRodData(toY: stats.chartMonthly[i].penjualan, color: AppColors.brand600, width: 7, borderRadius: BorderRadius.circular(3)),
                      BarChartRodData(toY: stats.chartMonthly[i].pengadaan, color: AppColors.amber500, width: 7, borderRadius: BorderRadius.circular(3)),
                    ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 11, color: AppColors.slate500)),
    ]);
  }
}

class _LowStockCard extends StatelessWidget {
  final List<LowStockItem> items;
  const _LowStockCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.slate200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: const [
            Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.amber500),
            SizedBox(width: 6),
            Text('Barang Stok Menipis', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
          ]),
          const SizedBox(height: 10),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Semua stok barang dalam kondisi aman.', style: TextStyle(color: AppColors.slate400, fontSize: 13)),
            )
          else
            ...items.map((it) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(it.nama, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                            Text(it.kode, style: const TextStyle(fontSize: 11, color: AppColors.slate400)),
                          ],
                        ),
                      ),
                      Text('${it.stok}/${it.stokMinimum}', style: const TextStyle(fontSize: 12, color: AppColors.slate500)),
                      const SizedBox(width: 8),
                      StatusBadge(it.stok == 0 ? 'Habis' : 'Menipis', tone: it.stok == 0 ? BadgeTone.red : BadgeTone.amber),
                    ],
                  ),
                )),
        ],
      ),
    );
  }
}

class _TopBarangCard extends StatelessWidget {
  final List<TopBarangItem> items;
  const _TopBarangCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.slate200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Barang Terlaris', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
          const SizedBox(height: 10),
          ...items.map((it) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Expanded(child: Text(it.nama, style: const TextStyle(fontSize: 13))),
                    Text('${it.terjual} terjual', style: const TextStyle(fontSize: 12, color: AppColors.slate500)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
