import '../models/cash_tx_model.dart';
import 'api_client.dart';
import 'api_constants.dart';

class CashflowApiService {
  final ApiClient apiClient;

  CashflowApiService({required this.apiClient});

  /// Lấy danh sách giao dịch dòng tiền thu chi
  Future<List<CashTxModel>> getCashTransactions({
    String? flow,
    String? method,
    String? category,
    String? startDate,
    String? endDate,
    int page = 1,
    int limit = 50,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (flow != null && flow.isNotEmpty) query['flow'] = flow;
    if (method != null && method.isNotEmpty) query['method'] = method;
    if (category != null && category.isNotEmpty) query['category'] = category;
    if (startDate != null && startDate.isNotEmpty) query['startDate'] = startDate;
    if (endDate != null && endDate.isNotEmpty) query['endDate'] = endDate;

    final response = await apiClient.get(
      ApiConstants.cashflow,
      queryParams: query,
    );

    if (response is Map<String, dynamic> && response['items'] is List) {
      final list = response['items'] as List;
      return list.map((item) {
        final map = item as Map<String, dynamic>;
        return CashTxModel(
          id: map['id'] as int,
          dateStr: map['dateStr'] as String? ?? '',
          flow: map['flow'] as String? ?? 'IN',
          category: map['category'] as String? ?? '',
          method: map['method'] as String? ?? 'CASH',
          amount: (map['amount'] as num?)?.toInt() ?? 0,
          note: map['note'] as String? ?? '',
        );
      }).toList();
    }
    return [];
  }

  /// Xem số dư tồn quỹ tiền mặt & tài khoản ngân hàng
  Future<Map<String, dynamic>> getFundBalance() async {
    final response = await apiClient.get('${ApiConstants.cashflow}/balance');
    return response as Map<String, dynamic>;
  }

  /// Ghi nhận giao dịch thu chi thủ công
  Future<CashTxModel> createCashTransaction(CashTxModel tx) async {
    final response = await apiClient.post(
      ApiConstants.cashflow,
      body: {
        'flow': tx.flow,
        'category': tx.category,
        'method': tx.method,
        'amount': tx.amount,
        'note': tx.note,
        'dateStr': tx.dateStr.contains(' ') ? tx.dateStr.split(' ')[0] : tx.dateStr,
      },
    );

    final map = response as Map<String, dynamic>;
    final txMap = (map['transaction'] as Map<String, dynamic>?) ?? map;

    return CashTxModel(
      id: txMap['id'] as int,
      dateStr: txMap['dateStr'] as String? ?? tx.dateStr,
      flow: txMap['flow'] as String? ?? tx.flow,
      category: txMap['category'] as String? ?? tx.category,
      method: txMap['method'] as String? ?? tx.method,
      amount: (txMap['amount'] as num?)?.toInt() ?? tx.amount,
      note: txMap['note'] as String? ?? tx.note,
    );
  }

  /// Xóa giao dịch thu chi
  Future<void> deleteCashTransaction(int id) async {
    await apiClient.delete('${ApiConstants.cashflow}/$id');
  }

  /// Báo cáo Kết quả Kinh doanh Lời - Lỗ (P&L)
  Future<Map<String, dynamic>> getProfitAndLoss({String? startDate, String? endDate}) async {
    final query = <String, dynamic>{};
    if (startDate != null && startDate.isNotEmpty) query['startDate'] = startDate;
    if (endDate != null && endDate.isNotEmpty) query['endDate'] = endDate;

    final response = await apiClient.get(
      ApiConstants.reportsPnl,
      queryParams: query.isNotEmpty ? query : null,
    );
    return response as Map<String, dynamic>;
  }

  /// Biểu đồ xu hướng doanh thu theo ngày
  Future<List<Map<String, dynamic>>> getDailyTrend({int days = 7}) async {
    final response = await apiClient.get(
      ApiConstants.reportsDailyTrend,
      queryParams: {'days': days},
    );
    if (response is List) {
      return response.map((e) => e as Map<String, dynamic>).toList();
    }
    return [];
  }
}
