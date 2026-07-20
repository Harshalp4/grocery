import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

const categories = [
  { slug: 'rice', name: 'Rice', emoji: '🍚' },
  { slug: 'dal-pulses', name: 'Dal & Pulses', emoji: '🫘' },
  { slug: 'wheat-flour', name: 'Wheat & Flour', emoji: '🌾' },
  { slug: 'oils-ghee', name: 'Oils & Ghee', emoji: '🛢️' },
  { slug: 'spices', name: 'Spices', emoji: '🌶️' },
  { slug: 'millets', name: 'Millets', emoji: '🌱' },
  { slug: 'tea-coffee', name: 'Tea & Coffee', emoji: '☕' },
  { slug: 'sugar-jaggery', name: 'Sugar & Jaggery', emoji: '🍯' },
];

const products = [
  { id: 'toor-dal', name: 'Premium Toor Dal', source: 'Vidarbha, MH', packedDate: '10 Jun', price: 160, marketPrice: 198, grade: 'Premium A', tags: 'best,premium', categorySlug: 'dal-pulses', harvestMonth: 'March 2026', packSize: '1 kg', nutrition: JSON.stringify({ Protein: '22 g', Carbohydrates: '63 g', Fibre: '15 g', Energy: '343 kcal' }) },
  { id: 'wheat-flour', name: 'Farm Wheat Flour', source: 'Own farm, Nashik', packedDate: '12 Jun', price: 255, marketPrice: 320, grade: 'Chakki Fresh', tags: 'best,fresh', categorySlug: 'wheat-flour', packSize: '10 kg', nutrition: '{}' },
  { id: 'basmati-rice', name: 'Premium Basmati Rice', source: 'Haryana mills', packedDate: '08 Jun', price: 540, marketPrice: 640, grade: 'Aged 1yr', tags: 'best,premium', categorySlug: 'rice', packSize: '5 kg', nutrition: '{}' },
  { id: 'groundnut-oil', name: 'Groundnut Oil', source: 'Saurashtra', packedDate: '05 Jun', price: 1150, marketPrice: 1320, grade: 'Cold pressed', tags: 'premium', categorySlug: 'oils-ghee', packSize: '5 L', nutrition: '{}' },
  { id: 'jaggery-powder', name: 'Jaggery Powder', source: 'Kolhapur', packedDate: '11 Jun', price: 95, marketPrice: 120, grade: 'Chemical-free', tags: 'fresh', categorySlug: 'sugar-jaggery', packSize: '1 kg', nutrition: '{}' },
  { id: 'chilli-powder', name: 'Red Chilli Powder', source: 'Guntur', packedDate: '09 Jun', price: 240, marketPrice: 295, grade: 'Premium', tags: 'premium', categorySlug: 'spices', packSize: '500 g', nutrition: '{}' },
  { id: 'moong-dal', name: 'Moong Dal', source: 'Rajasthan', packedDate: '10 Jun', price: 140, marketPrice: 175, grade: 'Premium A', tags: 'best', categorySlug: 'dal-pulses', packSize: '1 kg', nutrition: '{}' },
  { id: 'ragi-flour', name: 'Ragi Flour', source: 'Karnataka', packedDate: '07 Jun', price: 88, marketPrice: 110, grade: 'Stone ground', tags: 'fresh', categorySlug: 'millets', packSize: '1 kg', nutrition: '{}' },
];

const reviews = [
  { productId: 'toor-dal', initials: 'PM', author: 'Priya M.', area: 'Powai', rating: 5, text: 'Cooks soft, clean dal. Better than store brand.' },
  { productId: 'toor-dal', initials: 'RS', author: 'Rohit S.', area: 'Vashi', rating: 4, text: 'Fair price and fresh packing date.' },
];

