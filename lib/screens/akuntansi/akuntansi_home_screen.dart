import 'package:flutter/material.dart';
import 'akun_tab.dart';
import 'jurnal_tab.dart';
import 'pembayaran_tab.dart';
import 'laporan_tab.dart';

class AkuntansiHomeScreen extends StatelessWidget {
  const AkuntansiHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Akuntansi'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Chart of Akun'),
              Tab(text: 'Jurnal Umum'),
              Tab(text: 'Hutang & Piutang'),
              Tab(text: 'Laporan'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [AkunTab(), JurnalTab(), PembayaranTab(), LaporanTab()],
        ),
      ),
    );
  }
}
