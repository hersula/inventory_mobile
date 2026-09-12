import '../core/formatters.dart';

/// Port dari model StokOpname/StokOpnameDetail backend (lihat
/// prisma/schema.prisma & api/opname di repo inventory_dashboard) — satu sesi
/// opname mencakup barang manapun yang benar-benar diinput "stok fisik"-nya,
/// stok langsung disesuaikan ke hasil hitung fisik saat disimpan.
class StokOpnameDetailLine {
  final int barangId;
  final String barangNama;
  final String barangKode;
  final String satuan;
  final int stokSistem;
  final int stokFisik;
  final int selisih;
  final double hargaBeli;
  final double nilaiSelisih;

  StokOpnameDetailLine({
    required this.barangId,
    required this.barangNama,
    required this.barangKode,
    required this.satuan,
    required this.stokSistem,
    required this.stokFisik,
    required this.selisih,
    required this.hargaBeli,
    required this.nilaiSelisih,
  });

  factory StokOpnameDetailLine.fromJson(Map<String, dynamic> json) => StokOpnameDetailLine(
        barangId: Formatters.toInt(json['barangId']),
        barangNama: json['barang']?['nama'] ?? '-',
        barangKode: json['barang']?['kode'] ?? '',
        satuan: json['barang']?['satuan'] ?? 'pcs',
        stokSistem: Formatters.toInt(json['stokSistem']),
        stokFisik: Formatters.toInt(json['stokFisik']),
        selisih: Formatters.toInt(json['selisih']),
        hargaBeli: Formatters.toDouble(json['hargaBeli']),
        nilaiSelisih: Formatters.toDouble(json['nilaiSelisih']),
      );
}

class StokOpname {
  final int id;
  final String nomor;
  final DateTime tanggal;
  final String? catatan;
  final double totalNilaiSelisih;
  final String userName;
  final List<StokOpnameDetailLine> detail;

  StokOpname({
    required this.id,
    required this.nomor,
    required this.tanggal,
    this.catatan,
    required this.totalNilaiSelisih,
    required this.userName,
    required this.detail,
  });

  List<StokOpnameDetailLine> get berselisih => detail.where((d) => d.selisih != 0).toList();

  factory StokOpname.fromJson(Map<String, dynamic> json) => StokOpname(
        id: Formatters.toInt(json['id']),
        nomor: json['nomor'] ?? '',
        tanggal: DateTime.tryParse(json['tanggal'] ?? '') ?? DateTime.now(),
        catatan: json['catatan'],
        totalNilaiSelisih: Formatters.toDouble(json['totalNilaiSelisih']),
        userName: json['user']?['name'] ?? '-',
        detail: (json['detail'] as List? ?? []).map((e) => StokOpnameDetailLine.fromJson(e)).toList(),
      );
}