const combos = [
  { id: 'bachelor', name: 'Bachelor Pack', type: 'family', price: 999, size: '1 person', duration: '2–3 weeks', items: 'Rice 2kg, Atta 2kg, Dal 1kg, Oil 1L, Sugar 1kg, Tea 250g', savingsNote: 'Save ~₹120*' },
  { id: 'couple', name: 'Couple Pack', type: 'family', price: 2499, size: '2 people', duration: '1 month', items: 'Rice 5kg, Atta 5kg, Dals 3kg, Oil 2L, Sugar 2kg, Spices set', savingsNote: 'Save ~₹320*' },
  { id: 'small-family', name: 'Small Family Pack', type: 'family', price: 4999, size: '3–4 people', duration: '1 month', items: 'Rice 10kg, Atta 10kg, Dals 5kg, Oil 5L, Sugar 3kg, Spices, Tea', savingsNote: 'Save ~₹600*' },
  { id: 'medium-family', name: 'Medium Family Pack', type: 'family', price: 7999, size: '5–6 people', duration: '1 month', items: 'Rice 15kg, Atta 15kg, Dals 8kg, Oil 8L, Sugar 5kg, Spices, Tea, Jaggery', savingsNote: 'Save ~₹900*' },
  { id: 'large-family', name: 'Large Family Pack', type: 'family', price: 11999, size: '7+ / joint', duration: '1 month', items: 'Rice 25kg, Atta 25kg, Dals 12kg, Oil 12L, Sugar 8kg, Full spice set', savingsNote: 'Save ~₹1,400*' },
  { id: 'fitness', name: 'Fitness Pack', type: 'health', price: 2999, size: 'High energy', duration: '1 month', items: 'Oats, Brown rice, Millets, Moong, Peanut, Honey', savingsNote: 'Save ~₹350*' },
  { id: 'diabetic', name: 'Diabetic Friendly Pack', type: 'health', price: 3299, size: 'Low GI', duration: '1 month', items: 'Ragi, Jowar, Bajra, Brown rice, Chana, Methi seeds', savingsNote: 'Save ~₹400*' },
  { id: 'weight-loss', name: 'Weight Loss Pack', type: 'health', price: 2799, size: 'Low cal', duration: '1 month', items: 'Millets, Oats, Moong, Quinoa, Flax, Green tea', savingsNote: 'Save ~₹300*' },
  { id: 'high-protein', name: 'High Protein Vegetarian Pack', type: 'health', price: 3499, size: 'Protein+', duration: '1 month', items: 'Soya, Rajma, Chana, Moong, Peanut, Sprouts mix', savingsNote: 'Save ~₹450*' },
  { id: 'ganpati', name: 'Ganpati Pack', type: 'festival', price: 1999, size: 'Pooja + prasad', duration: 'Festival', items: 'Rice, Rava, Jaggery, Ghee, Dry fruits, Coconut', savingsNote: 'Save ~₹250*' },
  { id: 'diwali', name: 'Diwali Pack', type: 'festival', price: 2999, size: 'Sweets + faral', duration: 'Festival', items: 'Besan, Maida, Rava, Sugar, Ghee, Dry fruits, Oil', savingsNote: 'Save ~₹380*' },
  { id: 'gudi-padwa', name: 'Gudi Padwa Pack', type: 'festival', price: 1799, size: 'New year', duration: 'Festival', items: 'Rice, Jaggery, Neem, Rava, Ghee, Dry fruits', savingsNote: 'Save ~₹220*' },
  { id: 'upvas', name: 'Upvas Pack', type: 'festival', price: 1499, size: 'Vrat items', duration: 'Fasting', items: 'Sabudana, Rajgira, Singhara flour, Peanut, Rock salt', savingsNote: 'Save ~₹180*' },
];

const subscriptions = [
  { id: 'monthly-essentials', name: 'Monthly Essentials Plan', description: 'Core grains, dal, oil & sugar each month', priceLabel: 'from ₹2,499/mo*' },
  { id: 'family-savings', name: 'Family Savings Plan', description: 'Bigger basket, best combined savings', priceLabel: 'from ₹4,999/mo*' },
  { id: 'premium-quality', name: 'Premium Quality Plan', description: 'Top-grade own-label premium range', priceLabel: 'from ₹5,999/mo*' },
  { id: 'custom-kirana', name: 'Custom Kirana Plan', description: 'Built from your Auto Kirana List', priceLabel: 'budget-based*' },
];

const kiranaLines = [
  { name: 'Rice', quantity: '10 kg', priceLabel: '₹540' },
  { name: 'Wheat Flour', quantity: '15 kg', priceLabel: '₹765' },
  { name: 'Toor Dal', quantity: '3 kg', priceLabel: '₹480' },
  { name: 'Chana Dal', quantity: '2 kg', priceLabel: '₹260' },
  { name: 'Sugar', quantity: '2 kg', priceLabel: '₹110' },
  { name: 'Tea', quantity: '1 kg', priceLabel: '₹450' },
  { name: 'Oil', quantity: '5 L', priceLabel: '₹1,150' },
];

