import 'package:flutter/material.dart';
import '../../../core/controllers/business_controller.dart';
import '../../../core/models/models.dart';
import '../../../core/utils/validators.dart';

void showStoreSettingsDialog(BuildContext context, BusinessController ctrl) {
  final formKey = GlobalKey<FormState>();
  final nameCtrl = TextEditingController(text: ctrl.storeConfig.storeName);
  final subCtrl = TextEditingController(text: ctrl.storeConfig.storeSubtitle);
  final bankCtrl = TextEditingController(text: ctrl.storeConfig.bankName);
  final accCtrl = TextEditingController(text: ctrl.storeConfig.bankAccount);
  final holderCtrl = TextEditingController(text: ctrl.storeConfig.bankHolder);
  String selectedTheme = ctrl.storeConfig.themeMode;

  const commonBanks = [
    'MB Bank',
    'Vietcombank',
    'Techcombank',
    'BIDV',
    'VietinBank',
    'ACB',
    'VPBank',
    'TPBank',
    'Agribank',
    'VIB',
    'Sacombank',
    'HDBank',
  ];

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            CircleAvatar(
              backgroundColor: Color(0xFFE0F2F1),
              child: Icon(Icons.storefront, color: Color(0xFF0F766E)),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Cài Đặt Cửa Hàng & VietQR',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Form(
          key: formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Tên Cửa Hàng / Hộ Kinh Doanh *',
                    hintText: 'VD: Cửa Hàng Tạp Hóa Minh Quang',
                    prefixIcon: Icon(Icons.store),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                  validator: (v) => Validators.required(v, 'Tên cửa hàng không được để trống'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: subCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả / Ngành nghề kinh doanh',
                    hintText: 'VD: Tạp hóa tổng hợp • Bán buôn & bán lẻ',
                    prefixIcon: Icon(Icons.subtitles_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '🏦 Thông Tin Tài Khoản Nhận Chuyển Khoản (VietQR)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),

                // Ngân hàng
                DropdownButtonFormField<String>(
                  value: commonBanks.contains(bankCtrl.text) ? bankCtrl.text : commonBanks.first,
                  decoration: const InputDecoration(
                    labelText: 'Tên Ngân hàng',
                    prefixIcon: Icon(Icons.account_balance),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                  items: commonBanks.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                  onChanged: (v) => setDialogState(() => bankCtrl.text = v ?? 'MB Bank'),
                ),
                const SizedBox(height: 12),

                // Số tài khoản
                TextFormField(
                  controller: accCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Số tài khoản ngân hàng',
                    hintText: 'VD: 0987654321',
                    prefixIcon: Icon(Icons.credit_card),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                ),
                const SizedBox(height: 12),

                // Chủ tài khoản
                TextFormField(
                  controller: holderCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Tên Chủ tài khoản (viết hoa không dấu)',
                    hintText: 'VD: NGUYEN VAN A',
                    prefixIcon: Icon(Icons.person_pin_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '🌓 Giao Diện Ứng Dụng (Theme)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: 'system',
                      label: Text('Hệ thống', style: TextStyle(fontSize: 11)),
                      icon: Icon(Icons.brightness_auto, size: 16),
                    ),
                    ButtonSegment(
                      value: 'light',
                      label: Text('Sáng', style: TextStyle(fontSize: 11)),
                      icon: Icon(Icons.light_mode, size: 16),
                    ),
                    ButtonSegment(
                      value: 'dark',
                      label: Text('Tối', style: TextStyle(fontSize: 11)),
                      icon: Icon(Icons.dark_mode, size: 16),
                    ),
                  ],
                  selected: {selectedTheme},
                  onSelectionChanged: (v) => setDialogState(() => selectedTheme = v.first),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          FilledButton.icon(
            icon: const Icon(Icons.check, size: 18),
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              ctrl.updateStoreConfig(StoreConfig(
                storeName: nameCtrl.text.trim().isEmpty ? 'HỘ KINH DOANH CỦA TÔI' : nameCtrl.text.trim(),
                storeSubtitle: subCtrl.text.trim(),
                bankName: bankCtrl.text.trim(),
                bankAccount: accCtrl.text.trim(),
                bankHolder: holderCtrl.text.trim(),
                themeMode: selectedTheme,
              ));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã cập nhật thông tin cửa hàng & VietQR!'),
                  backgroundColor: Color(0xFF0F766E),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            label: const Text('Lưu Cài Đặt'),
          ),
        ],
      ),
    ),
  );
}
