import '../models/order_record_model.dart';
import 'api_client.dart';
import 'api_constants.dart';

class OrderApiService {
  final ApiClient apiClient;

  OrderApiService({required this.apiClient});

  /// Thanh toán đơn hàng POS (Bán lẻ hoặc Nhập hàng)
  Future<Map<String, dynamic>> checkout({
    required String orderType, // 'SALE' or 'PURCHASE'
    required List<Map<String, dynamic>> items,
    int discount = 0,
    required int paidAmount,
    String paymentMethod = 'CASH',
    int? householdId,
    String? buyerMemberName,
    int? supplierId,
    int containerOwedDelta = 0,
    String note = '',
    String? dateStr,
  }) async {
    final response = await apiClient.post(
      ApiConstants.checkout,
      body: {
        'orderType': orderType,
        'items': items,
        'discount': discount,
        'paidAmount': paidAmount,
        'paymentMethod': paymentMethod,
        'householdId': householdId,
        'buyerMemberName': buyerMemberName,
        'supplierId': supplierId,
        'containerOwedDelta': containerOwedDelta,
        'note': note,
        'dateStr': dateStr,
      },
    );

    return response as Map<String, dynamic>;
  }

  /// Lấy danh sách lịch sử đơn hàng
  Future<List<OrderRecordModel>> getOrders({
    String? orderType,
    String? startDate,
    String? endDate,
    int page = 1,
    int limit = 50,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (orderType != null && orderType.isNotEmpty) query['orderType'] = orderType;
    if (startDate != null && startDate.isNotEmpty) query['startDate'] = startDate;
    if (endDate != null && endDate.isNotEmpty) query['endDate'] = endDate;

    final response = await apiClient.get(
      ApiConstants.orders,
      queryParams: query,
    );

    if (response is Map<String, dynamic> && response['orders'] is List) {
      final list = response['orders'] as List;
      return list.map((item) {
        final map = item as Map<String, dynamic>;
        return OrderRecordModel(
          id: map['id'] as int,
          dateStr: map['dateStr'] as String? ?? '',
          orderType: map['orderType'] as String? ?? 'SALE',
          categoryRootId: map['categoryRootId'] as int? ?? 0,
          totalAmount: (map['totalAmount'] as num?)?.toInt() ?? 0,
          cogs: (map['cogs'] as num?)?.toInt() ?? 0,
          paidAmount: (map['paidAmount'] as num?)?.toInt() ?? 0,
          debtAmount: (map['debtAmount'] as num?)?.toInt() ?? 0,
          description: map['description'] as String? ?? '',
        );
      }).toList();
    }
    return [];
  }

  /// Báo cáo tài chính doanh thu & giá vốn
  Future<Map<String, dynamic>> getOrderSummary() async {
    final response = await apiClient.get('${ApiConstants.orders}/summary');
    return response as Map<String, dynamic>;
  }
}
