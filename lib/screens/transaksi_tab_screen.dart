import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/rbac.dart';
import '../providers/auth_provider.dart';
import 'pengadaan/pengadaan_screen.dart';
import 'penjualan/penjualan_screen.dart';

class TransaksiTabScreen extends StatefulWidget {
  const TransaksiTabScreen({super.key});

  @override
  State<TransaksiTabScreen> createState() => _TransaksiTabScreenState();
}

class _TransaksiTabScreenState extends State<TransaksiTabScreen> with SingleTickerProviderStateMixin {
  late TabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthProvider>().currentUser?.role;
    final showPengadaan = can(role, 'pengadaan.view');
    final showPenjualan = can(role, 'penjualan.view');

    if (showPengadaan && !showPenjualan) return const PengadaanScreen(embedded: false);
    if (!showPengadaan && showPenjualan) return const PenjualanScreen(embedded: false);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Transaksi'),
          bottom: const TabBar(
            tabs: [Tab(text: 'Pengadaan'), Tab(text: 'Penjualan')],
          ),
        ),
        body: const TabBarView(
          children: [
            PengadaanScreen(embedded: true),
            PenjualanScreen(embedded: true),
          ],
        ),
      ),
    );
  }
}
