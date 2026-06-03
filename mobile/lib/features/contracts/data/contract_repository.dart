import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import 'contract_model.dart';

class ContractRepository {
  final ApiClient _api;
  ContractRepository(this._api);

  Future<List<ContractModel>> getContracts() async {
    final res = await _api.dio.get('/contracts');
    return (res.data as List).map((e) => ContractModel.fromJson(e)).toList();
  }
}

final contractRepositoryProvider = Provider((ref) => ContractRepository(ApiClient()));

final contractsProvider = FutureProvider<List<ContractModel>>((ref) async {
  return ref.read(contractRepositoryProvider).getContracts();
});
