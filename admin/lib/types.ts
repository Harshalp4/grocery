export interface ProductVariant {
  id: string;
  label: string;
  price: number;
  marketPrice: number;
  stock: number;
  inStock: boolean;
}

export interface Product {
  id: string;
  name: string;
  source: string;
  packedDate: string;
  price: number;
  marketPrice: number;
  grade: string;
  tags: string[];
  harvestMonth: string | null;
  packSize: string | null;
  nutrition: Record<string, string>;
  categorySlug?: string;
  imageUrl: string | null;
  stock: number;
  inStock: boolean;
  variants: ProductVariant[];
}

export interface Category {
  id?: string;
  slug: string;
  name: string;
  emoji: string;
  sortOrder?: number;
}

export type ComboType = 'family' | 'health' | 'festival';

export interface Combo {
  id: string;
  name: string;
  type: ComboType;
  price: number;
  size: string;
  duration: string;
  items: string;
  savingsNote: string;
}

export interface Subscription {
  id: string;
  name: string;
  description: string;
  priceLabel: string;
}

export interface Review {
  id: string;
  productId: string;
  productName: string;
  initials: string;
  author: string;
  area: string;
  rating: number;
  text: string;
}

export interface OrderItem {
  id: string;
  name: string;
  quantity: string;
  priceLabel: string;
  price: number;
}

export type OrderStatus =
  | 'placed'
  | 'confirmed'
  | 'packed'
  | 'out_for_delivery'
  | 'delivered'
  | 'cancelled';

export interface OrderEvent {
  id: string;
  status: string;
  note: string | null;
  createdAt: string;
}

export interface OrderPartner {
  id: string;
  name: string;
  phone: string;
}

export interface Order {
  id: string;
  code: string;
  customerName: string;
  phone: string;
  address: string;
  slot: string;
  itemTotal: number;
  savings: number;
  deliveryFee: number;
  total: number;
  paymentMethod: string;
  paymentStatus: string;
  paymentRef: string | null;
  status: OrderStatus;
  items: OrderItem[];
  createdAt: string;
  events?: OrderEvent[];
  deliveryPartner?: OrderPartner | null;
  returnRequest?: { status: string } | null;
}

export interface Customer {
  id: string;
  phone: string;
  name: string;
  createdAt: string;
  orderCount: number;
  addressCount: number;
  totalSpend: number;
}

export interface CustomerAddress {
  id: string;
  label: string;
  line: string;
  area: string;
  city: string;
  pincode: string;
  isDefault: boolean;
}

export interface CustomerOrder {
  id: string;
  code: string;
  total: number;
  status: string;
  createdAt: string;
  items: OrderItem[];
}

export interface CustomerDetail {
  id: string;
  phone: string;
  name: string;
  createdAt: string;
  addresses: CustomerAddress[];
  orders: CustomerOrder[];
}

export interface Slot {
  id: string;
  label: string;
  active: boolean;
  sortOrder: number;
}

export interface Area {
  id: string;
  pincode: string;
  area: string;
  city: string;
  etaLabel: string;
  active: boolean;
}

export interface Partner {
  id: string;
  name: string;
  phone: string;
  active: boolean;
}

export type ReturnStatus = 'requested' | 'approved' | 'rejected' | 'refunded';

export interface ReturnRequest {
  id: string;
  orderId: string;
  reason: string;
  status: ReturnStatus;
  createdAt: string;
  order: { code: string; customerName: string; total: number };
}

export interface Stats {
  counts: {
    products: number;
    categories: number;
    combos: number;
    subscriptions: number;
    reviews: number;
    orders: number;
  };
  revenue: number;
  byCategory: { categorySlug: string; count: number }[];
  byGrade: { grade: string; count: number }[];
  price: { avg: number; min: number; max: number };
}
