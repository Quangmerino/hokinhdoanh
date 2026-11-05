import '../models/debt_ledger_entry.dart';
import '../models/household_model.dart';
import 'api_client.dart';
import 'api_constants.dart';

class HouseholdApiService {
  final ApiClient apiClient;

  HouseholdApiService({required this.apiClient});

  /// Lấy danh sách sổ nợ các hộ gia đình
  Future<List<HouseholdModel>> getHouseholds({String? search, bool? hasDebtOnly}) async {
    final query = <String, dynamic>{};
    if (search != null && search.isNotEmpty) query['search'] = search;
    if (hasDebtOnly == true) query['hasDebtOnly'] = 'true';

    final response = await apiClient.get(
      ApiConstants.households,
      queryParams: query.isNotEmpty ? query : null,
    );

    if (response is Map<String, dynamic> && response['households'] is List) {
      final list = response['households'] as List;
      return list.map((item) => _mapToHousehold(item as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// Lấy chi tiết sổ nợ kèm lịch sử
  Future<HouseholdModel> getHouseholdDetail(int id) async {
    final response = await apiClient.get('${ApiConstants.households}/$id');
    final map = response as Map<String, dynamic>;
    final rawLedgers = map['recentLedger'] as List<dynamic>? ?? [];
    final ledgers = rawLedgers.map((l) => _mapToLedger(l as Map<String, dynamic>)).toList();
    return _mapToHousehold(map, ledger: ledgers);
  }

  /// Lấy lịch sử biến động sổ nợ phân trang
  Future<List<DebtLedgerEntry>> getLedger(int id, {int page = 1, int limit = 50}) async {
    final response = await apiClient.get(
      '${ApiConstants.households}/$id/ledger',
      queryParams: {'page': page, 'limit': limit},
    );

    if (response is Map<String, dynamic> && response['items'] is List) {
      final list = response['items'] as List;
      return list.map((l) => _mapToLedger(l as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// Lấy tin nhắn mẫu nhắc nợ
  Future<String> getDebtNotice(int id) async {
    final response = await apiClient.get('${ApiConstants.households}/$id/debt-notice');
    final map = response as Map<String, dynamic>;
    return map['noticeMessage'] as String? ?? '';
  }

  /// Tạo sổ hộ gia đình mới
  Future<HouseholdModel> createHousehold(HouseholdModel household) async {
    final response = await apiClient.post(
      ApiConstants.households,
      body: {
        'name': household.name.trim(),
        'headName': household.headName.trim(),
        'phone': household.phone.trim().isEmpty ? null : household.phone.trim(),
        'address': household.address.trim().isEmpty ? null : household.address.trim(),
        'creditLimit': household.creditLimit,
        'currentDebt': household.currentDebt,
        'containerOwed': household.containerOwed,
        'members': household.members,
      },
    );

    final map = response as Map<String, dynamic>;
    final hhMap = (map['household'] as Map<String, dynamic>?) ?? map;
    return _mapToHousehold(hhMap);
  }

  /// Cập nhật sổ hộ gia đình
  Future<HouseholdModel> updateHousehold(int id, HouseholdModel household) async {
    final response = await apiClient.patch(
      '${ApiConstants.households}/$id',
      body: {
        'name': household.name.trim(),
        'headName': household.headName.trim(),
        'phone': household.phone.trim().isEmpty ? null : household.phone.trim(),
        'address': household.address.trim().isEmpty ? null : household.address.trim(),
        'creditLimit': household.creditLimit,
        'currentDebt': household.currentDebt,
        'containerOwed': household.containerOwed,
        'members': household.members,
      },
    );

    final map = response as Map<String, dynamic>;
    final hhMap = (map['household'] as Map<String, dynamic>?) ?? map;
    return _mapToHousehold(hhMap);
  }

  /// Thu nợ hộ gia đình & nhận trả vỏ két/bình
  Future<Map<String, dynamic>> collectDebt(
    int id, {
    required int amount,
    int containersReturned = 0,
    String? actorName,
    String method = 'CASH',
    String note = '',
  }) async {
    final response = await apiClient.post(
      '${ApiConstants.households}/$id/collect-debt',
      body: {
        'amount': amount,
        'containersReturned': containersReturned,
        'actorName': actorName,
        'method': method,
        'note': note,
      },
    );
    return response as Map<String, dynamic>;
  }

  /// Ghi nợ thêm cho hộ gia đình
  Future<Map<String, dynamic>> addDebt(
    int id, {
    required int amount,
    int containersTaken = 0,
    String? actorName,
    required String description,
  }) async {
    final response = await apiClient.post(
      '${ApiConstants.households}/$id/add-debt',
      body: {
        'amount': amount,
        'containersTaken': containersTaken,
        'actorName': actorName,
        'description': description,
      },
    );
    return response as Map<String, dynamic>;
  }

  /// Xóa sổ hộ gia đình
  Future<void> deleteHousehold(int id) async {
    await apiClient.delete('${ApiConstants.households}/$id');
  }

  HouseholdModel _mapToHousehold(Map<String, dynamic> map, {List<DebtLedgerEntry> ledger = const []}) {
    final rawMembers = map['members'] as List<dynamic>? ?? [];
    return HouseholdModel(
      id: map['id'] as int,
      name: map['name'] as String? ?? '',
      headName: map['headName'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      address: map['address'] as String? ?? '',
      creditLimit: (map['creditLimit'] as num?)?.toInt() ?? 20000000,
      currentDebt: (map['currentDebt'] as num?)?.toInt() ?? 0,
      containerOwed: (map['containerOwed'] as num?)?.toInt() ?? 0,
      members: rawMembers.map((e) => e.toString()).toList(),
      ledger: ledger,
    );
  }

  DebtLedgerEntry _mapToLedger(Map<String, dynamic> map) {
    return DebtLedgerEntry(
      id: map['id'] as int,
      householdId: map['householdId'] as int? ?? 0,
      dateStr: map['dateStr'] as String? ?? '',
      actorName: map['actorName'] as String? ?? '',
      description: map['description'] as String? ?? '',
      changeAmount: (map['changeAmount'] as num?)?.toInt() ?? 0,
      balanceAfter: (map['balanceAfter'] as num?)?.toInt() ?? 0,
    );
  }
}
