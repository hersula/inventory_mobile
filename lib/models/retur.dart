import '../core/formatters.dart';

/// Port dari model Retur backend (lihat prisma/schema.prisma & api/retur di
/// repo inventory_dashboard) — PEMBELIAN = retur ke supplier (dari transaksi
/// Pengadaan), PENJUALAN = retur dari pelanggan (dari transaksi Penjualan).
enum JenisRetur { pembelian, penjualan }

String jenisReturToString(JenisRetur j) => j == JenisRetur.pembelian ? 'PEMBELIAN' : 'PENJUALAN';

JenisRetur jenisReturFromString(String v) => v.toUpperCase() == 'PEMBELIAN' ? JenisRetur.pembelian : JenisRetur.penjualan;

class ReturDetailLine {
  final int barangId;
  final String barangNama;
  final String barangKode;
  final int qty;
  final double hargaSatuan;
  final double subtotal;

  ReturDetailLine({
    required this.barangId,
    required this.barangNama,
    required this.barangKode,
    required this.qty,
    required this.hargaSatuan,
    required this.subtotal,
  });

  factory ReturDetailLine.fromJson(Map<String, dynamic> json) => ReturDetailLine(
        barangId: Formatters.toInt(json['barangId']),
        barangNama: json['barang']?['nama'] ?? '-',
        barangKode: json['barang']?['kode'] ?? '',
        qty: Formatters.toInt(json['qty']),
        hargaSatuan: Formatters.toDouble(json['hargaSatuan']),
        subtotal: Formatters.toDouble(json['subtotal']),
      );
}

class Retur {
  final int id;
  final String nomor;
  final DateTime tanggal;
  final JenisRetur jenis;
  final String? catatan;
  final double total;
  final String userName;
  final String? referensiNomor;
  final String? referensiPihak;
  final List<ReturDetailLine> detail;

  Retur({
    required this.id,
    required this.nomor,
    required this.tanggal,
    required this.jenis,
    this.catatan,
    required this.total,
    required this.userName,
    this.referensiNomor,
    this.referensiPihak,
    required this.detail,
  });

  factory Retur.fromJson(Map<String, dynamic> json) => Retur(
        id: Formatters.toInt(json['id']),
        nomor: json['nomor'] ?? '',
        tanggal: DateTime.tryParse(json['tanggal'] ?? '') ?? DateTime.now(),
        jenis: jenisReturFromString(json['jenis'] ?? 'PEMBELIAN'),
        catatan: json['catatan'],
        total: Formatters.toDouble(json['total']),
        userName: json['user']?['name'] ?? '-',
        referensiNomor: json['referensi']?['nomor'],
        referensiPihak: json['referensi']?['pihak'],
        detail: (json['detail'] as List? ?? []).map((e) => ReturDetailLine.fromJson(e)).toList(),
      );
}

/// Ringkasan transaksi Pengadaan/Penjualan untuk dropdown "pilih transaksi
/// asal" di form Retur — dibangun manual dari Pengadaan/Penjualan yang sudah
/// ada (lihat ReturFormSheet), bukan hasil parse JSON tersendiri.
class TrxRingkas {
  final int id;
  final String nomor;
  final DateTime tanggal;
  final String pihak;

  TrxRingkas({required this.id, required this.nomor, required this.tanggal, required this.pihak});
}

/// Hasil GET /api/retur/sumber — detail item dari SATU transaksi asal,
/// lengkap dengan sisa qty yang masih bisa diretur.
class SumberItem {
  final int barangId;
  final String kode;
  final String nama;
  final String satuan;
  final int qtyAsal;
  final double hargaSatuan;
  final int sudahDiretur;
  final int sisaBisaDiretur;

  SumberItem({
    required this.barangId,
    required this.kode,
    required this.nama,
    required this.satuan,
    required this.qtyAsal,
    required this.hargaSatuan,
    required this.sudahDiretur,
    required this.sisaBisaDiretur,
  });

  factory SumberItem.fromJson(Map<String, dynamic> json) => SumberItem(
        barangId: Formatters.toInt(json['barangId']),
        kode: json['kode'] ?? '',
        nama: json['nama'] ?? '',
        satuan: json['satuan'] ?? 'pcs',
        qtyAsal: Formatters.toInt(json['qtyAsal']),
        hargaSatuan: Formatters.toDouble(json['hargaSatuan']),
        sudahDiretur: Formatters.toInt(json['sudahDiretur']),
        sisaBisaDiretur: Formatters.toInt(json['sisaBisaDiretur']),
      );
}

class SumberRetur {
  final String nomor;
  final DateTime tanggal;
  final String pihak;
  final List<SumberItem> items;

  SumberRetur({required this.nomor, required this.tanggal, required this.pihak, required this.items});

  factory SumberRetur.fromJson(Map<String, dynamic> json) => SumberRetur(
        nomor: json['nomor'] ?? '',
        tanggal: DateTime.tryParse(json['tanggal'] ?? '') ?? DateTime.now(),
        pihak: json['pihak'] ?? '-',
        items: (json['items'] as List? ?? []).map((e) => SumberItem.fromJson(e)).toList(),
      );
}
