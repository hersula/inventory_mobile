import '../core/formatters.dart';
import 'barang.dart';
import 'partner.dart';

enum MetodeBayar { tunai, transfer, kredit, tempo }

MetodeBayar metodeBayarFromString(String value) {
  switch (value.toUpperCase()) {
    case 'TUNAI':
      return MetodeBayar.tunai;
    case 'TRANSFER':
      return MetodeBayar.transfer;
    case 'KREDIT':
      return MetodeBayar.kredit;
    case 'TEMPO':
      return MetodeBayar.tempo;
    default:
      return MetodeBayar.tunai;
  }
}

String metodeBayarToString(MetodeBayar m) => m.name.toUpperCase();

String metodeBayarLabel(MetodeBayar m) {
  switch (m) {
    case MetodeBayar.tunai:
      return 'Tunai';
    case MetodeBayar.transfer:
      return 'Transfer Bank';
    case MetodeBayar.kredit:
      return 'Kredit';
    case MetodeBayar.tempo:
      return 'Tempo';
  }
}

bool isLunasDiMuka(MetodeBayar m) => m == MetodeBayar.tunai || m == MetodeBayar.transfer;

class ItemDetail {
  final int id;
  final Barang barang;
  final int qty;
  final double hargaSatuan;
  final double subtotal;

  ItemDetail({required this.id, required this.barang, required this.qty, required this.hargaSatuan, required this.subtotal});

  factory ItemDetail.fromJson(Map<String, dynamic> json) => ItemDetail(
        id: Formatters.toInt(json['id']),
        barang: Barang.fromJson(json['barang']),
        qty: Formatters.toInt(json['qty']),
        hargaSatuan: Formatters.toDouble(json['hargaSatuan']),
        subtotal: Formatters.toDouble(json['subtotal']),
      );
}

class ItemInput {
  int? barangId;
  String barangLabel;
  int qty;
  double hargaSatuan;

  ItemInput({this.barangId, this.barangLabel = '', this.qty = 1, this.hargaSatuan = 0});

  Map<String, dynamic> toJson() => {'barangId': barangId, 'qty': qty, 'hargaSatuan': hargaSatuan};
}

class Pengadaan {
  final int id;
  final String nomor;
  final DateTime tanggal;
  final Supplier? supplier;
  final String userName;
  final MetodeBayar metodeBayar;
  final double subtotal;
  final double diskonPersen;
  final double diskonNominal;
  final double ppn;
  final double total;
  final double totalDibayar;
  final double sisa;
  final String? catatan;
  final List<ItemDetail> detail;

  Pengadaan({
    required this.id,
    required this.nomor,
    required this.tanggal,
    this.supplier,
    required this.userName,
    required this.metodeBayar,
    required this.subtotal,
    required this.diskonPersen,
    required this.diskonNominal,
    required this.ppn,
    required this.total,
    required this.totalDibayar,
    required this.sisa,
    this.catatan,
    required this.detail,
  });

  factory Pengadaan.fromJson(Map<String, dynamic> json) => Pengadaan(
        id: Formatters.toInt(json['id']),
        nomor: json['nomor'] ?? '',
        tanggal: DateTime.tryParse(json['tanggal'] ?? '') ?? DateTime.now(),
        supplier: json['supplier'] != null ? Supplier.fromJson(json['supplier']) : null,
        userName: json['user']?['name'] ?? '-',
        metodeBayar: metodeBayarFromString(json['metodeBayar'] ?? 'TUNAI'),
        subtotal: Formatters.toDouble(json['subtotal']),
        diskonPersen: Formatters.toDouble(json['diskonPersen']),
        diskonNominal: Formatters.toDouble(json['diskonNominal']),
        ppn: Formatters.toDouble(json['ppn']),
        total: Formatters.toDouble(json['total']),
        totalDibayar: Formatters.toDouble(json['totalDibayar']),
        sisa: Formatters.toDouble(json['sisa']),
        catatan: json['catatan'],
        detail: (json['detail'] as List? ?? []).map((e) => ItemDetail.fromJson(e)).toList(),
      );
}

class Penjualan {
  final int id;
  final String nomor;
  final DateTime tanggal;
  final Pelanggan? pelanggan;
  final String userName;
  final MetodeBayar metodeBayar;
  final double subtotal;
  final double diskonPersen;
  final double diskonNominal;
  final double ppn;
  final double total;
  final double totalDibayar;
  final double sisa;
  final String? catatan;
  final List<ItemDetail> detail;

  Penjualan({
    required this.id,
    required this.nomor,
    required this.tanggal,
    this.pelanggan,
    required this.userName,
    required this.metodeBayar,
    required this.subtotal,
    required this.diskonPersen,
    required this.diskonNominal,
    required this.ppn,
    required this.total,
    required this.totalDibayar,
    required this.sisa,
    this.catatan,
    required this.detail,
  });

  factory Penjualan.fromJson(Map<String, dynamic> json) => Penjualan(
        id: Formatters.toInt(json['id']),
        nomor: json['nomor'] ?? '',
        tanggal: DateTime.tryParse(json['tanggal'] ?? '') ?? DateTime.now(),
        pelanggan: json['pelanggan'] != null ? Pelanggan.fromJson(json['pelanggan']) : null,
        userName: json['user']?['name'] ?? '-',
        metodeBayar: metodeBayarFromString(json['metodeBayar'] ?? 'TUNAI'),
        subtotal: Formatters.toDouble(json['subtotal']),
        diskonPersen: Formatters.toDouble(json['diskonPersen']),
        diskonNominal: Formatters.toDouble(json['diskonNominal']),
        ppn: Formatters.toDouble(json['ppn']),
        total: Formatters.toDouble(json['total']),
        totalDibayar: Formatters.toDouble(json['totalDibayar']),
        sisa: Formatters.toDouble(json['sisa']),
        catatan: json['catatan'],
        detail: (json['detail'] as List? ?? []).map((e) => ItemDetail.fromJson(e)).toList(),
      );
}
