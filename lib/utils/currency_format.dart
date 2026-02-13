import 'package:intl/intl.dart';

class CurrencyFormat {
  /// Mengubah angka menjadi format Rupiah (Rp 10.000)
  /// [number] bisa berupa int, double, atau String angka
  /// [decimalDigit] default 0 karena Rupiah jarang pakai desimal
  static String convertToIdr(dynamic number, [int decimalDigit = 0]) {
    
    // 1. Safety Check: Jika null, kembalikan Rp 0
    if (number == null) return 'Rp 0';

    // 2. Handle jika input berupa String ("10000" -> 10000)
    num? value;
    if (number is String) {
      value = num.tryParse(number);
    } else if (number is num) {
      value = number;
    }

    // Jika konversi gagal (misal string "abc"), kembalikan Rp 0
    if (value == null) return 'Rp 0';

    // 3. Format Currency
    NumberFormat currencyFormatter = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: decimalDigit,
    );
    
    return currencyFormatter.format(value);
  }
}
