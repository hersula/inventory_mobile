import '../core/formatters.dart';

enum TipeAkun { aset, kewajiban, modal, pendapatan, beban }

TipeAkun tipeAkunFromString(String v) {
  switch (v.toUpperCase()) {
    case 'ASET':
      return TipeAkun.aset;
    case 'KEWAJIBAN':
      return TipeAkun.kewajiban;
    case 'MODAL':
      return TipeAkun.modal;
    case 'PENDAPATAN':
      return TipeAkun.pendapatan;
    default:
      return TipeAkun.beban;
  }
}

String tipeAkunLabel(TipeAkun t) {
  switch (t) {
    case TipeAkun.aset:
      return 'Aset';
    case TipeAkun.kewajiban:
      return 'Kewajiban';
    case TipeAkun.modal:
      return 'Modal';
    case TipeAkun.pendapatan:
      return 'Pendapatan';
    case TipeAkun.beban:
      return 'Beban';
  }
}

class Akun {
  final int id;
  final String kode;
  final String nama;
  final TipeAkun tipe;
  final String saldoNormal; // "DEBIT" | "KREDIT"
  final bool isActive;

  Akun({required this.id, required this.kode, required this.nama, required this.tipe, required this.saldoNormal, required this.isActive});

  factory Akun.fromJson(Map<String, dynamic> json) => Akun(
        id: Formatters.toInt(json['id']),
        kode: json['kode'] ?? '',
        nama: json['nama'] ?? '',
        tipe: tipeAkunFromString(json['tipe'] ?? 'ASET'),
        saldoNormal: json['saldoNormal'] ?? 'DEBIT',
        isActive: json['isActive'] ?? true,
      );
}

class JurnalDetailLine {
  final int id;
  final Akun akun;
  final double debit;
  final double kredit;
  final String? keterangan;

  JurnalDetailLine({required this.id, required this.akun, required this.debit, required this.kredit, this.keterangan});

  factory JurnalDetailLine.fromJson(Map<String, dynamic> json) => JurnalDetailLine(
        id: Formatters.toInt(json['id']),
        akun: Akun.fromJson(json['akun']),
        debit: Formatters.toDouble(json['debit']),
        kredit: Formatters.toDouble(json['kredit']),
        keterangan: json['keterangan'],
      );
}

class JurnalEntry {
  final int id;
  final String nomor;
  final DateTime tanggal;
  final String? keterangan;
  final String referensiTipe; // manual | pengadaan | penjualan | pembayaran-hutang | pembayaran-piutang
  final String userName;
  final List<JurnalDetailLine> detail;

  JurnalEntry({
    required this.id,
    required this.nomor,
    required this.tanggal,
    this.keterangan,
    required this.referensiTipe,
    required this.userName,
    required this.detail,
  });

  double get totalDebit => detail.fold(0, (s, d) => s + d.debit);

  factory JurnalEntry.fromJson(Map<String, dynamic> json) => JurnalEntry(
        id: Formatters.toInt(json['id']),
        nomor: json['nomor'] ?? '',
        tanggal: DateTime.tryParse(json['tanggal'] ?? '') ?? DateTime.now(),
        keterangan: json['keterangan'],
        referensiTipe: json['referensiTipe'] ?? 'manual',
        userName: json['user']?['name'] ?? '-',
        detail: (json['detail'] as List? ?? []).map((e) => JurnalDetailLine.fromJson(e)).toList(),
      );
}

class OutstandingItem {
  final int id;
  final String nomor;
  final DateTime tanggal;
  final String pihak;
  final MetodeBayarPelunasanTarget metodeBayar;
  final double total;
  final double totalDibayar;
  final double sisa;

  OutstandingItem({
    required this.id,
    required this.nomor,
    required this.tanggal,
    required this.pihak,
    required this.metodeBayar,
    required this.total,
    required this.totalDibayar,
    required this.sisa,
  });

  factory OutstandingItem.fromJson(Map<String, dynamic> json) => OutstandingItem(
        id: Formatters.toInt(json['id']),
        nomor: json['nomor'] ?? '',
        tanggal: DateTime.tryParse(json['tanggal'] ?? '') ?? DateTime.now(),
        pihak: json['pihak'] ?? '-',
        metodeBayar: json['metodeBayar'] == 'KREDIT' ? MetodeBayarPelunasanTarget.kredit : MetodeBayarPelunasanTarget.tempo,
        total: Formatters.toDouble(json['total']),
        totalDibayar: Formatters.toDouble(json['totalDibayar']),
        sisa: Formatters.toDouble(json['sisa']),
      );
}

enum MetodeBayarPelunasanTarget { kredit, tempo }

class RiwayatPembayaran {
  final int id;
  final String nomor;
  final DateTime tanggal;
  final String tipe; // HUTANG | PIUTANG
  final double jumlah;
  final String metodeBayar; // TUNAI | TRANSFER
  final String? keterangan;
  final String userName;
  final String? referensiNomor;
  final String? referensiPihak;

  RiwayatPembayaran({
    required this.id,
    required this.nomor,
    required this.tanggal,
    required this.tipe,
    required this.jumlah,
    required this.metodeBayar,
    this.keterangan,
    required this.userName,
    this.referensiNomor,
    this.referensiPihak,
  });

  factory RiwayatPembayaran.fromJson(Map<String, dynamic> json) => RiwayatPembayaran(
        id: Formatters.toInt(json['id']),
        nomor: json['nomor'] ?? '',
        tanggal: DateTime.tryParse(json['tanggal'] ?? '') ?? DateTime.now(),
        tipe: json['tipe'] ?? 'HUTANG',
        jumlah: Formatters.toDouble(json['jumlah']),
        metodeBayar: json['metodeBayar'] ?? 'TUNAI',
        keterangan: json['keterangan'],
        userName: json['user']?['name'] ?? '-',
        referensiNomor: json['referensi']?['nomor'],
        referensiPihak: json['referensi']?['pihak'],
      );
}
