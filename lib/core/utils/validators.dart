import 'formatters.dart';

class Validators {
  static String? required(String? value, [String message = 'Vui lòng không để trống']) {
    if (value == null || value.trim().isEmpty) {
      return message;
    }
    return null;
  }

  static String? minLength(String? value, int min, [String? message]) {
    if (value == null || value.trim().length < min) {
      return message ?? 'Cần nhập ít nhất $min ký tự';
    }
    return null;
  }

  static String? positiveNumber(String? value, [String message = 'Giá trị phải lớn hơn 0']) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập số';
    }
    final numVal = double.tryParse(value.replaceAll(',', '.'));
    if (numVal == null || numVal <= 0) {
      return message;
    }
    return null;
  }

  static String? nonNegativeNumber(String? value, [String message = 'Giá trị không được âm']) {
    if (value == null || value.trim().isEmpty) return null;
    final numVal = double.tryParse(value.replaceAll(',', '.'));
    if (numVal == null || numVal < 0) {
      return message;
    }
    return null;
  }

  static String? positiveCurrency(String? value, [String message = 'Số tiền phải lớn hơn 0']) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập số tiền';
    }
    final numVal = AppFormatters.parseVnd(value);
    if (numVal <= 0) {
      return message;
    }
    return null;
  }

  static String? nonNegativeCurrency(String? value, [String message = 'Số tiền không được âm']) {
    if (value == null || value.trim().isEmpty) return null;
    final numVal = AppFormatters.parseVnd(value);
    if (numVal < 0) {
      return message;
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final clean = value.replaceAll(RegExp(r'[^0-9+]'), '');
    if (clean.length < 9 || clean.length > 11) {
      return 'Số điện thoại không hợp lệ (9-11 chữ số)';
    }
    return null;
  }

  static String? requiredPhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập số điện thoại';
    }
    return phone(value);
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regex.hasMatch(value.trim())) {
      return 'Địa chỉ email / Gmail không đúng định dạng';
    }
    return null;
  }

  static String? requiredEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập địa chỉ Gmail / Email';
    }
    return email(value);
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập mật khẩu';
    }
    if (value.length < 6) {
      return 'Mật khẩu phải có ít nhất 6 ký tự';
    }
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng xác nhận mật khẩu';
    }
    if (value != original) {
      return 'Mật khẩu xác nhận không khớp';
    }
    return null;
  }
}
