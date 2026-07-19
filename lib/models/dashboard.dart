import '../core/formatters.dart';

class LowStockItem {
  final int id;
  final String kode;
  final String nama;
  final int stok;
  final int stokMinimum;

  LowStockItem({required this.id, required this.kode, required this.nama, required this.stok, required this.stokMinimum});

  factory LowStockItem.fromJson(Map<String, dynamic> json) => LowStockItem(
        id: Formatters.toInt(json['id']),
        kode: json['kode'] ?? '',
        nama: json['nama'] ?? '',
        stok: Formatters.toInt(json['stok']),
        stokMinimum: Formatters.toInt(json['stokMinimum']),
      );
}

class MonthlyPoint {
  final String bulan;
  final double penjualan;
  final double pengadaan;

  MonthlyPoint({required this.bulan, required this.penjualan, required this.pengadaan});

  factory MonthlyPoint.fromJson(Map<String, dynamic> json) => MonthlyPoint(
        bulan: json['bulan'] ?? '',
        penjualan: Formatters.toDouble(json['penjualan']),
        pengadaan: Formatters.toDouble(json['pengadaan']),
      );
}

class KategoriChartItem {
  final String nama;
  final int jumlah;

  KategoriChartItem({required this.nama, required this.jumlah});

  factory KategoriChartItem.fromJson(Map<String, dynamic> json) =>
      KategoriChartItem(nama: json['nama'] ?? '', jumlah: Formatters.toInt(json['jumlah']));
}

class TopBarangItem {
  final String nama;
  final int terjual;

  TopBarangItem({required this.nama, required this.terjual});

  factory TopBarangItem.fromJson(Map<String, dynamic> json) =>
      TopBarangItem(nama: json['nama'] ?? '', terjual: Formatters.toInt(json['terjual']));
}

class DashboardStats {
  final int totalBarang;
  final int totalStok;
  final double totalNilaiStok;
  final int lowStockCount;
  final List<LowStockItem> lowStockItems;
  final double penjualanBulanIniTotal;
  final int penjualanBulanIniJumlah;
  final double pengadaanBulanIniTotal;
  final int pengadaanBulanIniJumlah;
  final List<MonthlyPoint> chartMonthly;
  final List<KategoriChartItem> kategoriChart;
  final List<TopBarangItem> topBarang;

  DashboardStats({
    required this.totalBarang,
    required this.totalStok,
    required this.totalNilaiStok,
    required this.lowStockCount,
    required this.lowStockItems,
    required this.penjualanBulanIniTotal,
    required this.penjualanBulanIniJumlah,
    required this.pengadaanBulanIniTotal,
    required this.pengadaanBulanIniJumlah,
    required this.chartMonthly,
    required this.kategoriChart,
    required this.topBarang,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) => DashboardStats(
        totalBarang: Formatters.toInt(json['totalBarang']),
        totalStok: Formatters.toInt(json['totalStok']),
        totalNilaiStok: Formatters.toDouble(json['totalNilaiStok']),
        lowStockCount: Formatters.toInt(json['lowStockCount']),
        lowStockItems: (json['lowStockItems'] as List? ?? []).map((e) => LowStockItem.fromJson(e)).toList(),
        penjualanBulanIniTotal: Formatters.toDouble(json['penjualanBulanIni']?['total']),
        penjualanBulanIniJumlah: Formatters.toInt(json['penjualanBulanIni']?['jumlahTransaksi']),
        pengadaanBulanIniTotal: Formatters.toDouble(json['pengadaanBulanIni']?['total']),
        pengadaanBulanIniJumlah: Formatters.toInt(json['pengadaanBulanIni']?['jumlahTransaksi']),
        chartMonthly: (json['chartMonthly'] as List? ?? []).map((e) => MonthlyPoint.fromJson(e)).toList(),
        kategoriChart: (json['kategoriChart'] as List? ?? []).map((e) => KategoriChartItem.fromJson(e)).toList(),
        topBarang: (json['topBarang'] as List? ?? []).map((e) => TopBarangItem.fromJson(e)).toList(),
      );
}
