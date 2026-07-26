import '../../domain/entities/basket_line.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/combo_pack.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/review.dart';
import '../../domain/entities/subscription_plan.dart';

/// Static seed data lifted verbatim from `mobile-wireframe.html` so the app
/// matches the approved prototype. When the API is attached, a remote data
/// source replaces this file; the repositories and UI stay unchanged.
abstract class MockData {
  static const categories = <Category>[
    Category(emoji: '🍚', name: 'Rice'),
    Category(emoji: '🫘', name: 'Dal & Pulses'),
    Category(emoji: '🌾', name: 'Wheat & Flour'),
    Category(emoji: '🛢️', name: 'Oils & Ghee'),
    Category(emoji: '🌶️', name: 'Spices'),
    Category(emoji: '🌱', name: 'Millets'),
    Category(emoji: '☕', name: 'Tea & Coffee'),
    Category(emoji: '🍯', name: 'Sugar & Jaggery'),
  ];

  static const products = <Product>[
    Product(
      id: 'toor-dal',
      name: 'Premium Toor Dal',
      source: 'Vidarbha, MH',
      packedDate: '10 Jun',
      price: 160,
      marketPrice: 198,
      grade: 'Premium A',
      tags: ['best', 'premium'],
      harvestMonth: 'March 2026',
      packSize: '1 kg',
      nutrition: {
        'Protein': '22 g',
        'Carbohydrates': '63 g',
        'Fibre': '15 g',
        'Energy': '343 kcal',
      },
    ),
    Product(
      id: 'wheat-flour',
      name: 'Farm Wheat Flour',
      source: 'Own farm, Nashik',
      packedDate: '12 Jun',
      price: 255,
      marketPrice: 320,
      grade: 'Chakki Fresh',
      tags: ['best', 'fresh'],
      packSize: '10 kg',
    ),
    Product(
      id: 'basmati-rice',
      name: 'Premium Basmati Rice',
      source: 'Haryana mills',
      packedDate: '08 Jun',
      price: 540,
      marketPrice: 640,
      grade: 'Aged 1yr',
      tags: ['best', 'premium'],
      packSize: '5 kg',
    ),
    Product(
      id: 'groundnut-oil',
      name: 'Groundnut Oil',
      source: 'Saurashtra',
      packedDate: '05 Jun',
      price: 1150,
      marketPrice: 1320,
      grade: 'Cold pressed',
      tags: ['premium'],
      packSize: '5 L',
    ),
    Product(
      id: 'jaggery-powder',
      name: 'Jaggery Powder',
      source: 'Kolhapur',
      packedDate: '11 Jun',
      price: 95,
      marketPrice: 120,
      grade: 'Chemical-free',
      tags: ['fresh'],
      packSize: '1 kg',
    ),
    Product(
      id: 'chilli-powder',
      name: 'Red Chilli Powder',
      source: 'Guntur',
      packedDate: '09 Jun',
      price: 240,
      marketPrice: 295,
      grade: 'Premium',
      tags: ['premium'],
      packSize: '500 g',
    ),
    Product(
      id: 'moong-dal',
      name: 'Moong Dal',
      source: 'Rajasthan',
      packedDate: '10 Jun',
      price: 140,
      marketPrice: 175,
      grade: 'Premium A',
      tags: ['best'],
      packSize: '1 kg',
    ),
    Product(
      id: 'ragi-flour',
      name: 'Ragi Flour',
      source: 'Karnataka',
      packedDate: '07 Jun',
      price: 88,
      marketPrice: 110,
      grade: 'Stone ground',
      tags: ['fresh'],
      packSize: '1 kg',
    ),
  ];

  static const reviews = <Review>[
    Review(
      initials: 'PM',
      author: 'Priya M.',
      area: 'Powai',
      rating: 5,
      text: 'Cooks soft, clean dal. Better than store brand.',
    ),
    Review(
      initials: 'RS',
      author: 'Rohit S.',
      area: 'Vashi',
      rating: 4,
      text: 'Fair price and fresh packing date.',
    ),
  ];

