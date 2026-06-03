import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/contracts/presentation/contracts_screen.dart';
import '../../features/invoices/presentation/invoices_screen.dart';
import '../../features/invoices/presentation/pay_screen.dart';
import '../../features/payments/presentation/payments_screen.dart';
import '../../features/tickets/presentation/tickets_screen.dart';
import '../../features/tickets/presentation/ticket_detail_screen.dart';
import '../../features/tickets/presentation/new_ticket_screen.dart';
import '../../features/auth/presentation/settings_screen.dart';
import '../../features/main/main_shell.dart';
import '../utils/storage.dart';

final router = GoRouter(
  initialLocation: '/home',
  redirect: (context, state) async {
    final token = await AppStorage.getToken();
    final isAuth = token != null;
    final isLoginRoute = state.matchedLocation == '/login';
    if (!isAuth && !isLoginRoute) return '/login';
    if (isAuth && isLoginRoute) return '/home';
    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
        GoRoute(path: '/contracts', builder: (_, __) => const ContractsScreen()),
        GoRoute(path: '/invoices', builder: (_, __) => const InvoicesScreen()),
        GoRoute(path: '/invoices/pay/:invoiceId/:url', builder: (_, state) {
          return PayScreen(
            invoiceId: int.parse(state.pathParameters['invoiceId']!),
            paymentUrl: Uri.decodeComponent(state.pathParameters['url']!),
          );
        }),
        GoRoute(path: '/payments', builder: (_, __) => const PaymentsScreen()),
        GoRoute(path: '/tickets', builder: (_, __) => const TicketsScreen()),
        GoRoute(path: '/tickets/new', builder: (_, __) => const NewTicketScreen()),
        GoRoute(path: '/tickets/:id', builder: (_, state) {
          return TicketDetailScreen(ticketId: int.parse(state.pathParameters['id']!));
        }),
        GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      ],
    ),
  ],
);
