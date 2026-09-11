import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/rbac.dart';
import '../providers/auth_provider.dart';
import 'pengadaan/pengadaan_screen.dart';
import 'penjualan/penjualan_screen.dart';
import 'retur/retur_screen.dart';

/// Menggabungkan Pengadaan, Penjualan, dan Retur dalam satu shell tab —
/// jumlah tab menyesuaikan permission role user (kalau cuma 1 modul yang
/// boleh diakses, tampilkan langsung tanpa TabBar).
class TransaksiTabScreen extends StatelessWidget {
  const TransaksiTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthProvider>().currentUser?.role;

    final visible = <_TransaksiTab>[
      if (can(role, 'pengadaan.view'))
        const _TransaksiTab('Pengadaan', PengadaanScreen(embedded: true), PengadaanScreen(embedded: false)),
      if (can(role, 'penjualan.view'))
        const _TransaksiTab('Penjualan', PenjualanScreen(embedded: true), PenjualanScreen(embedded: false)),
      if (can(role, 'retur.view')) const _TransaksiTab('Retur', ReturScreen(embedded: true), ReturScreen(embedded: false)),
    ];

    if (visible.isEmpty) return const SizedBox.shrink();
    if (visible.length == 1) return visible.first.standalone;

    return DefaultTabController(
      length: visible.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Transaksi'),
          bottom: TabBar(tabs: visible.map((t) => Tab(text: t.label)).toList()),
        ),
        body: TabBarView(children: visible.map((t) => t.embedded).toList()),
      ),
    );
  }
}

class _TransaksiTab {
  final String label;
  final Widget embedded;
  final Widget standalone;
  const _TransaksiTab(this.label, this.embedded, this.standalone);
}
