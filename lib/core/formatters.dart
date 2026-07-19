import 'package:intl/intl.dart';

class Formatters {
  static final _currency = NumberFormat.decimalPattern('id_ID');
  static final _dateShort = DateFormat('d MMM yyyy', 'id_ID');
  static final _dateLong = DateFormat('d MMMM yyyy', 'id_ID');

  static String rupiah(num value) => 'Rp ${_currency.format(value.round())}';

  static String dateShort(DateTime date) => _dateShort.format(date);

  static String dateLong(DateTime date) => _dateLong.format(date);

  static double toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  static int toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }
}