  static const familyPacks = <ComboPack>[
    ComboPack(
      id: 'bachelor',
      name: 'Bachelor Pack',
      type: ComboType.family,
      price: 999,
      size: '1 person',
      duration: '2–3 weeks',
      items: 'Rice 2kg, Atta 2kg, Dal 1kg, Oil 1L, Sugar 1kg, Tea 250g',
      savingsNote: 'Save ~₹120*',
    ),
    ComboPack(
      id: 'couple',
      name: 'Couple Pack',
      type: ComboType.family,
      price: 2499,
      size: '2 people',
      duration: '1 month',
      items: 'Rice 5kg, Atta 5kg, Dals 3kg, Oil 2L, Sugar 2kg, Spices set',
      savingsNote: 'Save ~₹320*',
    ),
    ComboPack(
      id: 'small-family',
      name: 'Small Family Pack',
      type: ComboType.family,
      price: 4999,
      size: '3–4 people',
      duration: '1 month',
      items: 'Rice 10kg, Atta 10kg, Dals 5kg, Oil 5L, Sugar 3kg, Spices, Tea',
      savingsNote: 'Save ~₹600*',
    ),
    ComboPack(
      id: 'medium-family',
      name: 'Medium Family Pack',
      type: ComboType.family,
      price: 7999,
      size: '5–6 people',
      duration: '1 month',
      items:
          'Rice 15kg, Atta 15kg, Dals 8kg, Oil 8L, Sugar 5kg, Spices, Tea, Jaggery',
      savingsNote: 'Save ~₹900*',
    ),
    ComboPack(
      id: 'large-family',
      name: 'Large Family Pack',
      type: ComboType.family,
      price: 11999,
      size: '7+ / joint',
      duration: '1 month',
      items: 'Rice 25kg, Atta 25kg, Dals 12kg, Oil 12L, Sugar 8kg, Full spice set',
      savingsNote: 'Save ~₹1,400*',
    ),
  ];

  static const healthPacks = <ComboPack>[
    ComboPack(
      id: 'fitness',
      name: 'Fitness Pack',
      type: ComboType.health,
      price: 2999,
      size: 'High energy',
      duration: '1 month',
      items: 'Oats, Brown rice, Millets, Moong, Peanut, Honey',
      savingsNote: 'Save ~₹350*',
    ),
    ComboPack(
      id: 'diabetic',
      name: 'Diabetic Friendly Pack',
      type: ComboType.health,
      price: 3299,
      size: 'Low GI',
      duration: '1 month',
      items: 'Ragi, Jowar, Bajra, Brown rice, Chana, Methi seeds',
      savingsNote: 'Save ~₹400*',
    ),
    ComboPack(
      id: 'weight-loss',
      name: 'Weight Loss Pack',
      type: ComboType.health,
      price: 2799,
      size: 'Low cal',
      duration: '1 month',
      items: 'Millets, Oats, Moong, Quinoa, Flax, Green tea',
      savingsNote: 'Save ~₹300*',
    ),
    ComboPack(
      id: 'high-protein',
      name: 'High Protein Vegetarian Pack',
      type: ComboType.health,
      price: 3499,
      size: 'Protein+',
      duration: '1 month',
      items: 'Soya, Rajma, Chana, Moong, Peanut, Sprouts mix',
      savingsNote: 'Save ~₹450*',
    ),
  ];

  static const festivalPacks = <ComboPack>[
    ComboPack(
      id: 'ganpati',
      name: 'Ganpati Pack',
      type: ComboType.festival,
      price: 1999,
      size: 'Pooja + prasad',
      duration: 'Festival',
      items: 'Rice, Rava, Jaggery, Ghee, Dry fruits, Coconut',
      savingsNote: 'Save ~₹250*',
    ),
    ComboPack(
      id: 'diwali',
      name: 'Diwali Pack',
      type: ComboType.festival,
      price: 2999,
      size: 'Sweets + faral',
      duration: 'Festival',
      items: 'Besan, Maida, Rava, Sugar, Ghee, Dry fruits, Oil',
      savingsNote: 'Save ~₹380*',
    ),
    ComboPack(
      id: 'gudi-padwa',
      name: 'Gudi Padwa Pack',
      type: ComboType.festival,
      price: 1799,
      size: 'New year',
      duration: 'Festival',
      items: 'Rice, Jaggery, Neem, Rava, Ghee, Dry fruits',
      savingsNote: 'Save ~₹220*',
    ),
    ComboPack(
      id: 'upvas',
      name: 'Upvas Pack',
      type: ComboType.festival,
      price: 1499,
      size: 'Vrat items',
      duration: 'Fasting',
      items: 'Sabudana, Rajgira, Singhara flour, Peanut, Rock salt',
      savingsNote: 'Save ~₹180*',
    ),
  ];

