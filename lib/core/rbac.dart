/// Port 1:1 dari src/lib/rbac.ts (versi web) supaya perilaku menu & tombol
/// di mobile konsisten dengan web. Kalau rbac.ts di backend berubah, ubah
/// juga peta di sini.
enum AppRole { admin, manager, staff }

AppRole roleFromString(String value) {
  switch (value.toUpperCase()) {
    case 'ADMIN':
      return AppRole.admin;
    case 'MANAGER':
      return AppRole.manager;
    default:
      return AppRole.staff;
  }
}

String roleLabel(AppRole role) {
  switch (role) {
    case AppRole.admin:
      return 'Administrator';
    case AppRole.manager:
      return 'Manajer';
    case AppRole.staff:
      return 'Staff';
  }
}

const Map<AppRole, Set<String>> _rolePermissions = {
  AppRole.admin: {
    'dashboard.view',
    'barang.view',
    'barang.manage',
    'pengadaan.view',
    'pengadaan.manage',
    'penjualan.view',
    'penjualan.manage',
    'retur.view',
    'retur.manage',
    'akuntansi.view',
    'akuntansi.manage',
    'users.manage',
  },
  AppRole.manager: {
    'dashboard.view',
    'barang.view',
    'barang.manage',
    'pengadaan.view',
    'pengadaan.manage',
    'penjualan.view',
    'penjualan.manage',
    'retur.view',
    'retur.manage',
    'akuntansi.view',
    'akuntansi.manage',
  },
  AppRole.staff: {
    'dashboard.view',
    'barang.view',
    'pengadaan.view',
    'pengadaan.manage',
    'penjualan.view',
    'penjualan.manage',
    'retur.view',
    'retur.manage',
  },
};

bool can(AppRole? role, String permission) {
  if (role == null) return false;
  return _rolePermissions[role]?.contains(permission) ?? false;
}
