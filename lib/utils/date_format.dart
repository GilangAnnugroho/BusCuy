import 'package:intl/intl.dart';

class DateHelper {
  
  // 1. Format Panjang: Senin, 12 Okt 2025
  // Digunakan di Detail Transaksi / Laporan
  static String formatDate(String dateString) {
    if (dateString.isEmpty) return '-';
    try {
      DateTime date = DateTime.parse(dateString);
      // 'id' = Locale Indonesia (Pastikan initializeDateFormatting dipanggil di main.dart jika perlu)
      return DateFormat('EEEE, d MMM yyyy', 'id').format(date);
    } catch (e) {
      return dateString; // Kembalikan asli jika error parsing
    }
  }

  // 2. Format Singkat: 12/10/2025
  // Digunakan di List / Card yang sempit
  static String formatShort(String dateString) {
    if (dateString.isEmpty) return '-';
    try {
      DateTime date = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  // 3. Format dengan Jam: 12/10/2025 14:30
  // Digunakan untuk Created At (Waktu Transaksi dibuat)
  static String formatWithTime(String dateString) {
    if (dateString.isEmpty) return '-';
    try {
      DateTime date = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    } catch (e) {
      return dateString;
    }
  }

  // 4. Hitung Total Hari (Logic Bisnis Sewa)
  static int hitungSelisihHari(String tglMulai, String tglSelesai) {
    try {
      DateTime start = DateTime.parse(tglMulai);
      DateTime end = DateTime.parse(tglSelesai);

      // PENTING: Normalisasi ke jam 00:00:00
      // Agar selisih jam tidak mempengaruhi hitungan hari kalender
      DateTime startDateOnly = DateTime(start.year, start.month, start.day);
      DateTime endDateOnly = DateTime(end.year, end.month, end.day);

      // Hitung selisih
      int diff = endDateOnly.difference(startDateOnly).inDays;

      // Rule Rental: Inclusive (Tgl 1 s/d Tgl 2 = 2 Hari)
      // Jadi harus ditambah 1
      return diff >= 0 ? diff + 1 : 0; 
    } catch (e) {
      return 0;
    }
  }
}