const repeatLines = [
  { name: 'Premium Basmati Rice', quantity: '5 kg', priceLabel: '₹540' },
  { name: 'Farm Wheat Flour', quantity: '10 kg', priceLabel: '₹510' },
  { name: 'Toor Dal', quantity: '3 kg', priceLabel: '₹480' },
  { name: 'Moong Dal', quantity: '2 kg', priceLabel: '₹280' },
  { name: 'Groundnut Oil', quantity: '5 L', priceLabel: '₹1,150' },
  { name: 'Sugar', quantity: '2 kg', priceLabel: '₹110' },
  { name: 'Tea', quantity: '500 g', priceLabel: '₹225' },
  { name: 'Red Chilli Powder', quantity: '500 g', priceLabel: '₹120' },
  { name: 'Jaggery Powder', quantity: '1 kg', priceLabel: '₹95' },
];

const deliverySlots = [
  'Tomorrow · 8–11 AM',
  'Tomorrow · 12–3 PM',
  'Tomorrow · 5–8 PM',
  'Day after · 8–11 AM',
  'Day after · 5–8 PM',
];

// Per-product stock (chilli = out of stock, jaggery = low, to demo states).
const stockMap: Record<string, number> = {
  'toor-dal': 40, 'wheat-flour': 30, 'basmati-rice': 25, 'groundnut-oil': 18,
  'jaggery-powder': 3, 'chilli-powder': 0, 'moong-dal': 35, 'ragi-flour': 22,
};

// Pack-size variants: [label, price, marketPrice, stock].
const variantsSeed: Record<string, [string, number, number, number][]> = {
  'toor-dal': [['500 g', 85, 105, 30], ['1 kg', 160, 198, 40], ['2 kg', 300, 380, 15]],
  'moong-dal': [['500 g', 75, 95, 20], ['1 kg', 140, 175, 35]],
  'basmati-rice': [['1 kg', 120, 145, 20], ['5 kg', 540, 640, 25], ['10 kg', 1040, 1260, 8]],
  'wheat-flour': [['5 kg', 135, 170, 30], ['10 kg', 255, 320, 30]],
};

const serviceableAreas = [
  { pincode: '400703', area: 'Vashi', city: 'Navi Mumbai', etaLabel: 'Tomorrow by 11 AM' },
  { pincode: '410210', area: 'Kharghar', city: 'Navi Mumbai', etaLabel: 'Tomorrow by 1 PM' },
  { pincode: '400076', area: 'Powai', city: 'Mumbai', etaLabel: 'Next day' },
];

const deliveryPartners = [
  { name: 'Ravi K.', phone: '9820011111' },
  { name: 'Suresh M.', phone: '9820022222' },
];

async function main() {
  // Clear (order matters for FK). Orders are NOT cleared (keep real orders);
  // just detach partner refs so partners can be re-seeded.
  await prisma.order.updateMany({ data: { deliveryPartnerId: null } });
  await prisma.review.deleteMany();
  await prisma.productVariant.deleteMany();
  await prisma.product.deleteMany();
  await prisma.category.deleteMany();
  await prisma.comboPack.deleteMany();
  await prisma.subscriptionPlan.deleteMany();
  await prisma.basketLine.deleteMany();
  await prisma.serviceableArea.deleteMany();
  await prisma.deliveryPartner.deleteMany();

  await prisma.category.createMany({
    data: categories.map((c, i) => ({ ...c, sortOrder: i })),
  });
  for (const p of products) {
    await prisma.product.create({
      data: { ...p, imageUrl: `/uploads/${p.id}.png`, stock: stockMap[p.id] ?? 20 },
    });
  }
  for (const [pid, vs] of Object.entries(variantsSeed)) {
    await prisma.productVariant.createMany({
      data: vs.map(([label, price, marketPrice, stock], i) => ({
        productId: pid, label, price, marketPrice, stock, sortOrder: i,
      })),
    });
  }
  await prisma.serviceableArea.createMany({ data: serviceableAreas });
  await prisma.deliveryPartner.createMany({ data: deliveryPartners });
  await prisma.review.createMany({ data: reviews });
  await prisma.comboPack.createMany({ data: combos });
  await prisma.subscriptionPlan.createMany({ data: subscriptions });
  await prisma.basketLine.createMany({
    data: [
      ...kiranaLines.map((l, i) => ({ ...l, list: 'kirana', sortOrder: i })),
      ...repeatLines.map((l, i) => ({ ...l, list: 'repeat', sortOrder: i })),
    ],
  });
  await prisma.deliverySlot.deleteMany();
  await prisma.deliverySlot.createMany({
    data: deliverySlots.map((label, i) => ({ label, sortOrder: i })),
  });

  console.log('Seed complete:',
    `${categories.length} categories, ${products.length} products, ` +
    `${combos.length} combos, ${subscriptions.length} plans.`);
}

main()
  .catch((e) => { console.error(e); process.exit(1); })
  .finally(() => prisma.$disconnect());