  static const subscriptions = <SubscriptionPlan>[
    SubscriptionPlan(
      id: 'monthly-essentials',
      name: 'Monthly Essentials Plan',
      description: 'Core grains, dal, oil & sugar each month',
      priceLabel: 'from ₹2,499/mo*',
    ),
    SubscriptionPlan(
      id: 'family-savings',
      name: 'Family Savings Plan',
      description: 'Bigger basket, best combined savings',
      priceLabel: 'from ₹4,999/mo*',
    ),
    SubscriptionPlan(
      id: 'premium-quality',
      name: 'Premium Quality Plan',
      description: 'Top-grade own-label premium range',
      priceLabel: 'from ₹5,999/mo*',
    ),
    SubscriptionPlan(
      id: 'custom-kirana',
      name: 'Custom Kirana Plan',
      description: 'Built from your Auto Kirana List',
      priceLabel: 'budget-based*',
    ),
  ];

  static const kiranaBasket = <BasketLine>[
    BasketLine(name: 'Rice', quantity: '10 kg', priceLabel: '₹540'),
    BasketLine(name: 'Wheat Flour', quantity: '15 kg', priceLabel: '₹765'),
    BasketLine(name: 'Toor Dal', quantity: '3 kg', priceLabel: '₹480'),
    BasketLine(name: 'Chana Dal', quantity: '2 kg', priceLabel: '₹260'),
    BasketLine(name: 'Sugar', quantity: '2 kg', priceLabel: '₹110'),
    BasketLine(name: 'Tea', quantity: '1 kg', priceLabel: '₹450'),
    BasketLine(name: 'Oil', quantity: '5 L', priceLabel: '₹1,150'),
  ];

  static const repeatBasket = <BasketLine>[
    BasketLine(name: 'Premium Basmati Rice', quantity: '5 kg', priceLabel: '₹540'),
    BasketLine(name: 'Farm Wheat Flour', quantity: '10 kg', priceLabel: '₹510'),
    BasketLine(name: 'Toor Dal', quantity: '3 kg', priceLabel: '₹480'),
    BasketLine(name: 'Moong Dal', quantity: '2 kg', priceLabel: '₹280'),
    BasketLine(name: 'Groundnut Oil', quantity: '5 L', priceLabel: '₹1,150'),
    BasketLine(name: 'Sugar', quantity: '2 kg', priceLabel: '₹110'),
    BasketLine(name: 'Tea', quantity: '500 g', priceLabel: '₹225'),
    BasketLine(name: 'Red Chilli Powder', quantity: '500 g', priceLabel: '₹120'),
    BasketLine(name: 'Jaggery Powder', quantity: '1 kg', priceLabel: '₹95'),
  ];

  /// Default cart contents shown in the wireframe cart screen.
  static const starterCart = <BasketLine>[
    BasketLine(name: 'Premium Basmati Rice', quantity: '5 kg', priceLabel: '₹540'),
    BasketLine(name: 'Farm Wheat Flour', quantity: '10 kg', priceLabel: '₹510'),
    BasketLine(name: 'Toor Dal', quantity: '3 kg', priceLabel: '₹480'),
    BasketLine(name: 'Groundnut Oil', quantity: '5 L', priceLabel: '₹1,150'),
    BasketLine(name: 'Jaggery Powder', quantity: '1 kg', priceLabel: '₹95'),
  ];
}
