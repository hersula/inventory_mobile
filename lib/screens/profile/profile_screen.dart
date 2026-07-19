import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/rbac.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import '../users/users_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Yakin ingin keluar dari akun ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.red600),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await context.read<AuthProvider>().logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.slate200)),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.brand100,
                  child: Text(
                    (user?.name.isNotEmpty == true ? user!.name[0] : '?').toUpperCase(),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.brand700),
                  ),
                ),
                const SizedBox(height: 12),
                Text(user?.name ?? '-', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                Text(user?.email ?? '-', style: const TextStyle(fontSize: 13, color: AppColors.slate500)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(color: AppColors.brand50, borderRadius: BorderRadius.circular(999)),
                  child: Text(user != null ? roleLabel(user.role) : '-', style: const TextStyle(color: AppColors.brand700, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 4),
                Text(user?.companyName ?? '-', style: const TextStyle(fontSize: 12.5, color: AppColors.slate400)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (can(user?.role, 'users.manage'))
            _MenuTile(
              icon: Icons.people_outline,
              label: 'Manajemen User',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const UsersScreen())),
            ),
          const SizedBox(height: 8),
          _MenuTile(icon: Icons.logout, label: 'Keluar', danger: true, onTap: () => _logout(context)),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;
  const _MenuTile({required this.icon, required this.label, required this.onTap, this.danger = false});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.slate200)),
          child: Row(
            children: [
              Icon(icon, size: 20, color: danger ? AppColors.red600 : AppColors.slate600),
              const SizedBox(width: 12),
              Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: danger ? AppColors.red600 : AppColors.slate700)),
              const Spacer(),
              const Icon(Icons.chevron_right, size: 18, color: AppColors.slate300),
            ],
          ),
        ),
      ),
    );
  }
}
