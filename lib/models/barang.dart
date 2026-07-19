import '../core/formatters.dart';

class Kategori {
  final int id;
  final String nama;

  Kategori({required this.id, required this.nama});

  factory Kategori.fromJson(Map<String, dynamic> json) =>
      Kategori(id: Formatters.toInt(json['id']), nama: json['nama'] ?? '');
}

class Barang {
  final int id;
  final String kode;
  final String nama;
  final int? kategoriId;
  final Kategori? kategori;
  final String satuan;
  final double hargaBeli;
  final double hargaJual;
  final int stok;
  final int stokMinimum;
  final String? deskripsi;

  Barang({
    required this.id,
    required this.kode,
    required this.nama,
    this.kategoriId,
    this.kategori,
    required this.satuan,
    required this.hargaBeli,
    required this.hargaJual,
    required this.stok,
    required this.stokMinimum,
    this.deskripsi,
  });

  bool get stokMenipis => stok <= stokMinimum;

  factory Barang.fromJson(Map<String, dynamic> json) => Barang(
        id: Formatters.toInt(json['id']),
        kode: json['kode'] ?? '',
        nama: json['nama'] ?? '',
        kategoriId: json['kategoriId'] != null ? Formatters.toInt(json['kategoriId']) : null,
        kategori: json['kategori'] != null ? Kategori.fromJson(json['kategori']) : null,
        satuan: json['satuan'] ?? 'pcs',
        hargaBeli: Formatters.toDouble(json['hargaBeli']),
        hargaJual: Formatters.toDouble(json['hargaJual']),
        stok: Formatters.toInt(json['stok']),
        stokMinimum: Formatters.toInt(json['stokMinimum']),
        deskripsi: json['deskripsi'],
      );

  Map<String, dynamic> toJson() => {
        'kode': kode,
        'nama': nama,
        'kategoriId': kategoriId,
        'satuan': satuan,
        'hargaBeli': hargaBeli,
        'hargaJual': hargaJual,
        'stok': stok,
        'stokMinimum': stokMinimum,
        'deskripsi': deskripsi,
      };
}
