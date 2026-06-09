import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import 'community_model.dart';

class CommunityRepository {
  final ApiClient _api;
  CommunityRepository(this._api);

  Future<List<PublicClient>> ourClients() async {
    final res = await _api.dio.get('/community/clients');
    return (res.data as List).map((e) => PublicClient.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<LeaderboardData> leaderboard() async {
    final res = await _api.dio.get('/community/leaderboard');
    return LeaderboardData.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> clientProfile(int id) async {
    final res = await _api.dio.get('/community/clients/$id');
    return res.data as Map<String, dynamic>;
  }

  Future<void> follow(int id) => _api.dio.post('/community/clients/$id/follow');
  Future<void> unfollow(int id) => _api.dio.post('/community/clients/$id/unfollow');

  Future<void> requestVisibility(String scope) =>
      _api.dio.post('/community/visibility-request', data: {'scope': scope});
}

final communityRepositoryProvider = Provider((ref) => CommunityRepository(ApiClient()));

final ourClientsProvider = FutureProvider<List<PublicClient>>((ref) =>
    ref.watch(communityRepositoryProvider).ourClients());

final leaderboardProvider = FutureProvider<LeaderboardData>((ref) =>
    ref.watch(communityRepositoryProvider).leaderboard());

final clientProfileProvider = FutureProvider.family<Map<String, dynamic>, int>((ref, id) =>
    ref.watch(communityRepositoryProvider).clientProfile(id));
