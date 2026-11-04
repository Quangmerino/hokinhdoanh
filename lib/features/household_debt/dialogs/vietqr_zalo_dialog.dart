import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/controllers/business_controller.dart';
import '../../../core/models/models.dart';
import '../../../core/utils/formatters.dart';

void showVietQrZaloDialog(BuildContext context, BusinessController ctrl, HouseholdModel hh) {
  final store = ctrl.storeConfig;
  final reminderLines = <String>[
    '[${store.storeName} - PHIẾU ĐỐI CHIẾU CÔNG NỢ]',
    'Kính gửi: ${hh.name}',
    '- Tổng dư nợ hiện tại: ${AppFormatters.formatVnd(hh.currentDebt)}',
    if (hh.containerOwed > 0) '- Vỏ/Bao bì đang giữ: ${hh.containerOwed} vỏ',
    'Thanh toán CK: ${store.bankName} - STK: ${store.bankAccount} (${store.bankHolder}). Xin cảm ơn!',
  ];
  final reminderText = reminderLines.join(String.fromCharCode(10));

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('📲 Phiếu Nhắc Nợ & VietQR Zalo'),
      content: SelectableText(reminderText),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
        FilledButton.icon(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: reminderText));
            Navigator.pop(ctx);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đã sao chép nội dung nhắc nợ gửi Zalo!')),
            );
          },
          icon: const Icon(Icons.copy, size: 16),
          label: const Text('Sao chép gửi Zalo'),
        ),
      ],
    ),
  );
}
