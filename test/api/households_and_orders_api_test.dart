import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:ho_kinh_doanh/core/api/api_client.dart';
import 'package:ho_kinh_doanh/core/api/cashflow_api_service.dart';
import 'package:ho_kinh_doanh/core/api/household_api_service.dart';
import 'package:ho_kinh_doanh/core/api/order_api_service.dart';
import 'package:ho_kinh_doanh/core/models/household_model.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('Households, Orders, and Cashflow API Tests', () {
    test('HouseholdApiService households CRUD & collect debt', () async {
      final mockClient = MockClient((request) async {
        if (request.method == 'GET' && request.url.path.endsWith('/households')) {
          return http.Response(
            jsonEncode({
              'households': [
                {
                  'id': 101,
                  'name': 'Hộ Chú Ba Xóm Chợ',
                  'headName': 'Chú Ba',
                  'phone': '0901234567',
                  'address': 'Khu A',
                  'creditLimit': 15000000,
                  'currentDebt': 3500000,
                  'containerOwed': 4,
                  'members': ['Chú Ba (Chủ hộ)', 'Thím Ba', 'Cu Tèo'],
                }
              ]
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        } else if (request.method == 'POST' && request.url.path.contains('/collect-debt')) {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['amount'], 2000000);
          expect(body['containersReturned'], 2);
          return http.Response(
            jsonEncode({
              'message': 'Thu nợ thành công',
              'remainingDebt': 1500000,
              'remainingContainers': 2,
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(httpClient: mockClient);
      final householdApi = HouseholdApiService(apiClient: apiClient);

      final households = await householdApi.getHouseholds();
      expect(households.length, 1);
      expect(households.first.headName, 'Chú Ba');
      expect(households.first.currentDebt, 3500000);
      expect(households.first.containerOwed, 4);

      final collectRes = await householdApi.collectDebt(
        101,
        amount: 2000000,
        containersReturned: 2,
        method: 'CASH',
        note: 'Trả bớt nợ',
      );
      expect(collectRes['remainingDebt'], 1500000);
      expect(collectRes['remainingContainers'], 2);
    });

    test('OrderApiService checkout & getOrders', () async {
      final mockClient = MockClient((request) async {
        if (request.method == 'POST' && request.url.path.endsWith('/orders/checkout')) {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['orderType'], 'SALE');
          expect(body['paidAmount'], 150000);
          return http.Response(
            jsonEncode({
              'message': 'Thanh toán đơn hàng thành công',
              'order': {
                'id': 501,
                'orderType': 'SALE',
                'totalAmount': 150000,
                'cogs': 120000,
                'paidAmount': 150000,
                'debtAmount': 0,
                'dateStr': '2026-11-05 14:00',
              }
            }),
            201,
            headers: {'content-type': 'application/json'},
          );
        } else if (request.method == 'GET' && request.url.path.endsWith('/orders')) {
          return http.Response(
            jsonEncode({
              'orders': [
                {
                  'id': 501,
                  'orderType': 'SALE',
                  'categoryRootId': 1,
                  'totalAmount': 150000,
                  'cogs': 120000,
                  'paidAmount': 150000,
                  'debtAmount': 0,
                  'dateStr': '2026-11-05 14:00',
                  'description': '1 Thùng Bia Hà Nội',
                }
              ]
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(httpClient: mockClient);
      final orderApi = OrderApiService(apiClient: apiClient);

      final checkoutRes = await orderApi.checkout(
        orderType: 'SALE',
        items: [
          {'productId': 10, 'quantity': 1, 'isPack': true, 'price': 150000}
        ],
        paidAmount: 150000,
        paymentMethod: 'CASH',
      );
      expect(checkoutRes['order']['id'], 501);

      final orders = await orderApi.getOrders();
      expect(orders.length, 1);
      expect(orders.first.totalAmount, 150000);
      expect(orders.first.cogs, 120000);
    });

    test('CashflowApiService cash transactions & fund balance', () async {
      final mockClient = MockClient((request) async {
        if (request.method == 'GET' && request.url.path.endsWith('/cashflow/balance')) {
          return http.Response(
            jsonEncode({
              'cash': 25000000,
              'bank': 80000000,
              'total': 105000000,
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        } else if (request.method == 'GET' && request.url.path.endsWith('/reports/pnl')) {
          return http.Response(
            jsonEncode({
              'revenue': 50000000,
              'cogs': 38000000,
              'grossProfit': 12000000,
              'operatingExpenses': 3000000,
              'netProfit': 9000000,
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(httpClient: mockClient);
      final cashflowApi = CashflowApiService(apiClient: apiClient);

      final balance = await cashflowApi.getFundBalance();
      expect(balance['cash'], 25000000);
      expect(balance['bank'], 80000000);
      expect(balance['total'], 105000000);

      final pnl = await cashflowApi.getProfitAndLoss();
      expect(pnl['revenue'], 50000000);
      expect(pnl['netProfit'], 9000000);
    });
  });
}
