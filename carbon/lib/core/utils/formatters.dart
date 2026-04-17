import 'package:intl/intl.dart';

class AppFormatters {
  static final NumberFormat _currency = NumberFormat.currency(
    locale: 'en_IN',
    symbol: 'Rs ',
    decimalDigits: 2,
  );

  static String currency(num value) => _currency.format(value);

  static String date(DateTime value) {
    return DateFormat('dd MMM yyyy').format(value);
  }
}
