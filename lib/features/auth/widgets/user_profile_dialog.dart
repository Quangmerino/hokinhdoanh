import 'package:flutter/material.dart';
import '../../../core/controllers/business_controller.dart';
import '../screens/forgot_password_screen.dart';

void showUserProfileDialog(BuildContext context, BusinessController ctrl) {
  final user = ctrl.currentUser;
  if (user == null) return;
  final isDark = Theme.of(context).brightness == Brightness.dark;

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFF0F766E),
            child: Text(
              user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '👤',
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  user.storeName,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.tealAccent : const Color(0xFF0F766E),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  _buildInfoRow(Icons.phone_outlined, 'Số điện thoại', user.phone, isDark),
                  const Divider(height: 16),
                  _buildInfoRow(Icons.email_outlined, 'Email / Gmail', user.email, isDark),
                  const Divider(height: 16),
                  _buildInfoRow(
                    Icons.security_outlined,
                    'Kênh khôi phục',
                    _channelLabel(user.recoveryChannel),
                    isDark,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 42),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ForgotPasswordScreen(
                      controller: ctrl,
                      initialIdentifier: user.phone.isNotEmpty ? user.phone : user.email,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.lock_reset, size: 18),
              label: const Text('Đổi mật khẩu tài khoản'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Đóng'),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.red.shade700,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            showDialog(
              context: ctx,
              builder: (c) => AlertDialog(
                title: const Text('Xác nhận đăng xuất?'),
                content: const Text('Bạn có chắc chắn muốn đăng xuất tài khoản khỏi thiết bị này không?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(c), child: const Text('Hủy')),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () {
                      Navigator.pop(c); // Pop confirm
                      Navigator.pop(ctx); // Pop profile dialog
                      ctrl.logout();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã đăng xuất tài khoản an toàn!'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: const Text('Đăng Xuất'),
                  ),
                ],
              ),
            );
          },
          icon: const Icon(Icons.logout, size: 16),
          label: const Text('Đăng Xuất'),
        ),
      ],
    ),
  );
}

Widget _buildInfoRow(IconData icon, String label, String value, bool isDark) {
  return Row(
    children: [
      Icon(icon, size: 18, color: isDark ? Colors.tealAccent : const Color(0xFF0F766E)),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54)),
            Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    ],
  );
}

String _channelLabel(String channel) {
  switch (channel.toLowerCase()) {
    case 'email':
      return '📧 Gmail / Email';
    case 'whatsapp':
      return '💬 WhatsApp';
    case 'facebook':
      return '🌐 Facebook Messenger';
    case 'sms':
    default:
      return '📱 Tin nhắn SMS';
  }
}
