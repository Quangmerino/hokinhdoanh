import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  static final NumberFormat _formatter = NumberFormat.decimalPattern('vi_VN');
  final int maxDigits;

  CurrencyInputFormatter({this.maxDigits = 14});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    if (digitsOnly.length > maxDigits) {
      digitsOnly = digitsOnly.substring(0, maxDigits);
    }

    final number = int.tryParse(digitsOnly);
    if (number == null) return oldValue;

    final formatted = _formatter.format(number);

    // Calculate intelligent cursor position based on digit count before cursor
    int digitsBeforeCursor = 0;
    final cursorOffset = newValue.selection.baseOffset.clamp(0, newValue.text.length);
    for (int i = 0; i < cursorOffset; i++) {
      if (RegExp(r'[0-9]').hasMatch(newValue.text[i])) {
        digitsBeforeCursor++;
      }
    }

    int newCursorPos = formatted.length;
    int digitCount = 0;
    for (int i = 0; i < formatted.length; i++) {
      if (RegExp(r'[0-9]').hasMatch(formatted[i])) {
        digitCount++;
      }
      if (digitCount == digitsBeforeCursor) {
        newCursorPos = i + 1;
        break;
      }
    }
    if (digitsBeforeCursor == 0) newCursorPos = 0;

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: newCursorPos.clamp(0, formatted.length)),
    );
  }

  static String format(num value) {
    return _formatter.format(value.round());
  }

  static int parse(String? text) {
    if (text == null || text.trim().isEmpty) return 0;
    final clean = text.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(clean) ?? 0;
  }
}

class AppFormatters {
  static final NumberFormat _vndFormat = NumberFormat.decimalPattern('vi_VN');

  /// Định dạng tiền kèm ký hiệu đ: 2.000.000đ
  static String formatVnd(num amount) {
    return '${_vndFormat.format(amount.round())}đ';
  }

  /// Định dạng số chỉ có dấu chấm: 2.000.000
  static String formatNumber(num amount) {
    return _vndFormat.format(amount.round());
  }

  /// Chuyển chuỗi định dạng (ví dụ '2.000.000' hoặc '2.000.000đ') về số nguyên
  static int parseVnd(String? text) {
    return CurrencyInputFormatter.parse(text);
  }

  /// Định dạng gọn: 2.5 tr, 500 k
  static String formatCompact(num amount) {
    final abs = amount.abs();
    final sign = amount < 0 ? '-' : '';
    if (abs >= 1000000000) {
      return '$sign${(abs / 1000000000).toStringAsFixed(1)} tỷ';
    } else if (abs >= 1000000) {
      return '$sign${(abs / 1000000).toStringAsFixed(1)} tr';
    } else if (abs >= 1000) {
      return '$sign${(abs / 1000).toStringAsFixed(0)} k';
    }
    return '$sign${abs.round()}đ';
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
