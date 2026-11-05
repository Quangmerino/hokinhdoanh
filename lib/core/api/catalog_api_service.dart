import '../models/category_node.dart';
import '../models/supplier_model.dart';
import 'api_client.dart';
import 'api_constants.dart';

class CatalogApiService {
  final ApiClient apiClient;

  CatalogApiService({required this.apiClient});

  // ==================== CATEGORIES ====================

  /// Lấy danh sách danh mục từ backend
  Future<List<CategoryNode>> getCategories({bool asTree = false}) async {
    final response = await apiClient.get(
      ApiConstants.categories,
      queryParams: asTree ? {'tree': 'true'} : null,
    );

    if (response is List) {
      return response.map((item) {
        final map = item as Map<String, dynamic>;
        return CategoryNode(
          id: map['id'] as int,
          parentId: map['parentId'] as int?,
          name: map['name'] as String? ?? '',
          icon: map['icon'] as String? ?? '📦',
          materializedPath: map['materializedPath'] as String? ?? '/',
        );
      }).toList();
    }
    return [];
  }

  /// Tạo danh mục mới
  Future<CategoryNode> createCategory({
    required String name,
    String icon = '📦',
    int? parentId,
  }) async {
    final response = await apiClient.post(
      ApiConstants.categories,
      body: {
        'name': name.trim(),
        'icon': icon.trim(),
        'parentId': parentId,
      },
    );

    final map = response as Map<String, dynamic>;
    final catMap = (map['category'] as Map<String, dynamic>?) ?? map;

    return CategoryNode(
      id: catMap['id'] as int,
      parentId: catMap['parentId'] as int?,
      name: catMap['name'] as String? ?? name,
      icon: catMap['icon'] as String? ?? icon,
      materializedPath: catMap['materializedPath'] as String? ?? '/',
    );
  }

  /// Cập nhật danh mục
  Future<CategoryNode> updateCategory(
    int id, {
    String? name,
    String? icon,
    int? parentId,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name.trim();
    if (icon != null) body['icon'] = icon.trim();
    if (parentId != null) body['parentId'] = parentId;

    final response = await apiClient.patch(
      '${ApiConstants.categories}/$id',
      body: body,
    );

    final map = response as Map<String, dynamic>;
    return CategoryNode(
      id: map['id'] as int,
      parentId: map['parentId'] as int?,
      name: map['name'] as String? ?? (name ?? ''),
      icon: map['icon'] as String? ?? (icon ?? '📦'),
      materializedPath: map['materializedPath'] as String? ?? '/',
    );
  }

  /// Xóa danh mục
  Future<void> deleteCategory(int id) async {
    await apiClient.delete('${ApiConstants.categories}/$id');
  }

  // ==================== SUPPLIERS ====================

  /// Lấy danh sách nhà cung cấp
  Future<List<SupplierModel>> getSuppliers({String? search, int? categoryId}) async {
    final query = <String, dynamic>{};
    if (search != null && search.isNotEmpty) query['search'] = search;
    if (categoryId != null) query['categoryId'] = categoryId;

    final response = await apiClient.get(
      ApiConstants.suppliers,
      queryParams: query.isNotEmpty ? query : null,
    );

    if (response is Map<String, dynamic> && response['suppliers'] is List) {
      final list = response['suppliers'] as List;
      return list.map((item) {
        final map = item as Map<String, dynamic>;
        final rawCatIds = map['categoryIds'] as List<dynamic>? ?? [];
        return SupplierModel(
          id: map['id'] as int,
          name: map['name'] as String? ?? '',
          phone: map['phone'] as String? ?? '',
          address: map['address'] as String? ?? '',
          payableDebt: (map['payableDebt'] as num?)?.toInt() ?? 0,
          categoryIds: rawCatIds.map((e) => (e as num).toInt()).toList(),
        );
      }).toList();
    }
    return [];
  }

  /// Tạo nhà cung cấp mới
  Future<SupplierModel> createSupplier({
    required String name,
    String phone = '',
    String address = '',
    int payableDebt = 0,
    List<int> categoryIds = const [],
  }) async {
    final response = await apiClient.post(
      ApiConstants.suppliers,
      body: {
        'name': name.trim(),
        'phone': phone.trim().isEmpty ? null : phone.trim(),
        'address': address.trim().isEmpty ? null : address.trim(),
        'payableDebt': payableDebt,
        'categoryIds': categoryIds,
      },
    );

    final map = response as Map<String, dynamic>;
    final supMap = (map['supplier'] as Map<String, dynamic>?) ?? map;
    final rawCatIds = supMap['categoryIds'] as List<dynamic>? ?? categoryIds;

    return SupplierModel(
      id: supMap['id'] as int,
      name: supMap['name'] as String? ?? name,
      phone: supMap['phone'] as String? ?? phone,
      address: supMap['address'] as String? ?? address,
      payableDebt: (supMap['payableDebt'] as num?)?.toInt() ?? payableDebt,
      categoryIds: rawCatIds.map((e) => (e as num).toInt()).toList(),
    );
  }

  /// Cập nhật thông tin nhà cung cấp
  Future<SupplierModel> updateSupplier(
    int id, {
    String? name,
    String? phone,
    String? address,
    int? payableDebt,
    List<int>? categoryIds,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name.trim();
    if (phone != null) body['phone'] = phone.trim();
    if (address != null) body['address'] = address.trim();
    if (payableDebt != null) body['payableDebt'] = payableDebt;
    if (categoryIds != null) body['categoryIds'] = categoryIds;

    final response = await apiClient.patch(
      '${ApiConstants.suppliers}/$id',
      body: body,
    );

    final map = response as Map<String, dynamic>;
    final supMap = (map['supplier'] as Map<String, dynamic>?) ?? map;
    final rawCatIds = supMap['categoryIds'] as List<dynamic>? ?? [];

    return SupplierModel(
      id: supMap['id'] as int,
      name: supMap['name'] as String? ?? '',
      phone: supMap['phone'] as String? ?? '',
      address: supMap['address'] as String? ?? '',
      payableDebt: (supMap['payableDebt'] as num?)?.toInt() ?? 0,
      categoryIds: rawCatIds.map((e) => (e as num).toInt()).toList(),
    );
  }

  /// Thanh toán công nợ nhà cung cấp
  Future<Map<String, dynamic>> paySupplierDebt(
    int id, {
    required int amount,
    String? note,
    String paymentMethod = 'BANK',
  }) async {
    final response = await apiClient.post(
      '${ApiConstants.suppliers}/$id/pay-debt',
      body: {
        'amount': amount,
        'note': note,
        'paymentMethod': paymentMethod,
      },
    );
    return response as Map<String, dynamic>;
  }

  /// Xóa nhà cung cấp
  Future<void> deleteSupplier(int id) async {
    await apiClient.delete('${ApiConstants.suppliers}/$id');
  }
}
