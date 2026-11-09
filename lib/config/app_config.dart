import 'dart:io';

class AppConfig {
  // Ganti URL ini dengan URL Web App Google Apps Script Anda yang telah di-Deploy
  // Format: https://script.google.com/macros/s/AKfycb.../exec
  static String webAppUrl = '';

  // Spreadsheet ID yang digunakan di Google Apps Script (sebagai referensi)
  static const String sheetId = '11S2EJ79oNoaBytsZnR7b-wAQ7UcLBwVSIhVMttcZgLk';

  // Format angka ke format Rupiah (Contoh: Rp 25.000)
  static String formatRupiah(num? amount) {
    if (amount == null) return 'Rp 0';
    final isNegative = amount < 0;
    final absAmount = amount.abs();
    
    final strVal = absAmount.toInt().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < strVal.length; i++) {
      if (i > 0 && (strVal.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(strVal[i]);
    }
    
    return '${isNegative ? '- ' : ''}Rp ${buffer.toString()}';
  }

  // Format angka biasa dengan pemisah ribuan
  static String formatNumber(num? number) {
    if (number == null) return '0';
    final strVal = number.toInt().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < strVal.length; i++) {
      if (i > 0 && (strVal.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(strVal[i]);
    }
    return buffer.toString();
  }

  // Format tanggal ISO / Apps Script timestamp ke format Indonesia yang mudah dibaca
  static String formatDate(dynamic dateInput) {
    if (dateInput == null) return '-';
    final str = dateInput.toString().trim();
    if (str.isEmpty) return '-';

    try {
      DateTime dt;
      if (str.contains('T')) {
        dt = DateTime.parse(str);
      } else if (str.contains(' ')) {
        // format: yyyy-MM-dd HH:mm:ss
        final parts = str.split(' ');
        final dateParts = parts[0].split('-');
        if (dateParts.length == 3) {
          final year = int.parse(dateParts[0]);
          final month = int.parse(dateParts[1]);
          final day = int.parse(dateParts[2]);

          int hour = 0, minute = 0;
          if (parts.length > 1) {
            final timeParts = parts[1].split(':');
            if (timeParts.length >= 2) {
              hour = int.parse(timeParts[0]);
              minute = int.parse(timeParts[1]);
            }
          }
          dt = DateTime(year, month, day, hour, minute);
        } else {
          return str;
        }
      } else {
        return str;
      }

      const months = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'
      ];

      final hourStr = dt.hour.toString().padLeft(2, '0');
      final minuteStr = dt.minute.toString().padLeft(2, '0');
      return '${dt.day} ${months[dt.month]} ${dt.year}, $hourStr:$minuteStr WIB';
    } catch (_) {
      return str;
    }
  }
}

