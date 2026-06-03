import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import 'ticket_model.dart';

class TicketRepository {
  final ApiClient _api;
  TicketRepository(this._api);

  Future<List<TicketModel>> getTickets() async {
    final res = await _api.dio.get('/tickets');
    return (res.data as List).map((e) => TicketModel.fromJson(e)).toList();
  }

  Future<TicketModel> getTicket(int id) async {
    final res = await _api.dio.get('/tickets/$id');
    return TicketModel.fromJson(res.data);
  }

  Future<void> createTicket(String title, String message) async {
    await _api.dio.post('/tickets', data: {'title': title, 'message': message});
  }

  Future<void> reply(int ticketId, String message) async {
    await _api.dio.post('/tickets/$ticketId/reply', data: {'message': message});
  }
}

final ticketRepositoryProvider = Provider((ref) => TicketRepository(ApiClient()));

final ticketsProvider = FutureProvider<List<TicketModel>>((ref) async {
  return ref.read(ticketRepositoryProvider).getTickets();
});

final ticketDetailProvider = FutureProvider.family<TicketModel, int>((ref, id) async {
  return ref.read(ticketRepositoryProvider).getTicket(id);
});
