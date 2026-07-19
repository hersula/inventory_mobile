import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/formatters.dart';
import '../../core/api_exception.dart';
import '../../models/transaksi.dart';
import '../../services/penjualan_service.dart';
import '../../widgets/state_views.dart';
import '../../widgets/status_badge.dart';

class PenjualanDetailSheet extends StatefulWidget {
  final int id;
  const PenjualanDetailSheet({super.key, required this.id});

  @override
  State<PenjualanDetailSheet> createState() => _PenjualanDetailSheetState();
}

class _PenjualanDetailSheetState extends State<PenjualanDetailSheet> {
  final _service = PenjualanService();
  Penjualan? _data;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final d = await _service.detail(widget.id);
      setState(() => _data = d);
    } catch (e) {
      setState(() => _error = e is ApiException ? e.message : 'Gagal memuat detail');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(children: [
                Expanded(child: Text('Detail Transaksi ${_data?.nomor ?? ""}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ]),
            ),
            const Divider(height: 1),
            Expanded(
              child: _error != null
                  ? ErrorView(message: _error!, onRetry: _load)
                  : _data == null
                      ? const LoadingView()
                      : ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.all(20),
                          children: [
                            Row(children: [
                              Expanded(child: _InfoBlock(label: 'Tanggal', value: Formatters.dateLong(_data!.tanggal))),
                              Expanded(child: _InfoBlock(label: 'Pelanggan', value: _data!.pelanggan?.nama ?? 'Umum')),
                            ]),
                            const SizedBox(height: 8),
                            Row(children: [
                              StatusBadge(metodeBayarLabel(_data!.metodeBayar),
                                  tone: isLunasDiMuka(_data!.metodeBayar) ? BadgeTone.green : BadgeTone.amber),
                              if (_data!.sisa > 0) ...[
                                const SizedBox(width: 8),
                                Text('Sisa ${Formatters.rupiah(_data!.sisa)}',
                                    style: const TextStyle(color: AppColors.red500, fontWeight: FontWeight.w600, fontSize: 12.5)),
                              ],
                            ]),
                            const SizedBox(height: 16),
                            ..._data!.detail.map((d) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  child: Row(children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(d.barang.nama, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                                          Text('${d.qty} x ${Formatters.rupiah(d.hargaSatuan)}',
                                              style: const TextStyle(fontSize: 12, color: AppColors.slate400)),
                                        ],
                                      ),
                                    ),
                                    Text(Formatters.rupiah(d.subtotal), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                  ]),
                                )),
                            const Divider(height: 24),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(color: AppColors.slate50, borderRadius: BorderRadius.circular(12)),
                              child: Column(children: [
                                _Row('Subtotal', Formatters.rupiah(_data!.subtotal)),
                                if (_data!.diskonNominal > 0) _Row('Diskon (${_data!.diskonPersen.toStringAsFixed(0)}%)', '- ${Formatters.rupiah(_data!.diskonNominal)}'),
                                if (_data!.ppn > 0) _Row('PPN 11%', '+ ${Formatters.rupiah(_data!.ppn)}'),
                                const Divider(),
                                _Row('Total', Formatters.rupiah(_data!.total), bold: true),
                              ]),
                            ),
                            if (_data!.catatan != null && _data!.catatan!.isNotEmpty) ...[
                              const SizedBox(height: 14),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: AppColors.slate50, borderRadius: BorderRadius.circular(10)),
                                child: Text('Catatan: ${_data!.catatan}', style: const TextStyle(fontSize: 12.5, color: AppColors.slate600)),
                              ),
                            ],
                            const SizedBox(height: 20),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  final String label;
  final String value;
  const _InfoBlock({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.slate400)),
        Text(value, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  const _Row(this.label, this.value, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: bold ? 14 : 12.5,
      fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
      color: bold ? AppColors.slate800 : AppColors.slate500,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: style), Text(value, style: style)]),
    );
  }
}
