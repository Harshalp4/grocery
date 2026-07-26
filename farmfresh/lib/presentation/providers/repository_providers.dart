import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/assistant_repository_impl.dart';
import '../../data/repositories/catalog_repository_impl.dart';
import '../../data/repositories/kirana_repository_impl.dart';
import '../../data/repositories/mock_address_repository.dart';
import '../../data/repositories/mock_auth_repository.dart';
import '../../data/repositories/mock_cart_repository.dart';
import '../../data/repositories/mock_notification_repository.dart';
import '../../data/repositories/mock_order_repository.dart';
import '../../data/repositories/mock_support_repository.dart';
import '../../domain/entities/address.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/entities/customer_order.dart';
import '../../domain/entities/promo_banner.dart';
import '../../domain/entities/support_ticket.dart';
import '../../domain/repositories/address_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/cart_repository.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../domain/repositories/support_repository.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/combo_pack.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/subscription_plan.dart';
import '../../domain/repositories/assistant_repository.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../../domain/repositories/kirana_repository.dart';
import '../../domain/repositories/order_repository.dart';

/// Dependency-injection seam. To go live, override these with remote
/// implementations (e.g. in `main()` via `ProviderScope(overrides: [...])`).
final catalogRepositoryProvider = Provider<CatalogRepository>(
  (ref) => const MockCatalogRepository(),
);

final kiranaRepositoryProvider = Provider<KiranaRepository>(
  (ref) => const MockKiranaRepository(),
);

final assistantRepositoryProvider = Provider<AssistantRepository>(
  (ref) => const MockAssistantRepository(),
);

final orderRepositoryProvider = Provider<OrderRepository>(
  (ref) => const MockOrderRepository(),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => const MockAuthRepository(),
);

final addressRepositoryProvider = Provider<AddressRepository>(
  (ref) => const MockAddressRepository(),
);

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => const MockNotificationRepository(),
);

final supportRepositoryProvider = Provider<SupportRepository>(
  (ref) => const MockSupportRepository(),
);

final cartRepositoryProvider = Provider<CartRepository>(
  (ref) => const MockCartRepository(),
);

/// The signed-in user's order history (My Orders).
final myOrdersProvider = FutureProvider<List<CustomerOrder>>(
  (ref) => ref.watch(orderRepositoryProvider).myOrders(),
);

/// The user's saved addresses.
final addressesProvider = FutureProvider<List<Address>>(
  (ref) => ref.watch(addressRepositoryProvider).list(),
);

/// A single order with its tracking timeline (My Orders → detail).
final orderDetailProvider = FutureProvider.family<CustomerOrder, String>(
  (ref, id) => ref.watch(orderRepositoryProvider).orderDetail(id),
);

/// Serviceability for a pincode (checkout).
final serviceableProvider = FutureProvider.family<ServiceCheck, String>(
  (ref, pincode) => ref.watch(orderRepositoryProvider).checkServiceable(pincode),
);

/// Available delivery slots.
final deliverySlotsProvider = FutureProvider<List<String>>(
  (ref) => ref.watch(orderRepositoryProvider).deliverySlots(),
);

/// Async catalog reads, consumed by the screens via `ref.watch`.
final categoriesProvider = FutureProvider<List<Category>>(
  (ref) => ref.watch(catalogRepositoryProvider).getCategories(),
);

final productsProvider = FutureProvider<List<Product>>(
  (ref) => ref.watch(catalogRepositoryProvider).getProducts(),
);

final bannersProvider = FutureProvider<List<PromoBanner>>(
  (ref) => ref.watch(catalogRepositoryProvider).getBanners(),
);

final subscriptionsProvider = FutureProvider<List<SubscriptionPlan>>(
  (ref) => ref.watch(catalogRepositoryProvider).getSubscriptions(),
);

final combosProvider = FutureProvider.family<List<ComboPack>, ComboType>(
  (ref, type) => ref.watch(catalogRepositoryProvider).getCombos(type),
);

/// The signed-in customer's wishlist / favorites.
final wishlistProvider = FutureProvider<List<Product>>(
  (ref) => ref.watch(catalogRepositoryProvider).getWishlist(),
);

/// Notification inbox + unread badge count.
final notificationsProvider = FutureProvider<List<AppNotification>>(
  (ref) => ref.watch(notificationRepositoryProvider).list(),
);

final unreadCountProvider = FutureProvider<int>(
  (ref) => ref.watch(notificationRepositoryProvider).unreadCount(),
);

/// The signed-in customer's support tickets.
final myTicketsProvider = FutureProvider<List<SupportTicket>>(
  (ref) => ref.watch(supportRepositoryProvider).myTickets(),
);
