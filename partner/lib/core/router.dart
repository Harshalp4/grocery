import 'package:go_router/go_router.dart';

import '../features/history_page.dart';
import '../features/login_page.dart';
import '../features/order_detail_page.dart';
import '../features/orders_page.dart';
import '../features/profile_page.dart';
import '../features/set_password_page.dart';
import '../features/shell.dart';
import '../features/splash_page.dart';

GoRouter buildRouter() => GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, __) => const SplashPage()),
        GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
        GoRoute(
            path: '/set-password',
            builder: (_, __) => const SetPasswordPage()),
        GoRoute(
          path: '/orders/:id',
          builder: (_, s) => OrderDetailPage(orderId: s.pathParameters['id']!),
        ),
        ShellRoute(
          builder: (_, __, child) => Shell(child: child),
          routes: [
            GoRoute(path: '/orders', builder: (_, __) => const OrdersPage()),
            GoRoute(path: '/history', builder: (_, __) => const HistoryPage()),
            GoRoute(path: '/profile', builder: (_, __) => const ProfilePage()),
          ],
        ),
      ],
    );
