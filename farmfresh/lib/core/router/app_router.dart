import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/features/ai/ai_assistant_page.dart';
import '../../presentation/features/auth/login_page.dart';
import '../../presentation/features/cart/cart_page.dart';
import '../../presentation/features/cart/checkout_page.dart';
import '../../presentation/features/combos/combos_page.dart';
import '../../presentation/features/home/home_page.dart';
import '../../presentation/features/kirana/kirana_page.dart';
import '../../presentation/features/addresses/addresses_page.dart';
import '../../presentation/features/orders/my_orders_page.dart';
import '../../presentation/features/orders/order_detail_page.dart';
import '../../presentation/features/products/product_detail_page.dart';
import '../../presentation/features/products/products_page.dart';
import '../../presentation/features/profile/profile_page.dart';
import '../../presentation/features/repeat/repeat_page.dart';
import '../../presentation/features/shell/main_shell.dart';
import '../../presentation/features/splash/splash_page.dart';
import '../../presentation/features/subscriptions/subscriptions_page.dart';

/// Central navigation config. A [StatefulShellRoute] hosts the 6 bottom-nav
/// tabs (each keeps its own navigation state); splash/login sit outside the
/// shell so the bottom bar is hidden there — exactly like the wireframe.
abstract class AppRouter {
  static final _rootKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, __) => const SplashPage()),
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => MainShell(shell: shell),
        branches: [
          // 0 — Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (_, __) => const HomePage(),
                routes: [
                  GoRoute(path: 'combos', builder: (_, __) => const CombosPage()),
                  GoRoute(path: 'repeat', builder: (_, __) => const RepeatPage()),
                  GoRoute(
                    path: 'subscriptions',
                    builder: (_, __) => const SubscriptionsPage(),
                  ),
                  GoRoute(
                    path: 'detail/:id',
                    builder: (_, s) =>
                        ProductDetailPage(productId: s.pathParameters['id']!),
                  ),
                ],
              ),
            ],
          ),
          // 1 — Categories / Products
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/products',
                builder: (_, __) => const ProductsPage(),
                routes: [
                  GoRoute(
                    path: 'detail/:id',
                    builder: (_, s) =>
                        ProductDetailPage(productId: s.pathParameters['id']!),
                  ),
                ],
              ),
            ],
          ),
          // 2 — Auto Kirana List
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/kirana', builder: (_, __) => const KiranaPage()),
            ],
          ),
          // 3 — AI Assistant
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/ai', builder: (_, __) => const AiAssistantPage()),
            ],
          ),
          // 4 — Cart
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/cart',
                builder: (_, __) => const CartPage(),
                routes: [
                  GoRoute(
                    path: 'checkout',
                    builder: (_, __) => const CheckoutPage(),
                  ),
                ],
              ),
            ],
          ),
          // 5 — Profile
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (_, __) => const ProfilePage(),
                routes: [
                  GoRoute(
                    path: 'orders',
                    builder: (_, __) => const MyOrdersPage(),
                    routes: [
                      GoRoute(
                        path: ':id',
                        builder: (_, s) =>
                            OrderDetailPage(orderId: s.pathParameters['id']!),
                      ),
                    ],
                  ),
                  GoRoute(
                      path: 'addresses',
                      builder: (_, __) => const AddressesPage()),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
