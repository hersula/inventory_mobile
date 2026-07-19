import '../core/rbac.dart';
import '../core/formatters.dart';

class AppUser {
  final int id;
  final String name;
  final String email;
  final AppRole role;
  final int companyId;
  final String companyName;
  final bool active;
  final DateTime? createdAt;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.companyId,
    required this.companyName,
    this.active = true,
    this.createdAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: Formatters.toInt(json['id']),
        name: json['name'] ?? '',
        email: json['email'] ?? '',
        role: roleFromString(json['role'] ?? 'STAFF'),
        companyId: Formatters.toInt(json['companyId']),
        companyName: json['companyName'] ?? '',
        active: json['active'] ?? true,
        createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      );
}

/// Dipakai khusus untuk daftar user di modul Manajemen User (field-nya
/// sedikit beda: tidak ada companyName karena implisit satu perusahaan).
class ManagedUser {
  final int id;
  final String name;
  final String email;
  final AppRole role;
  final bool active;
  final DateTime createdAt;

  ManagedUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.active,
    required this.createdAt,
  });

  factory ManagedUser.fromJson(Map<String, dynamic> json) => ManagedUser(
        id: Formatters.toInt(json['id']),
        name: json['name'] ?? '',
        email: json['email'] ?? '',
        role: roleFromString(json['role'] ?? 'STAFF'),
        active: json['active'] ?? true,
        createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      );
}
