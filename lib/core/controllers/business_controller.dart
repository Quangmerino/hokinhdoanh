import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../api/auth_api_service.dart';
import '../api/catalog_api_service.dart';
import '../api/product_api_service.dart';
import '../api/household_api_service.dart';
import '../api/order_api_service.dart';
import '../api/cashflow_api_service.dart';
import '../api/settings_api_service.dart';
import '../database/app_database.dart';
import '../models/models.dart';
import '../utils/formatters.dart';
import '../utils/security_helper.dart';

class BusinessController extends ChangeNotifier {
  final LocalSqliteDatabase _db = LocalSqliteDatabase.instance;
  final ApiClient apiClient = ApiClient();
  late final AuthApiService authApi = AuthApiService(apiClient: apiClient);
  late final CatalogApiService catalogApi = CatalogApiService(apiClient: apiClient);
  late final ProductApiService productApi = ProductApiService(apiClient: apiClient);
  late final HouseholdApiService householdApi = HouseholdApiService(apiClient: apiClient);
  late final OrderApiService orderApi = OrderApiService(apiClient: apiClient);
  late final CashflowApiService cashflowApi = CashflowApiService(apiClient: apiClient);
  late final SettingsApiService settingsApi = SettingsApiService(apiClient: apiClient);

  UserModel? currentUser;
  bool get isAuthenticated => currentUser != null;

  StoreConfig storeConfig = const StoreConfig();
  List<CategoryNode> categories = [];
  List<SupplierModel> suppliers = [];
  List<ProductModel> products = [];
  List<HouseholdModel> households = [];
  List<OrderRecordModel> orders = [];
  List<CashTxModel> cashTransactions = [];

  // UI & Filter State
  String treeMode = 'category'; // 'category' or 'supplier'
  int? selectedCategoryId;
  int? selectedSupplierId;
  final Set<String> expandedNodeKeys = {};

  // POS State
  String posOrderType = 'SALE'; // 'SALE' or 'PURCHASE'
  int? posCategoryFilter;
  List<CartItemModel> posCart = [];
  int? selectedHouseholdId;

  // Reports State
  String reportGranularity = 'MONTH'; // 'DAY', 'WEEK', 'MONTH', 'YEAR'
  String reportAnchorDate = AppFormatters.todayIsoDate();

  bool isInitialized = false;

  Future<void> init() async {
    try {
      final token = await _db.getAuthToken();
      if (token != null && token.isNotEmpty) {
        apiClient.setAccessToken(token);
        try {
          currentUser = await authApi.getProfile();
          // Đồng bộ dữ liệu mới nhất từ Backend API
          final remoteCategories = await catalogApi.getCategories();
          if (remoteCategories.isNotEmpty) categories = remoteCategories;

          final remoteSuppliers = await catalogApi.getSuppliers();
          if (remoteSuppliers.isNotEmpty) suppliers = remoteSuppliers;

          final remoteProducts = await productApi.getProducts();
          if (remoteProducts.isNotEmpty) products = remoteProducts;

          final remoteHouseholds = await householdApi.getHouseholds();
          if (remoteHouseholds.isNotEmpty) households = remoteHouseholds;

          final remoteOrders = await orderApi.getOrders();
          if (remoteOrders.isNotEmpty) orders = remoteOrders;

          final remoteCash = await cashflowApi.getCashTransactions();
          if (remoteCash.isNotEmpty) cashTransactions = remoteCash;

          final remoteSettings = await settingsApi.getSettings();
          storeConfig = remoteSettings;
        } catch (_) {
          currentUser = await _db.getActiveSessionUser();
        }
      } else {
        currentUser = await _db.getActiveSessionUser();
      }

      if (categories.isEmpty) categories = await _db.loadCategories();
      if (suppliers.isEmpty) suppliers = await _db.loadSuppliers();
      if (products.isEmpty) products = await _db.loadProducts();
      if (households.isEmpty) households = await _db.loadHouseholds();
      if (orders.isEmpty) orders = await _db.loadOrders();
      if (cashTransactions.isEmpty) cashTransactions = await _db.loadCashTransactions();
      if (storeConfig.storeName == 'HỘ KINH DOANH CỦA TÔI') {
        storeConfig = await _db.loadStoreConfig();
      }

      for (final c in categories) {
        expandedNodeKeys.add('cat-${c.id}');
      }
      for (final s in suppliers) {
        expandedNodeKeys.add('sup-${s.id}');
      }
      if (households.isNotEmpty) {
        selectedHouseholdId = households.first.id;
      }
    } catch (_) {
      // Fallback to in-memory if running on web preview without sqflite plugin
    }
    isInitialized = true;
    notifyListeners();
  }

  // ==================== AUTHENTICATION & SECURITY ====================

  String? _recoveryOtp;
  String? _recoveryIdentifier;
  String? _recoveryChannel;
  DateTime? _recoveryOtpExpiry;
  String? _verifiedOtpCode;

  String? get lastRecoveryOtp => _recoveryOtp;
  String? get lastRecoveryChannel => _recoveryChannel;
  String? get lastRecoveryIdentifier => _recoveryIdentifier;

