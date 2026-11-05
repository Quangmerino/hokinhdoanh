class StoreConfig {
  final String storeName;
  final String storeSubtitle;
  final String bankName;
  final String bankAccount;
  final String bankHolder;
  final String themeMode; // 'system', 'light', 'dark'

  const StoreConfig({
    this.storeName = 'HỘ KINH DOANH CỦA TÔI',
    this.storeSubtitle = 'Tự tạo Danh mục • Nhà cung cấp • Mặt hàng • Công nợ',
    this.bankName = 'MB Bank',
    this.bankAccount = '',
    this.bankHolder = '',
    this.themeMode = 'system',
  });

  StoreConfig copyWith({
    String? storeName,
    String? storeSubtitle,
    String? bankName,
    String? bankAccount,
    String? bankHolder,
    String? themeMode,
  }) {
    return StoreConfig(
      storeName: storeName ?? this.storeName,
      storeSubtitle: storeSubtitle ?? this.storeSubtitle,
      bankName: bankName ?? this.bankName,
      bankAccount: bankAccount ?? this.bankAccount,
      bankHolder: bankHolder ?? this.bankHolder,
      themeMode: themeMode ?? this.themeMode,
    );
  }

  Map<String, dynamic> toMap() => {
        'store_name': storeName,
        'store_subtitle': storeSubtitle,
        'bank_name': bankName,
        'bank_account': bankAccount,
        'bank_holder': bankHolder,
        'theme_mode': themeMode,
      };

  factory StoreConfig.fromMap(Map<String, dynamic> map) => StoreConfig(
        storeName: map['store_name'] as String? ?? 'HỘ KINH DOANH CỦA TÔI',
        storeSubtitle: map['store_subtitle'] as String? ?? '',
        bankName: map['bank_name'] as String? ?? 'MB Bank',
        bankAccount: map['bank_account'] as String? ?? '',
        bankHolder: map['bank_holder'] as String? ?? '',
        themeMode: map['theme_mode'] as String? ?? 'system',
      );
}
