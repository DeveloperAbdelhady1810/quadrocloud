import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import 'post_model.dart';
import 'service_model.dart';

class ExploreRepository {
  final ApiClient _api;
  ExploreRepository(this._api);

  Future<List<PostModel>> getPosts() async {
    final res = await _api.dio.get('/posts');
    final data = res.data['data'] as List;
    return data.map((e) => PostModel.fromJson(e)).toList();
  }

  Future<List<ServiceModel>> getServices() async {
    final res = await _api.dio.get('/services/public');
    return (res.data as List).map((e) => ServiceModel.fromJson(e)).toList();
  }

  Future<void> requestService({
    required int serviceId,
    required String name,
    required String email,
    required String phone,
    String message = '',
  }) async {
    await _api.dio.post('/services/$serviceId/request', data: {
      'name': name,
      'email': email,
      'phone': phone,
      'message': message,
    });
  }
}

final exploreRepositoryProvider = Provider((ref) => ExploreRepository(ApiClient()));
final postsProvider = FutureProvider<List<PostModel>>((ref) => ref.read(exploreRepositoryProvider).getPosts());
final servicesProvider = FutureProvider<List<ServiceModel>>((ref) => ref.read(exploreRepositoryProvider).getServices());
