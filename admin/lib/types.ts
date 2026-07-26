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
  | 'picked_up'
  | 'out_for_delivery'
  | 'delivered'
  | 'failed'
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
  onDuty?: boolean;
  vehicleType?: string | null;
  vehicleNumber?: string | null;
  zone?: string | null;
  hasCredentials?: boolean;
  mustChangePassword?: boolean;
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

export type CouponType = 'percent' | 'flat';

export interface Coupon {
  id: string;
  code: string;
  type: CouponType;
  value: number;
  minOrder: number;
  maxDiscount: number;
  validFrom: string | null;
  validTo: string | null;
  usageLimit: number;
  perUserLimit: number;
  timesUsed: number;
  active: boolean;
  createdAt?: string;
}

export type TicketStatus = 'open' | 'resolved' | 'closed';

export interface SupportTicket {
  id: string;
  subject: string;
  message: string;
  status: TicketStatus;
  reply: string | null;
  orderId: string | null;
  createdAt: string;
  updatedAt: string;
  customerName: string | null;
  phone: string | null;
}

export interface Banner {
  id: string;
  title: string;
  subtitle: string;
  imageUrl: string | null;
  actionType: string | null;
  actionValue: string | null;
  active: boolean;
  sortOrder: number;
}

export interface LowStockItem {
  productId: string;
  product: string;
  variant: string | null;
  stock: number;
}

export type AdminRole = 'admin' | 'staff';

export interface AdminUser {
  id: string;
  email: string;
  role: AdminRole;
  active: boolean;
  createdAt?: string;
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
