import '../models/product_model.dart';
import 'api_client.dart';
import 'api_constants.dart';

class ProductApiService {
  final ApiClient apiClient;

  ProductApiService({required this.apiClient});

  /// Lấy danh sách sản phẩm từ backend
  Future<List<ProductModel>> getProducts({
    String? search,
    int? categoryId,
    int? supplierId,
    bool? lowStockOnly,
    int page = 1,
    int limit = 100,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (search != null && search.isNotEmpty) query['search'] = search;
    if (categoryId != null) query['categoryId'] = categoryId;
    if (supplierId != null) query['supplierId'] = supplierId;
    if (lowStockOnly == true) query['lowStockOnly'] = 'true';

    final response = await apiClient.get(
      ApiConstants.products,
      queryParams: query,
    );

    if (response is Map<String, dynamic> && response['items'] is List) {
      final items = response['items'] as List;
      return items.map((item) => _mapToProduct(item as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// Lấy báo cáo tồn kho & định giá
  Future<Map<String, dynamic>> getInventorySummary() async {
    final response = await apiClient.get('${ApiConstants.products}/summary/inventory-value');
    return response as Map<String, dynamic>;
  }

  /// Lấy danh sách sản phẩm chạm ngưỡng tồn kho an toàn
  Future<List<ProductModel>> getLowStockAlerts() async {
    final response = await apiClient.get('${ApiConstants.products}/alerts/low-stock');
    if (response is Map<String, dynamic> && response['items'] is List) {
      final items = response['items'] as List;
      return items.map((item) => _mapToProduct(item as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// Tạo sản phẩm mới
  Future<ProductModel> createProduct(ProductModel product) async {
    final response = await apiClient.post(
      ApiConstants.products,
      body: {
        'sku': product.sku.trim().isEmpty ? null : product.sku.trim(),
        'name': product.name.trim(),
        'categoryId': product.categoryId,
        'primarySupplierId': product.primarySupplierId > 0 ? product.primarySupplierId : null,
        'supplierIds': product.supplierIds,
        'baseUnit': product.baseUnit.trim(),
        'stockQty': product.stockQty,
        'minStock': product.minStock,
        'costPrice': product.costPrice,
        'retailPrice': product.retailPrice,
        'packUnitName': product.packUnitName.trim().isEmpty ? null : product.packUnitName.trim(),
        'packRate': product.packRate,
        'packPrice': product.packPrice,
        'trackShell': product.trackReturnableShell,
        'specNote': product.specNote.trim().isEmpty ? null : product.specNote.trim(),
        'imagePath': product.imagePath,
      },
    );

    final map = response as Map<String, dynamic>;
    final pMap = (map['product'] as Map<String, dynamic>?) ?? map;
    return _mapToProduct(pMap);
  }

  /// Cập nhật thông tin sản phẩm
  Future<ProductModel> updateProduct(int id, ProductModel product) async {
    final response = await apiClient.patch(
      '${ApiConstants.products}/$id',
      body: {
        'sku': product.sku.trim(),
        'name': product.name.trim(),
        'categoryId': product.categoryId,
        'primarySupplierId': product.primarySupplierId > 0 ? product.primarySupplierId : null,
        'supplierIds': product.supplierIds,
        'baseUnit': product.baseUnit.trim(),
        'stockQty': product.stockQty,
        'minStock': product.minStock,
        'costPrice': product.costPrice,
        'retailPrice': product.retailPrice,
        'packUnitName': product.packUnitName.trim().isEmpty ? null : product.packUnitName.trim(),
        'packRate': product.packRate,
        'packPrice': product.packPrice,
        'trackShell': product.trackReturnableShell,
        'specNote': product.specNote.trim().isEmpty ? null : product.specNote.trim(),
        'imagePath': product.imagePath,
      },
    );

    final map = response as Map<String, dynamic>;
    final pMap = (map['product'] as Map<String, dynamic>?) ?? map;
    return _mapToProduct(pMap);
  }

  /// Điều chỉnh tồn kho (Kiểm kê, hao hụt, nhập thêm)
  Future<Map<String, dynamic>> adjustStock(
    int id, {
    required String operation, // 'ADD', 'SUBTRACT', 'SET'
    required double quantity,
    required String reason,
    String? note,
  }) async {
    final response = await apiClient.post(
      '${ApiConstants.products}/$id/adjust-stock',
      body: {
        'operation': operation,
        'quantity': quantity,
        'reason': reason,
        'note': note,
      },
    );
    return response as Map<String, dynamic>;
  }

  /// Xóa sản phẩm
  Future<void> deleteProduct(int id) async {
    await apiClient.delete('${ApiConstants.products}/$id');
  }

  ProductModel _mapToProduct(Map<String, dynamic> map) {
    final rawSupIds = map['supplierIds'] as List<dynamic>? ?? [];
    return ProductModel(
      id: map['id'] as int,
      sku: map['sku'] as String? ?? '',
      name: map['name'] as String? ?? '',
      categoryId: (map['categoryId'] as num?)?.toInt() ?? 0,
      primarySupplierId: (map['primarySupplierId'] as num?)?.toInt() ?? 0,
      supplierIds: rawSupIds.map((e) => (e as num).toInt()).toList(),
      baseUnit: map['baseUnit'] as String? ?? 'Cái',
      stockQty: (map['stockQty'] as num?)?.toDouble() ?? 0.0,
      minStock: (map['minStock'] as num?)?.toDouble() ?? 5.0,
      costPrice: (map['costPrice'] as num?)?.toInt() ?? 0,
      retailPrice: (map['retailPrice'] as num?)?.toInt() ?? 0,
      packUnitName: map['packUnitName'] as String? ?? '',
      packRate: (map['packRate'] as num?)?.toDouble() ?? 1.0,
      packPrice: (map['packPrice'] as num?)?.toInt() ?? 0,
      trackReturnableShell: map['trackShell'] as bool? ?? false,
      specNote: map['specNote'] as String? ?? '',
      imagePath: map['imagePath'] as String?,
    );
  }
}
