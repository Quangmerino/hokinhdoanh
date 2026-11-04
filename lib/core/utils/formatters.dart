import 'package:intl/intl.dart';

class AppFormatters {
  static final NumberFormat _vndFormat = NumberFormat.decimalPattern('vi_VN');

  static String formatVnd(num amount) {
    return '${_vndFormat.format(amount.round())}đ';
  }

  static String todayIsoDate() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  static String currentTimeHm() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }
}
