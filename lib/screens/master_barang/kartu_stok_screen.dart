import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/formatters.dart';
import '../../core/api_exception.dart';
import '../../models/barang.dart';
import '../../models/kartu_stok.dart';
import '../../services/laporan_service.dart';
import '../../widgets/state_views.dart';
import '../../widgets/status_badge.dart';

/// Log aktivitas stok satu barang (masuk dari Pengadaan/Retur Penjualan,
/// keluar dari Penjualan/Retur Pembelian) — port dari halaman /laporan-stok
/// versi web, dibuka dari tombol ikon riwayat di Master Barang.
class KartuStokScreen extends StatefulWidget {
  final Barang barang;
  const KartuStokScreen({super.key, required this.barang});

  @override
  State<KartuStokScreen> createState() => _KartuStokScreenState();
}

class _KartuStokScreenState extends State<KartuStokScreen> {
  final _service = LaporanService();
  DateTime? _start;
  DateTime? _end;
  KartuStok? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String? _isoDate(DateTime? d) => d?.toIso8601String().split('T').first;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _service.kartuStok(widget.barang.id, start: _isoDate(_start), end: _isoDate(_end));
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e is ApiException ? e.message : 'Gagal memuat kartu stok';
        _loading = false;
      });
    }
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? _start : _end) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _start = picked;
      } else {
        _end = picked;
      }
    });
    _load();
  }

  void _clearFilter() {
    setState(() {
      _start = null;
      _end = null;
    });
    _load();
  }

  BadgeTone _tone(TipePergerakan t) {
    switch (t) {
      case TipePergerakan.pengadaan:
        return BadgeTone.green;
      case TipePergerakan.penjualan:
        return BadgeTone.amber;
      case TipePergerakan.returPembelian:
        return BadgeTone.red;
      case TipePergerakan.returPenjualan:
        return BadgeTone.brand;
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalMasuk = _data?.pergerakan.fold<int>(0, (s, p) => s + p.masuk) ?? 0;
    final totalKeluar = _data?.pergerakan.fold<int>(0, (s, p) => s + p.keluar) ?? 0;

    return Scaffold(
      appBar: AppBar(title: Text('Kartu Stok · ${widget.barang.nama}')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickDate(isStart: true),
                  icon: const Icon(Icons.calendar_today_outlined, size: 16),
                  label: Text(_start == null ? 'Dari Tanggal' : Formatters.dateShort(_start!)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickDate(isStart: false),
                  icon: const Icon(Icons.calendar_today_outlined, size: 16),
                  label: Text(_end == null ? 'Sampai Tanggal' : Formatters.dateShort(_end!)),
                ),
              ),
              if (_start != null || _end != null)
                IconButton(icon: const Icon(Icons.close, size: 18), onPressed: _clearFilter, tooltip: 'Hapus filter tanggal'),
            ]),
            const SizedBox(height: 14),
            if (_loading)
              const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: LoadingView())
            else if (_error != null)
              ErrorView(message: _error!, onRetry: _load)
            else if (_data != null) ...[
              Row(children: [
                Expanded(
                  child: _SummaryCard(label: 'Stok Saat Ini', value: '${_data!.stokSaatIni} ${_data!.satuan}', color: AppColors.slate800),
                ),
                const SizedBox(width: 8),
                Expanded(child: _SummaryCard(label: 'Total Masuk', value: '+$totalMasuk', color: AppColors.emerald600)),
                const SizedBox(width: 8),
                Expanded(child: _SummaryCard(label: 'Total Keluar', value: '-$totalKeluar', color: AppColors.red600)),
              ]),
              const SizedBox(height: 16),
              const Text('Log Aktivitas', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 8),
              if (_start != null) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(color: AppColors.slate50, borderRadius: BorderRadius.circular(10)),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Saldo Awal Periode', style: TextStyle(fontSize: 12.5, color: AppColors.slate500, fontStyle: FontStyle.italic)),
                    Text('${_data!.saldoAwal}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  ]),
                ),
              ],
              if (_data!.pergerakan.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('Tidak ada pergerakan stok pada periode ini.', style: TextStyle(color: AppColors.slate400))),
                )
              else
                ..._data!.pergerakan.map((p) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.slate200)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.nomor, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                                  Text('${Formatters.dateShort(p.tanggal)} · ${p.pihak}', style: const TextStyle(fontSize: 11.5, color: AppColors.slate500)),
                                ],
                              ),
                            ),
                            StatusBadge(tipePergerakanLabel(p.tipe), tone: _tone(p.tipe)),
                          ]),
                          const Divider(height: 16),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Text(
                              p.masuk > 0 ? 'Masuk +${p.masuk}' : 'Keluar -${p.keluar}',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12.5,
                                color: p.masuk > 0 ? AppColors.emerald600 : AppColors.red600,
                              ),
                            ),
                            Text('Saldo: ${p.saldo}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                          ]),
                        ],
                      ),
                    )),
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SummaryCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.slate200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10.5, color: AppColors.slate400)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}
