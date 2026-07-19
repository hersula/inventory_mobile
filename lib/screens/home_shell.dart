import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/rbac.dart';
import '../providers/auth_provider.dart';
import 'dashboard/dashboard_screen.dart';
import 'master_barang/master_barang_screen.dart';
import 'transaksi_tab_screen.dart';
import 'akuntansi/akuntansi_home_screen.dart';
import 'profile/profile_screen.dart';

/// Shell dengan bottom navigation — daftar tab menyesuaikan permission role
/// user (port dari `navItems` + `can()` di Sidebar.tsx versi web).
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthProvider>().currentUser?.role;

    final tabs = <_TabItem>[
      _TabItem('Dashboard', Icons.dashboard_outlined, Icons.dashboard, const DashboardScreen()),
      if (can(role, 'barang.view'))
        _TabItem('Barang', Icons.inventory_2_outlined, Icons.inventory_2, const MasterBarangScreen()),
      if (can(role, 'pengadaan.view') || can(role, 'penjualan.view'))
        _TabItem('Transaksi', Icons.receipt_long_outlined, Icons.receipt_long, const TransaksiTabScreen()),
      if (can(role, 'akuntansi.view'))
        _TabItem('Akuntansi', Icons.account_balance_outlined, Icons.account_balance, const AkuntansiHomeScreen()),
      _TabItem('Profil', Icons.person_outline, Icons.person, const ProfileScreen()),
    ];

    if (_index >= tabs.length) _index = 0;

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: tabs.map((t) => t.screen).toList(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: tabs
            .map((t) => BottomNavigationBarItem(
                  icon: Icon(t.icon),
                  activeIcon: Icon(t.activeIcon),
                  label: t.label,
                ))
            .toList(),
      ),
    );
  }
}

class _TabItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final Widget screen;
  _TabItem(this.label, this.icon, this.activeIcon, this.screen);
}