  Future<String?> registerUser({
    required String fullName,
    required String phone,
    required String email,
    required String password,
    required String storeName,
    String recoveryChannel = 'sms',
  }) async {
    // 1. Thử đăng ký qua Backend API
    try {
      final res = await authApi.register(
        fullName: fullName,
        storeName: storeName,
        phone: phone,
        email: email,
        password: password,
        recoveryChannel: recoveryChannel,
      );

      final registeredUser = res['user'] as UserModel;
      final token = res['accessToken'] as String?;

      // Đồng bộ vào cơ sở dữ liệu nội bộ thiết bị để hỗ trợ ngoại tuyến
      try {
        final hash = SecurityHelper.hashPassword(password);
        final localUser = registeredUser.copyWith(passwordHash: hash);
        final created = await _db.registerUser(localUser);
        currentUser = created ?? localUser;
        await _db.saveAuthSession(currentUser!.id, token: token);
      } catch (_) {
        // Dự phòng cho nền tảng Web hoặc khi SQLite cục bộ không khả dụng
        currentUser = registeredUser;
      }

      if (storeName.trim().isNotEmpty) {
        await updateStoreConfig(storeConfig.copyWith(storeName: storeName.trim()));
      }
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      // Trường hợp request trước đó đã tạo xong trên Server nhưng client bị timeout
      if (e.message.contains('đã được sử dụng') || e.message.contains('đã tồn tại') || e.statusCode == 409) {
        try {
          final loginErr = await loginUser(identifier: phone, password: password);
          if (loginErr == null) {
            return null; // Đăng nhập tự động thành công!
          }
        } catch (_) {}
      }
      return e.message;
    } catch (_) {
      // 2. Chế độ dự phòng cục bộ khi máy chủ chưa mở hoặc mất mạng
      final existingPhone = await _db.findUserByIdentifier(phone);
      if (existingPhone != null) {
        return 'Số điện thoại này đã được đăng ký tài khoản.';
      }
      final existingEmail = await _db.findUserByIdentifier(email);
      if (existingEmail != null) {
        return 'Địa chỉ email/Gmail này đã được đăng ký tài khoản.';
      }

      final hash = SecurityHelper.hashPassword(password);
      final newUser = UserModel(
        id: 0,
        fullName: fullName.trim(),
        phone: phone.trim(),
        email: email.trim().toLowerCase(),
        passwordHash: hash,
        storeName: storeName.trim(),
        recoveryChannel: recoveryChannel,
        createdAt: DateTime.now().toIso8601String(),
      );

      final created = await _db.registerUser(newUser);
      if (created != null) {
        currentUser = created;
        await _db.saveAuthSession(currentUser!.id);
        if (storeName.trim().isNotEmpty) {
          await updateStoreConfig(storeConfig.copyWith(storeName: storeName.trim()));
        }
        notifyListeners();
        return null;
      }
      return 'Không thể tạo tài khoản. Vui lòng thử lại sau.';
    }
  }

  Future<String?> loginUser({
    required String identifier,
    required String password,
  }) async {
    // 1. Thử đăng nhập qua Backend API
    try {
      final res = await authApi.login(
        identifier: identifier,
        password: password,
      );

      final loggedInUser = res['user'] as UserModel;
      final token = res['accessToken'] as String?;

      try {
        final hash = SecurityHelper.hashPassword(password);
        final localUser = loggedInUser.copyWith(passwordHash: hash);
        final savedLocal = await _db.registerUser(localUser);
        currentUser = savedLocal ?? localUser;
        await _db.saveAuthSession(currentUser!.id, token: token);
      } catch (_) {
        // Dự phòng cho nền tảng Web hoặc khi SQLite cục bộ không khả dụng
        currentUser = loggedInUser;
      }

      if (currentUser!.storeName.isNotEmpty && storeConfig.storeName == 'HỘ KINH DOANH CỦA TÔI') {
        await updateStoreConfig(storeConfig.copyWith(storeName: currentUser!.storeName));
      }
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      // 2. Dự phòng đăng nhập ngoại tuyến
      final cleanId = identifier.trim().toLowerCase();
      final user = await _db.findUserByIdentifier(cleanId);
      if (user == null) {
        return 'Không tìm thấy tài khoản với SĐT hoặc Email "$cleanId".';
      }
      final hash = SecurityHelper.hashPassword(password);
      if (user.passwordHash != hash) {
        return 'Mật khẩu không chính xác. Vui lòng kiểm tra lại.';
      }

      await _db.saveAuthSession(user.id);
      currentUser = user;
      if (user.storeName.isNotEmpty && storeConfig.storeName == 'HỘ KINH DOANH CỦA TÔI') {
        await updateStoreConfig(storeConfig.copyWith(storeName: user.storeName));
      }
      notifyListeners();
      return null;
    }
  }

  Future<void> logout() async {
    try {
      await _db.clearAuthSession();
    } catch (_) {}
    apiClient.setAccessToken(null);
    currentUser = null;
    posCart.clear();
    _recoveryOtp = null;
    _recoveryIdentifier = null;
    _recoveryOtpExpiry = null;
    _verifiedOtpCode = null;
    notifyListeners();
  }

  Future<Map<String, dynamic>> requestPasswordRecovery({
    required String identifier,
    required String channel, // 'sms', 'email', 'whatsapp', 'facebook'
  }) async {
    // 1. Thử gửi qua Backend API
    try {
      final res = await authApi.sendRecoveryOtp(
        identifier: identifier,
        channel: channel,
      );
      _recoveryOtp = res['simulatedOtp'] as String?;
      _recoveryIdentifier = identifier.trim().toLowerCase();
      _recoveryChannel = channel;
      _recoveryOtpExpiry = DateTime.now().add(const Duration(minutes: 5));

      return {
        'success': true,
        'otp': _recoveryOtp ?? '',
        'destination': res['target'] ?? identifier,
        'message': res['message'] ?? '',
      };
    } on ApiException catch (e) {
      return {
        'success': false,
        'error': e.message,
      };
    } catch (_) {
      // 2. Dự phòng cục bộ
      final cleanId = identifier.trim().toLowerCase();
      final user = await _db.findUserByIdentifier(cleanId);
      if (user == null) {
        return {
          'success': false,
          'error': 'Không tìm thấy tài khoản nào khớp với "$identifier".',
        };
      }

      final randomOtp = (100000 + (DateTime.now().microsecondsSinceEpoch % 900000)).toString();
      _recoveryOtp = randomOtp;
      _recoveryIdentifier = cleanId;
      _recoveryChannel = channel;
      _recoveryOtpExpiry = DateTime.now().add(const Duration(minutes: 5));

      final destination = channel == 'email' ? user.email : user.phone;

      return {
        'success': true,
        'otp': randomOtp,
        'user': user,
        'channel': channel,
        'destination': destination,
      };
    }
  }

