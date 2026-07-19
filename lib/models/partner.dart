import '../core/formatters.dart';

class Supplier {
  final int id;
  final String nama;
  final String? alamat;
  final String? telepon;
  final String? email;

  Supplier({required this.id, required this.nama, this.alamat, this.telepon, this.email});

  factory Supplier.fromJson(Map<String, dynamic> json) => Supplier(
        id: Formatters.toInt(json['id']),
        nama: json['nama'] ?? '',
        alamat: json['alamat'],
        telepon: json['telepon'],
        email: json['email'],
      );
}

class Pelanggan {
  final int id;
  final String nama;
  final String? alamat;
  final String? telepon;

  Pelanggan({required this.id, required this.nama, this.alamat, this.telepon});

  factory Pelanggan.fromJson(Map<String, dynamic> json) => Pelanggan(
        id: Formatters.toInt(json['id']),
        nama: json['nama'] ?? '',
        alamat: json['alamat'],
        telepon: json['telepon'],
      );
}
