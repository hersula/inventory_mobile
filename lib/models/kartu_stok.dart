import '../core/formatters.dart';

/// Port dari response GET /api/laporan/kartu-stok (lihat repo inventory_dashboard) —
/// log kronologis pergerakan stok satu barang, digabung dari Pengadaan,
/// Penjualan, dan Retur.
enum TipePergerakan { pengadaan, penjualan, returPembelian, returPenjualan }

TipePergerakan tipePergerakanFromString(String v) {
  switch (v) {
    case 'PENGADAAN':
      return TipePergerakan.pengadaan;
    case 'PENJUALAN':
      return TipePergerakan.penjualan;
    case 'RETUR_PEMBELIAN':
      return TipePergerakan.returPembelian;
    default:
      return TipePergerakan.returPenjualan;
  }
}

String tipePergerakanLabel(TipePergerakan t) {
  switch (t) {
    case TipePergerakan.pengadaan:
      return 'Pengadaan';
    case TipePergerakan.penjualan:
      return 'Penjualan';
    case TipePergerakan.returPembelian:
      return 'Retur Pembelian';
    case TipePergerakan.returPenjualan:
      return 'Retur Penjualan';
  }
}

class PergerakanStok {
  final DateTime tanggal;
  final TipePergerakan tipe;
  final String nomor;
  final String pihak;
  final String? keterangan;
  final int masuk;
  final int keluar;
  final int saldo;

  PergerakanStok({
    required this.tanggal,
    required this.tipe,
    required this.nomor,
    required this.pihak,
    this.keterangan,
    required this.masuk,
    required this.keluar,
    required this.saldo,
  });

  factory PergerakanStok.fromJson(Map<String, dynamic> json) => PergerakanStok(
        tanggal: DateTime.tryParse(json['tanggal'] ?? '') ?? DateTime.now(),
        tipe: tipePergerakanFromString(json['tipe'] ?? 'PENGADAAN'),
        nomor: json['nomor'] ?? '',
        pihak: json['pihak'] ?? '-',
        keterangan: json['keterangan'],
        masuk: Formatters.toInt(json['masuk']),
        keluar: Formatters.toInt(json['keluar']),
        saldo: Formatters.toInt(json['saldo']),
      );
}

class KartuStok {
  final int barangId;
  final String kode;
  final String nama;
  final String satuan;
  final int stokSaatIni;
  final int saldoAwal;
  final List<PergerakanStok> pergerakan;

  KartuStok({
    required this.barangId,
    required this.kode,
    required this.nama,
    required this.satuan,
    required this.stokSaatIni,
    required this.saldoAwal,
    required this.pergerakan,
  });

  factory KartuStok.fromJson(Map<String, dynamic> json) => KartuStok(
        barangId: Formatters.toInt(json['barang']?['id']),
        kode: json['barang']?['kode'] ?? '',
        nama: json['barang']?['nama'] ?? '',
        satuan: json['barang']?['satuan'] ?? 'pcs',
        stokSaatIni: Formatters.toInt(json['barang']?['stokSaatIni']),
        saldoAwal: Formatters.toInt(json['saldoAwal']),
        pergerakan: (json['pergerakan'] as List? ?? []).map((e) => PergerakanStok.fromJson(e)).toList(),
      );
}
