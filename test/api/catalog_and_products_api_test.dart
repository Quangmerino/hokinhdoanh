import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:ho_kinh_doanh/core/api/api_client.dart';
import 'package:ho_kinh_doanh/core/api/catalog_api_service.dart';
import 'package:ho_kinh_doanh/core/api/product_api_service.dart';
import 'package:ho_kinh_doanh/core/models/category_node.dart';
import 'package:ho_kinh_doanh/core/models/product_model.dart';
import 'package:ho_kinh_doanh/core/models/supplier_model.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('CatalogApiService & ProductApiService Tests', () {
    test('CatalogApiService categories CRUD', () async {
      final mockClient = MockClient((request) async {
        if (request.method == 'GET' && request.url.path.endsWith('/categories')) {
          return http.Response(
            jsonEncode([
              {
                'id': 1,
                'name': 'Bia, Nước giải khát',
                'icon': '🍺',
                'parentId': null,
                'materializedPath': '/1/',
              },
              {
                'id': 2,
                'name': 'Bia lon',
                'icon': '🥫',
                'parentId': 1,
                'materializedPath': '/1/2/',
              }
            ]),
            200,
            headers: {'content-type': 'application/json'},
          );
        } else if (request.method == 'POST' && request.url.path.endsWith('/categories')) {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              'category': {
                'id': 3,
                'name': body['name'],
                'icon': body['icon'],
                'parentId': body['parentId'],
                'materializedPath': '/3/',
              }
            }),
            201,
            headers: {'content-type': 'application/json'},
          );
        } else if (request.method == 'DELETE') {
          return http.Response(jsonEncode({'message': 'Category deleted successfully'}), 200,
              headers: {'content-type': 'application/json'});
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(httpClient: mockClient);
      final catalogApi = CatalogApiService(apiClient: apiClient);

      final categories = await catalogApi.getCategories();
      expect(categories.length, 2);
      expect(categories.first.name, 'Bia, Nước giải khát');

      final created = await catalogApi.createCategory(name: 'Gia vị thực phẩm', icon: '🧂');
      expect(created.id, 3);
      expect(created.name, 'Gia vị thực phẩm');

      await expectLater(catalogApi.deleteCategory(3), completes);
    });

    test('CatalogApiService suppliers CRUD & debt payment', () async {
      final mockClient = MockClient((request) async {
        if (request.method == 'GET' && request.url.path.endsWith('/suppliers')) {
          return http.Response(
            jsonEncode({
              'suppliers': [
                {
                  'id': 1,
                  'name': 'Đại lý Bia Hà Nội',
                  'phone': '0912345678',
                  'address': 'Hà Nội',
                  'payableDebt': 15000000,
                  'categoryIds': [1, 2],
                }
              ]
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        } else if (request.method == 'POST' && request.url.path.contains('/pay-debt')) {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['amount'], 5000000);
          return http.Response(
            jsonEncode({
              'message': 'Thanh toán công nợ nhà cung cấp thành công',
              'amount': 5000000,
              'remainingDebt': 10000000,
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(httpClient: mockClient);
      final catalogApi = CatalogApiService(apiClient: apiClient);

      final suppliers = await catalogApi.getSuppliers();
      expect(suppliers.length, 1);
      expect(suppliers.first.name, 'Đại lý Bia Hà Nội');
      expect(suppliers.first.payableDebt, 15000000);

      final payRes = await catalogApi.paySupplierDebt(1, amount: 5000000, note: 'Trả tiền bia');
      expect(payRes['remainingDebt'], 10000000);
    });

    test('ProductApiService products CRUD & stock adjustment', () async {
      final mockClient = MockClient((request) async {
        if (request.method == 'GET' && request.url.path.endsWith('/products')) {
          return http.Response(
            jsonEncode({
              'items': [
                {
                  'id': 10,
                  'sku': 'BIA-HN-LON',
                  'name': 'Bia Hà Nội Lon 330ml',
                  'categoryId': 1,
                  'primarySupplierId': 1,
                  'supplierIds': [1],
                  'baseUnit': 'Lon',
                  'stockQty': 48.0,
                  'minStock': 24.0,
                  'costPrice': 10000,
                  'retailPrice': 12000,
                  'packUnitName': 'Thùng',
                  'packRate': 24.0,
                  'packPrice': 270000,
                  'trackShell': false,
                  'specNote': 'Lon 330ml 24 lon/thùng',
                }
              ]
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        } else if (request.method == 'POST' && request.url.path.contains('/adjust-stock')) {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['operation'], 'ADD');
          expect(body['quantity'], 24.0);
          return http.Response(
            jsonEncode({
              'message': 'Điều chỉnh tồn kho thành công',
              'productId': 10,
              'stockQty': 72.0,
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(httpClient: mockClient);
      final productApi = ProductApiService(apiClient: apiClient);

      final products = await productApi.getProducts();
      expect(products.length, 1);
      expect(products.first.name, 'Bia Hà Nội Lon 330ml');
      expect(products.first.packUnitName, 'Thùng');
      expect(products.first.packRate, 24.0);

      final adjustRes = await productApi.adjustStock(
        10,
        operation: 'ADD',
        quantity: 24.0,
        reason: 'Nhập bổ sung',
      );
      expect(adjustRes['stockQty'], 72.0);
    });
  });
}