  Future<bool> verifyRecoveryOtp({
    required String identifier,
    required String code,
  }) async {
    try {
      final res = await authApi.verifyRecoveryOtp(
        identifier: identifier,
        code: code,
      );
      if (res['success'] == true) {
        _verifiedOtpCode = code.trim();
        return true;
      }
      return false;
    } on ApiException {
      return false;
    } catch (_) {
      if (_recoveryOtp == null || _recoveryOtpExpiry == null) return false;
      if (DateTime.now().isAfter(_recoveryOtpExpiry!)) return false;
      if (_recoveryIdentifier != identifier.trim().toLowerCase()) return false;
      final matched = _recoveryOtp == code.trim();
      if (matched) _verifiedOtpCode = code.trim();
      return matched;
    }
  }

  Future<bool> resetPassword({
    required String identifier,
    required String newPassword,
    String? code,
  }) async {
    final cleanId = identifier.trim().toLowerCase();
    final otpCode = code?.trim() ?? _verifiedOtpCode ?? _recoveryOtp ?? '';

    try {
      final res = await authApi.resetPassword(
        identifier: cleanId,
        code: otpCode,
        newPassword: newPassword,
      );
      if (res['success'] == true) {
        try {
          final newHash = SecurityHelper.hashPassword(newPassword);
          await _db.updatePasswordByIdentifier(cleanId, newHash);
        } catch (_) {
          // Dự phòng cho nền tảng Web hoặc khi SQLite không khả dụng
        }
        _recoveryOtp = null;
        _recoveryIdentifier = null;
        _recoveryOtpExpiry = null;
        _verifiedOtpCode = null;
        if (currentUser != null &&
            (currentUser!.phone == cleanId || currentUser!.email.toLowerCase() == cleanId)) {
          currentUser = currentUser!.copyWith(passwordHash: SecurityHelper.hashPassword(newPassword));
        }
        notifyListeners();
        return true;
      }
      return false;
    } on ApiException {
      return false;
    } catch (_) {
      try {
        final newHash = SecurityHelper.hashPassword(newPassword);
        final success = await _db.updatePasswordByIdentifier(cleanId, newHash);
        if (success) {
          _recoveryOtp = null;
          _recoveryIdentifier = null;
          _recoveryOtpExpiry = null;
          _verifiedOtpCode = null;
          if (currentUser != null &&
              (currentUser!.phone == cleanId || currentUser!.email.toLowerCase() == cleanId)) {
            currentUser = currentUser!.copyWith(passwordHash: newHash);
          }
          notifyListeners();
        }
        return success;
      } catch (_) {
        return false;
      }
    }
  }

  // Computed KPIs
  int get totalCashBalance {
    int cashIn = 0;
    int cashOut = 0;
    for (final tx in cashTransactions) {
      if (tx.flow == 'IN') {
        cashIn += tx.amount;
      } else {
        cashOut += tx.amount;
      }
    }
    return cashIn - cashOut;
  }

  int get totalHouseholdDebt =>
      households.fold(0, (sum, h) => sum + h.currentDebt);

  int get totalContainerOwed =>
      households.fold(0, (sum, h) => sum + h.containerOwed);

  int get totalSupplierPayable =>
      suppliers.fold(0, (sum, s) => sum + s.payableDebt);

  // Tree Helpers
  int getRootCategoryId(int catId) {
    CategoryNode? curr = categories.where((c) => c.id == catId).firstOrNull;
    int guard = 0;
    while (curr != null && curr.parentId != null && guard < 20) {
      final parent = categories.where((c) => c.id == curr!.parentId).firstOrNull;
      if (parent == null) break;
      curr = parent;
      guard++;
    }
    return curr?.id ?? 0;
  }

  List<int> getCategorySubtreeIds(int? rootCatId) {
    if (rootCatId == null) return categories.map((c) => c.id).toList();
    final result = <int>{rootCatId};
    bool added = true;
    while (added) {
      added = false;
      for (final c in categories) {
        if (c.parentId != null && result.contains(c.parentId) && !result.contains(c.id)) {
          result.add(c.id);
          added = true;
        }
      }
    }
    return result.toList();
  }

  String getCategoryDepthLabel(CategoryNode cat) {
    int depth = 0;
    CategoryNode? curr = cat;
    int guard = 0;
    while (curr != null && curr.parentId != null && guard < 20) {
      depth++;
      curr = categories.where((c) => c.id == curr!.parentId).firstOrNull;
      guard++;
    }
    return '${'— ' * depth}${cat.icon} ${cat.name}';
  }

  void toggleNodeExpand(String key) {
    if (expandedNodeKeys.contains(key)) {
      expandedNodeKeys.remove(key);
    } else {
      expandedNodeKeys.add(key);
    }
    notifyListeners();
  }

  void selectTreeFilter({int? categoryId, int? supplierId}) {
    selectedCategoryId = categoryId;
    selectedSupplierId = supplierId;
    notifyListeners();
  }

  void setTreeMode(String mode) {
    treeMode = mode;
    notifyListeners();
  }

