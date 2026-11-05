import 'dart:convert';
import 'package:crypto/crypto.dart';

class SecurityHelper {
  static const String _salt = 'ho_kinh_doanh_secure_salt_2026';

  static String hashPassword(String password) {
    final bytes = utf8.encode(password + _salt);
    return sha256.convert(bytes).toString();
  }

  static bool verifyPassword(String password, String hash) {
    return hashPassword(password) == hash;
  }
}