  // Theme & Appearance
  ThemeMode get themeMode {
    switch (storeConfig.themeMode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    String modeStr = 'system';
    if (mode == ThemeMode.light) modeStr = 'light';
    if (mode == ThemeMode.dark) modeStr = 'dark';

    final updated = storeConfig.copyWith(themeMode: modeStr);
    await updateStoreConfig(updated);
  }

  Future<void> toggleThemeMode() async {
    if (themeMode == ThemeMode.system) {
      await setThemeMode(ThemeMode.light);
    } else if (themeMode == ThemeMode.light) {
      await setThemeMode(ThemeMode.dark);
    } else {
      await setThemeMode(ThemeMode.system);
    }
  }

  // Store Settings
  Future<void> updateStoreConfig(StoreConfig newConfig) async {
    storeConfig = newConfig;
    try {
      final updated = await settingsApi.updateSettings(newConfig);
      storeConfig = updated;
    } catch (_) {}
    try {
      await _db.saveStoreConfig(storeConfig);
    } catch (_) {}
    notifyListeners();
  }

  // Category CRUD (100% User-defined)
  Future<void> saveCategory({
    int? editId,
    required String name,
    required String icon,
    int? parentId,
  }) async {
    try {
      if (editId != null) {
        final updated = await catalogApi.updateCategory(
          editId,
          name: name,
          icon: icon,
          parentId: parentId,
        );
        final idx = categories.indexWhere((c) => c.id == editId);
        if (idx != -1) categories[idx] = updated;
        try {
          await _db.upsertCategory(updated);
        } catch (_) {}
      } else {
        final created = await catalogApi.createCategory(
          name: name,
          icon: icon,
          parentId: parentId,
        );
        categories.add(created);
        expandedNodeKeys.add('cat-${created.id}');
        if (parentId != null) expandedNodeKeys.add('cat-$parentId');
        selectedCategoryId = created.id;
        try {
          await _db.upsertCategory(created);
        } catch (_) {}
      }
    } catch (_) {
      // Dự phòng ngoại tuyến (Offline fallback)
      if (editId != null) {
        final idx = categories.indexWhere((c) => c.id == editId);
        if (idx != -1) {
          final path = parentId != null ? '/$parentId/$editId/' : '/$editId/';
          final updated = CategoryNode(
            id: editId,
            parentId: parentId,
            name: name,
            icon: icon,
            materializedPath: path,
          );
          categories[idx] = updated;
          try {
            await _db.upsertCategory(updated);
          } catch (_) {}
        }
      } else {
        final newId = DateTime.now().millisecondsSinceEpoch % 1000000;
        final path = parentId != null ? '/$parentId/$newId/' : '/$newId/';
        final created = CategoryNode(
          id: newId,
          parentId: parentId,
          name: name,
          icon: icon,
          materializedPath: path,
        );
        categories.add(created);
        expandedNodeKeys.add('cat-$newId');
        if (parentId != null) expandedNodeKeys.add('cat-$parentId');
        selectedCategoryId = newId;
        try {
          await _db.upsertCategory(created);
        } catch (_) {}
      }
    }
    notifyListeners();
  }

  Future<void> deleteCategory(int categoryId) async {
    try {
      await catalogApi.deleteCategory(categoryId);
    } catch (_) {}
    final subtreeIds = getCategorySubtreeIds(categoryId);
    categories.removeWhere((c) => subtreeIds.contains(c.id));
    products.removeWhere((p) => subtreeIds.contains(p.categoryId));
    for (int i = 0; i < suppliers.length; i++) {
      suppliers[i] = suppliers[i].copyWith(
        categoryIds: suppliers[i]
            .categoryIds
            .where((cid) => !subtreeIds.contains(cid))
            .toList(),
      );
    }
    if (selectedCategoryId != null && subtreeIds.contains(selectedCategoryId)) {
      selectedCategoryId = null;
    }
    try {
      await _db.deleteCategorySubtree(subtreeIds);
    } catch (_) {}
    notifyListeners();
  }

  // Supplier CRUD (100% User-defined)
  Future<void> saveSupplier({
    int? editId,
    required String name,
    required String phone,
    required String address,
    required int payableDebt,
    required List<int> categoryIds,
  }) async {
    try {
      if (editId != null) {
        final updated = await catalogApi.updateSupplier(
          editId,
          name: name,
          phone: phone,
          address: address,
          payableDebt: payableDebt,
          categoryIds: categoryIds,
        );
        final idx = suppliers.indexWhere((s) => s.id == editId);
        if (idx != -1) suppliers[idx] = updated;
        try {
          await _db.upsertSupplier(updated);
        } catch (_) {}
      } else {
        final created = await catalogApi.createSupplier(
          name: name,
          phone: phone,
          address: address,
          payableDebt: payableDebt,
          categoryIds: categoryIds,
        );
        suppliers.add(created);
        expandedNodeKeys.add('sup-${created.id}');
        try {
          await _db.upsertSupplier(created);
        } catch (_) {}
      }
    } catch (_) {
      // Dự phòng ngoại tuyến
      if (editId != null) {
        final idx = suppliers.indexWhere((s) => s.id == editId);
        if (idx != -1) {
          final updated = suppliers[idx].copyWith(
            name: name,
            phone: phone,
            address: address,
            payableDebt: payableDebt,
            categoryIds: categoryIds,
          );
          suppliers[idx] = updated;
          try {
            await _db.upsertSupplier(updated);
          } catch (_) {}
        }
      } else {
        final newId = DateTime.now().millisecondsSinceEpoch % 1000000;
        final created = SupplierModel(
          id: newId,
          name: name,
          phone: phone,
          address: address,
          payableDebt: payableDebt,
          categoryIds: categoryIds,
        );
        suppliers.add(created);
        expandedNodeKeys.add('sup-$newId');
        try {
          await _db.upsertSupplier(created);
        } catch (_) {}
      }
    }
    notifyListeners();
  }

  Future<void> deleteSupplier(int supplierId) async {
    try {
      await catalogApi.deleteSupplier(supplierId);
    } catch (_) {}
    suppliers.removeWhere((s) => s.id == supplierId);
    if (selectedSupplierId == supplierId) selectedSupplierId = null;
    try {
      await _db.deleteSupplier(supplierId);
    } catch (_) {}
    notifyListeners();
  }

  // Product CRUD (100% User-defined)
  Future<void> saveProduct({
    int? editId,
    required String name,
    required String sku,
    required int categoryId,
    required int primarySupplierId,
    required List<int> supplierIds,
    required String baseUnit,
    required double stockQty,
    required int costPrice,
    required int retailPrice,
    required String packUnitName,
    required double packRate,
    required int packPrice,
    required bool trackReturnableShell,
    required String specNote,
    String? imagePath,
  }) async {
    int resolvedCatId = categoryId;
    if (resolvedCatId == 0) {
      final autoId = DateTime.now().millisecondsSinceEpoch % 1000000;
      final autoCat = CategoryNode(
        id: autoId,
        parentId: null,
        name: 'Danh mục chung',
        icon: '📦',
        materializedPath: '/$autoId/',
      );
      categories.add(autoCat);
      expandedNodeKeys.add('cat-$autoId');
      resolvedCatId = autoId;
      try {
        await _db.upsertCategory(autoCat);
      } catch (_) {}
    }

    final mergedSups = <int>{...supplierIds};
    if (primarySupplierId > 0) mergedSups.add(primarySupplierId);

    // Ensure suppliers link to this category
    for (int i = 0; i < suppliers.length; i++) {
      if (mergedSups.contains(suppliers[i].id) &&
          !suppliers[i].categoryIds.contains(resolvedCatId)) {
        final nextCatIds = [...suppliers[i].categoryIds, resolvedCatId];
        suppliers[i] = suppliers[i].copyWith(categoryIds: nextCatIds);
        try {
          await _db.upsertSupplier(suppliers[i]);
        } catch (_) {}
      }
    }

    final model = ProductModel(
      id: editId ?? (DateTime.now().millisecondsSinceEpoch % 1000000 + 7),
      sku: sku.isEmpty ? 'SP-${DateTime.now().millisecondsSinceEpoch % 1000000}' : sku,
      name: name,
      categoryId: resolvedCatId,
      primarySupplierId: primarySupplierId,
      supplierIds: mergedSups.toList(),
      baseUnit: baseUnit,
      stockQty: stockQty,
      costPrice: costPrice,
      retailPrice: retailPrice,
      packUnitName: packUnitName,
      packRate: packUnitName.isNotEmpty ? packRate : 1.0,
      packPrice: packPrice,
      trackReturnableShell: trackReturnableShell,
      specNote: specNote,
      imagePath: imagePath,
    );

    try {
      if (editId != null) {
        final updated = await productApi.updateProduct(editId, model);
        final idx = products.indexWhere((p) => p.id == editId);
        if (idx != -1) products[idx] = updated;
        try {
          await _db.upsertProduct(updated);
        } catch (_) {}
      } else {
        final created = await productApi.createProduct(model);
        products.insert(0, created);
        try {
          await _db.upsertProduct(created);
        } catch (_) {}
      }
    } catch (_) {
      // Dự phòng ngoại tuyến
      if (editId != null) {
        final idx = products.indexWhere((p) => p.id == editId);
        if (idx != -1) {
          products[idx] = model;
          try {
            await _db.upsertProduct(model);
          } catch (_) {}
        }
      } else {
        products.insert(0, model);
        try {
          await _db.upsertProduct(model);
        } catch (_) {}
      }
    }
    notifyListeners();
  }

  Future<void> deleteProduct(int productId) async {
    try {
      await productApi.deleteProduct(productId);
    } catch (_) {}
    products.removeWhere((p) => p.id == productId);
    posCart.removeWhere((item) => item.product.id == productId);
    try {
      await _db.deleteProduct(productId);
    } catch (_) {}
    notifyListeners();
  }

  // POS Operations
  void setPosOrderType(String type) {
    posOrderType = type;
    posCart = posCart.map((item) {
      final p = item.product;
      final price = type == 'SALE'
          ? (item.usePackUnit ? p.packPrice : p.retailPrice)
          : (item.usePackUnit ? (p.costPrice * p.packRate).round() : p.costPrice);
      return item.copyWith(customUnitPrice: price);
    }).toList();
    notifyListeners();
  }

  void addProductToCart(ProductModel product) {
    final idx = posCart.indexWhere((c) => c.product.id == product.id);
    if (idx != -1) {
      posCart[idx] = posCart[idx].copyWith(qty: posCart[idx].qty + 1);
    } else {
      final usePack = product.hasPackUnit;
      final price = posOrderType == 'SALE'
          ? (usePack ? product.packPrice : product.retailPrice)
          : (usePack ? (product.costPrice * product.packRate).round() : product.costPrice);
      posCart.add(CartItemModel(
        product: product,
        usePackUnit: usePack,
        qty: 1,
        customUnitPrice: price,
      ));
    }
    notifyListeners();
  }

  void updateCartItem(int index, {bool? usePackUnit, double? qty, int? customUnitPrice}) {
    if (index < 0 || index >= posCart.length) return;
    final curr = posCart[index];
    if (qty != null && qty <= 0) {
      posCart.removeAt(index);
      notifyListeners();
      return;
    }
    int nextPrice = customUnitPrice ?? curr.customUnitPrice;
    if (usePackUnit != null && usePackUnit != curr.usePackUnit) {
      final p = curr.product;
      nextPrice = posOrderType == 'SALE'
          ? (usePackUnit ? p.packPrice : p.retailPrice)
          : (usePackUnit ? (p.costPrice * p.packRate).round() : p.costPrice);
    }
    posCart[index] = curr.copyWith(
      usePackUnit: usePackUnit,
      qty: qty,
      customUnitPrice: nextPrice,
    );
    notifyListeners();
  }

  void clearCart() {
    posCart.clear();
    notifyListeners();
  }

  int get posSubtotal => posCart.fold(0, (sum, item) => sum + item.lineTotal);

  Future<void> submitPosOrder({
    required int discount,
    required int paidAmount,
    required String paymentMethod,
    required String dateStr,
    int? householdId,
    String? buyerMemberName,
    int? supplierId,
    int containerOwedDelta = 0,
    String note = '',
  }) async {
    if (posCart.isEmpty) return;
    final isSale = posOrderType == 'SALE';
    final finalTotal = (posSubtotal - discount).clamp(0, 999999999);
    final paid = paidAmount.clamp(0, finalTotal);
    final debtAmount = (finalTotal - paid).clamp(0, 999999999);
    final fullDateStr = '$dateStr ${AppFormatters.currentTimeHm()}';

    int totalCogs = 0;
    final summaryParts = <String>[];
    int primaryRootCatId = 0;

    // 1. Thử gửi đơn hàng lên Backend API
    try {
      final itemsPayload = posCart.map((item) => {
        'productId': item.product.id,
        'quantity': item.qty,
        'isPack': item.usePackUnit,
        'price': item.customUnitPrice,
      }).toList();

      await orderApi.checkout(
        orderType: posOrderType,
        items: itemsPayload,
        discount: discount,
        paidAmount: paid,
        paymentMethod: paymentMethod,
        householdId: householdId,
        buyerMemberName: buyerMemberName,
        supplierId: supplierId,
        containerOwedDelta: containerOwedDelta,
        note: note,
        dateStr: dateStr,
      );
    } catch (_) {
      // Tiếp tục thực hiện lưu trữ nội bộ (Offline-first fallback)
    }

    for (int i = 0; i < posCart.length; i++) {
      final item = posCart[i];
      final pIdx = products.indexWhere((p) => p.id == item.product.id);
      if (pIdx == -1) continue;
      final prod = products[pIdx];
      if (i == 0) primaryRootCatId = getRootCategoryId(prod.categoryId);

      final baseQty = item.baseDeductionQty;
      summaryParts.add('${item.qty} ${item.unitLabel} ${prod.name}');

      final nextStock = isSale
          ? (prod.stockQty - baseQty).clamp(0.0, 9999999.0)
          : (prod.stockQty + baseQty);
      products[pIdx] = prod.copyWith(stockQty: nextStock);
      try {
        await _db.upsertProduct(products[pIdx]);
      } catch (_) {}

      if (isSale) {
        totalCogs += (baseQty * prod.costPrice).round();
      }
    }

    final summaryText = summaryParts.join(' + ') + (note.isNotEmpty ? ' ($note)' : '');
    final nowId = DateTime.now().millisecondsSinceEpoch % 1000000;

    if (isSale) {
      final order = OrderRecordModel(
        id: nowId,
        dateStr: fullDateStr,
        orderType: 'SALE',
        categoryRootId: primaryRootCatId,
        totalAmount: finalTotal,
        cogs: totalCogs,
        paidAmount: paid,
        debtAmount: debtAmount,
        description: summaryText,
      );
      orders.insert(0, order);
      try {
        await _db.insertOrder(order);
      } catch (_) {}

      if (paid > 0) {
        final hh = households.where((h) => h.id == householdId).firstOrNull;
        final tx = CashTxModel(
          id: nowId + 1,
          dateStr: fullDateStr,
          flow: 'IN',
          category: 'SALE_CASH',
          method: paymentMethod,
          amount: paid,
          note: 'Thu tiền bán hàng (${hh?.name ?? 'Khách lẻ'}): $summaryText',
        );
        cashTransactions.insert(0, tx);
        try {
          await _db.insertCashTransaction(tx);
        } catch (_) {}
      }

      if (householdId != null && householdId > 0) {
        final hIdx = households.indexWhere((h) => h.id == householdId);
        if (hIdx != -1) {
          final hh = households[hIdx];
          final nextDebt = hh.currentDebt + debtAmount;
          final nextContainer = hh.containerOwed + containerOwedDelta;
          final nextLedger = [...hh.ledger];

          if (debtAmount > 0 || containerOwedDelta > 0) {
            final entry = DebtLedgerEntry(
              id: nowId + 2,
              householdId: hh.id,
              dateStr: fullDateStr,
              actorName: buyerMemberName ?? hh.headName,
              description:
                  'Mua: $summaryText (Tổng: ${AppFormatters.formatVnd(finalTotal)}, Trả ngay: ${AppFormatters.formatVnd(paid)}${containerOwedDelta > 0 ? ', Giữ thêm $containerOwedDelta vỏ' : ''})',
              changeAmount: debtAmount,
              balanceAfter: nextDebt,
            );
            nextLedger.insert(0, entry);
            try {
              await _db.insertDebtLedger(entry);
            } catch (_) {}
          }

          households[hIdx] = hh.copyWith(
            currentDebt: nextDebt,
            containerOwed: nextContainer,
            ledger: nextLedger,
          );
          try {
            await _db.upsertHousehold(households[hIdx]);
          } catch (_) {}
        }
      }
    } else {
      // PURCHASE FROM SUPPLIER
      final sIdx = suppliers.indexWhere((s) => s.id == supplierId);
      final supName = sIdx != -1 ? suppliers[sIdx].name : 'Nhà cung cấp';
      if (paid > 0) {
        final tx = CashTxModel(
          id: nowId + 3,
          dateStr: fullDateStr,
          flow: 'OUT',
          category: 'PURCHASE_PAY',
          method: paymentMethod,
          amount: paid,
          note: 'Trả tiền nhập hàng ($supName): $summaryText',
        );
        cashTransactions.insert(0, tx);
        try {
          await _db.insertCashTransaction(tx);
        } catch (_) {}
      }
      if (sIdx != -1 && debtAmount > 0) {
        suppliers[sIdx] = suppliers[sIdx].copyWith(
          payableDebt: suppliers[sIdx].payableDebt + debtAmount,
        );
        try {
          await _db.upsertSupplier(suppliers[sIdx]);
        } catch (_) {}
      }
    }

    posCart.clear();
    notifyListeners();
  }

  // Household CRUD & Debt Collection
  Future<void> saveHousehold({
    int? editId,
    required String name,
    required String headName,
    required String phone,
    required String address,
    required int creditLimit,
    required int initDebt,
    required int initContainerOwed,
    required List<String> extraMembers,
  }) async {
    final allMembers = <String>['$headName (Chủ hộ)', ...extraMembers];
    final model = HouseholdModel(
      id: editId ?? (DateTime.now().millisecondsSinceEpoch % 1000000),
      name: name,
      headName: headName,
      phone: phone,
      address: address,
      creditLimit: creditLimit,
      currentDebt: initDebt,
      containerOwed: initContainerOwed,
      members: allMembers,
    );

    try {
      if (editId != null) {
        final updated = await householdApi.updateHousehold(editId, model);
        final idx = households.indexWhere((h) => h.id == editId);
        if (idx != -1) {
          households[idx] = households[idx].copyWith(
            name: updated.name,
            headName: updated.headName,
            phone: updated.phone,
            address: updated.address,
            creditLimit: updated.creditLimit,
            currentDebt: initDebt,
            containerOwed: initContainerOwed,
            members: updated.members,
          );
          try {
            await _db.upsertHousehold(households[idx]);
          } catch (_) {}
        }
      } else {
        final created = await householdApi.createHousehold(model);
        final initLedger = <DebtLedgerEntry>[];
        if (initDebt > 0) {
          final entry = DebtLedgerEntry(
            id: DateTime.now().millisecondsSinceEpoch % 1000000 + 1,
            householdId: created.id,
            dateStr: '${AppFormatters.todayIsoDate()} 08:00',
            actorName: headName,
            description: 'Dư nợ đầu kỳ khi khởi tạo sổ',
            changeAmount: initDebt,
            balanceAfter: initDebt,
          );
          initLedger.add(entry);
        }
        final finalCreated = created.copyWith(
          currentDebt: initDebt,
          containerOwed: initContainerOwed,
          ledger: initLedger,
        );
        households.insert(0, finalCreated);
        selectedHouseholdId = finalCreated.id;
        try {
          await _db.upsertHousehold(finalCreated);
          for (final l in initLedger) {
            await _db.insertDebtLedger(l);
          }
        } catch (_) {}
      }
    } catch (_) {
      // Ngoại tuyến (offline-first fallback)
      if (editId != null) {
        final idx = households.indexWhere((h) => h.id == editId);
        if (idx != -1) {
          households[idx] = households[idx].copyWith(
            name: name,
            headName: headName,
            phone: phone,
            address: address,
            creditLimit: creditLimit,
            currentDebt: initDebt,
            containerOwed: initContainerOwed,
            members: allMembers,
          );
          try {
            await _db.upsertHousehold(households[idx]);
          } catch (_) {}
        }
      } else {
        final newId = DateTime.now().millisecondsSinceEpoch % 1000000;
        final initLedger = <DebtLedgerEntry>[];
        if (initDebt > 0) {
          final entry = DebtLedgerEntry(
            id: newId + 1,
            householdId: newId,
            dateStr: '${AppFormatters.todayIsoDate()} 08:00',
            actorName: headName,
            description: 'Dư nợ đầu kỳ khi khởi tạo sổ',
            changeAmount: initDebt,
            balanceAfter: initDebt,
          );
          initLedger.add(entry);
        }
        final created = HouseholdModel(
          id: newId,
          name: name,
          headName: headName,
          phone: phone,
          address: address,
          creditLimit: creditLimit,
          currentDebt: initDebt,
          containerOwed: initContainerOwed,
          members: allMembers,
          ledger: initLedger,
        );
        households.insert(0, created);
        selectedHouseholdId = newId;
        try {
          await _db.upsertHousehold(created);
          for (final l in initLedger) {
            await _db.insertDebtLedger(l);
          }
        } catch (_) {}
      }
    }
    notifyListeners();
  }

  Future<void> addHouseholdMember(int householdId, String memberName) async {
    final idx = households.indexWhere((h) => h.id == householdId);
    if (idx == -1) return;
    final updatedMembers = [...households[idx].members, memberName];
    households[idx] = households[idx].copyWith(members: updatedMembers);
    try {
      await householdApi.updateHousehold(householdId, households[idx]);
    } catch (_) {}
    try {
      await _db.upsertHousehold(households[idx]);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> deleteHousehold(int householdId) async {
    try {
      await householdApi.deleteHousehold(householdId);
    } catch (_) {}
    households.removeWhere((h) => h.id == householdId);
    if (selectedHouseholdId == householdId) {
      selectedHouseholdId = households.isNotEmpty ? households.first.id : null;
    }
    try {
      await _db.deleteHousehold(householdId);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> collectHouseholdDebt({
    required int householdId,
    required int amount,
    required int containersReturned,
    required String method,
    required String note,
  }) async {
    final idx = households.indexWhere((h) => h.id == householdId);
    if (idx == -1) return;
    final hh = households[idx];

    try {
      await householdApi.collectDebt(
        householdId,
        amount: amount,
        containersReturned: containersReturned,
        actorName: hh.headName,
        method: method,
        note: note,
      );
    } catch (_) {}

    final nowId = DateTime.now().millisecondsSinceEpoch % 1000000;
    final fullDate = '${AppFormatters.todayIsoDate()} ${AppFormatters.currentTimeHm()}';

    final nextDebt = (hh.currentDebt - amount).clamp(0, 999999999);
    final nextContainer = (hh.containerOwed - containersReturned).clamp(0, 999999);

    final entry = DebtLedgerEntry(
      id: nowId,
      householdId: hh.id,
      dateStr: fullDate,
      actorName: hh.headName,
      description:
          '${note.isEmpty ? 'Thanh toán công nợ' : note} (${method == 'BANK' ? 'Chuyển khoản' : 'Tiền mặt'}${containersReturned > 0 ? ', Trả $containersReturned vỏ' : ''})',
      changeAmount: -amount,
      balanceAfter: nextDebt,
    );

    final nextLedger = [entry, ...hh.ledger];
    households[idx] = hh.copyWith(
      currentDebt: nextDebt,
      containerOwed: nextContainer,
      ledger: nextLedger,
    );

    try {
      await _db.upsertHousehold(households[idx]);
      await _db.insertDebtLedger(entry);
    } catch (_) {}

    if (amount > 0) {
      final tx = CashTxModel(
        id: nowId + 1,
        dateStr: fullDate,
        flow: 'IN',
        category: 'DEBT_COLLECTION',
        method: method,
        amount: amount,
        note: 'Thu nợ ${hh.name}: ${note.isEmpty ? 'Trả nợ' : note}',
      );
      cashTransactions.insert(0, tx);
      try {
        await _db.insertCashTransaction(tx);
      } catch (_) {}
    }
    notifyListeners();
  }

  // Manual Cash Transaction & Supplier Debt Payment
  Future<void> addManualCashTransaction({
    required String flow,
    required String category,
    required int amount,
    required String method,
    required String note,
    int? supplierId,
  }) async {
    final nowId = DateTime.now().millisecondsSinceEpoch % 1000000;
    final fullDate = '${AppFormatters.todayIsoDate()} ${AppFormatters.currentTimeHm()}';
    String resolvedNote = note;

    if (category == 'SUPPLIER_DEBT_PAY' && supplierId != null) {
      final sIdx = suppliers.indexWhere((s) => s.id == supplierId);
      if (sIdx != -1) {
        final sup = suppliers[sIdx];
        if (resolvedNote.isEmpty) {
          resolvedNote = 'Trả nợ tiền hàng cho ${sup.name}';
        }
        try {
          await catalogApi.paySupplierDebt(
            supplierId,
            amount: amount,
            note: resolvedNote,
            paymentMethod: method,
          );
        } catch (_) {}

        suppliers[sIdx] = sup.copyWith(
          payableDebt: (sup.payableDebt - amount).clamp(0, 999999999),
        );
        try {
          await _db.upsertSupplier(suppliers[sIdx]);
        } catch (_) {}
      }
    } else {
      try {
        await cashflowApi.createCashTransaction(CashTxModel(
          id: 0,
          dateStr: fullDate,
          flow: flow,
          category: category,
          method: method,
          amount: amount,
          note: resolvedNote.isEmpty
              ? (flow == 'IN' ? 'Phiếu thu bổ sung' : 'Chi phí vận hành cửa hàng')
              : resolvedNote,
        ));
      } catch (_) {}
    }

    final tx = CashTxModel(
      id: nowId,
      dateStr: fullDate,
      flow: flow,
      category: category,
      method: method,
      amount: amount,
      note: resolvedNote.isEmpty
          ? (flow == 'IN' ? 'Phiếu thu bổ sung' : 'Chi phí vận hành cửa hàng')
          : resolvedNote,
    );
    cashTransactions.insert(0, tx);
    try {
      await _db.insertCashTransaction(tx);
    } catch (_) {}
    notifyListeners();
  }

  // Điều chỉnh tồn kho qua API và đồng bộ
  Future<void> adjustProductStock(
    int productId, {
    required String operation, // 'ADD', 'SUBTRACT', 'SET'
    required double quantity,
    required String reason,
    String? note,
  }) async {
    try {
      await productApi.adjustStock(
        productId,
        operation: operation,
        quantity: quantity,
        reason: reason,
        note: note,
      );
    } catch (_) {}

    final idx = products.indexWhere((p) => p.id == productId);
    if (idx != -1) {
      final p = products[idx];
      double nextStock = p.stockQty;
      if (operation == 'ADD') {
        nextStock += quantity;
      } else if (operation == 'SUBTRACT') {
        nextStock = (nextStock - quantity).clamp(0.0, 9999999.0);
      } else if (operation == 'SET') {
        nextStock = quantity;
      }
      products[idx] = p.copyWith(stockQty: nextStock);
      try {
        await _db.upsertProduct(products[idx]);
      } catch (_) {}
      notifyListeners();
    }
  }

  // Làm mới toàn bộ dữ liệu từ server
  Future<void> refreshData() async {
    try {
      final remoteCategories = await catalogApi.getCategories();
      if (remoteCategories.isNotEmpty) categories = remoteCategories;

      final remoteSuppliers = await catalogApi.getSuppliers();
      if (remoteSuppliers.isNotEmpty) suppliers = remoteSuppliers;

      final remoteProducts = await productApi.getProducts();
      if (remoteProducts.isNotEmpty) products = remoteProducts;

      final remoteHouseholds = await householdApi.getHouseholds();
      if (remoteHouseholds.isNotEmpty) households = remoteHouseholds;

      final remoteOrders = await orderApi.getOrders();
      if (remoteOrders.isNotEmpty) orders = remoteOrders;

      final remoteCash = await cashflowApi.getCashTransactions();
      if (remoteCash.isNotEmpty) cashTransactions = remoteCash;

      final remoteSettings = await settingsApi.getSettings();
      storeConfig = remoteSettings;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> resetAllToBlank() async {
    categories.clear();
    suppliers.clear();
    products.clear();
    households.clear();
    posCart.clear();
    orders.clear();
    cashTransactions.clear();
    selectedCategoryId = null;
    selectedSupplierId = null;
    selectedHouseholdId = null;
    try {
      await _db.clearAllData();
    } catch (_) {}
    notifyListeners();
  }
}
