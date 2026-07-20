import { api } from './api';
import type {
  Area,
  Category,
  Combo,
  Customer,
  CustomerDetail,
  Order,
  OrderStatus,
  Partner,
  Product,
  ProductVariant,
  Review,
  ReturnRequest,
  ReturnStatus,
  Slot,
  Stats,
  Subscription,
} from './types';

export interface VariantInput {
  label: string;
  price: number;
  marketPrice: number;
  stock: number;
  sortOrder?: number;
}

// Typed CRUD wrappers per resource, hitting the backend /admin/* endpoints.

export const stats = {
  get: () => api.get<Stats>('/admin/stats'),
};

export const products = {
  list: () => api.get<Product[]>('/admin/products'),
  create: (p: Product) => api.post<Product>('/admin/products', p),
  update: (id: string, p: Product) => api.put<Product>(`/admin/products/${id}`, p),
  remove: (id: string) => api.del(`/admin/products/${id}`),
  uploadImage: (id: string, dataUrl: string) =>
    api.post<{ imageUrl: string }>(`/admin/products/${id}/image`, { dataUrl }),
  setStock: (id: string, stock: number) =>
    api.put<Product>(`/admin/products/${id}/stock`, { stock }),
};

export const variants = {
  create: (productId: string, body: VariantInput) =>
    api.post<ProductVariant>(`/admin/products/${productId}/variants`, body),
  update: (vid: string, body: VariantInput) =>
    api.put<ProductVariant>(`/admin/variants/${vid}`, body),
  remove: (vid: string) => api.del(`/admin/variants/${vid}`),
};

export const categories = {
  list: () => api.get<Category[]>('/admin/categories'),
  create: (c: Category) => api.post<Category>('/admin/categories', c),
  update: (slug: string, c: Category) =>
    api.put<Category>(`/admin/categories/${slug}`, c),
  remove: (slug: string) => api.del(`/admin/categories/${slug}`),
};

export const combos = {
  list: () => api.get<Combo[]>('/admin/combos'),
  create: (c: Combo) => api.post<Combo>('/admin/combos', c),
  update: (id: string, c: Combo) => api.put<Combo>(`/admin/combos/${id}`, c),
  remove: (id: string) => api.del(`/admin/combos/${id}`),
};

export const subscriptions = {
  list: () => api.get<Subscription[]>('/admin/subscriptions'),
  create: (s: Subscription) => api.post<Subscription>('/admin/subscriptions', s),
  update: (id: string, s: Subscription) =>
    api.put<Subscription>(`/admin/subscriptions/${id}`, s),
  remove: (id: string) => api.del(`/admin/subscriptions/${id}`),
};

export const reviews = {
  list: () => api.get<Review[]>('/admin/reviews'),
  remove: (id: string) => api.del(`/admin/reviews/${id}`),
};

export const orders = {
  list: () => api.get<Order[]>('/admin/orders'),
  get: (id: string) => api.get<Order>(`/admin/orders/${id}`),
  setStatus: (id: string, status: OrderStatus) =>
    api.put<Order>(`/admin/orders/${id}/status`, { status }),
  assign: (id: string, partnerId: string | null) =>
    api.put<Order>(`/admin/orders/${id}/assign`, { partnerId }),
};

export const customers = {
  list: () => api.get<Customer[]>('/admin/customers'),
  get: (id: string) => api.get<CustomerDetail>(`/admin/customers/${id}`),
};

export const slots = {
  list: () => api.get<Slot[]>('/admin/slots'),
  create: (s: Slot) => api.post<Slot>('/admin/slots', s),
  update: (id: string, s: Slot) => api.put<Slot>(`/admin/slots/${id}`, s),
  remove: (id: string) => api.del(`/admin/slots/${id}`),
};

export const areas = {
  list: () => api.get<Area[]>('/admin/areas'),
  create: (a: Area) => api.post<Area>('/admin/areas', a),
  update: (id: string, a: Area) => api.put<Area>(`/admin/areas/${id}`, a),
  remove: (id: string) => api.del(`/admin/areas/${id}`),
};

export const partners = {
  list: () => api.get<Partner[]>('/admin/partners'),
  create: (p: Partner) => api.post<Partner>('/admin/partners', p),
  update: (id: string, p: Partner) => api.put<Partner>(`/admin/partners/${id}`, p),
  remove: (id: string) => api.del(`/admin/partners/${id}`),
};

export const returns = {
  list: () => api.get<ReturnRequest[]>('/admin/returns'),
  setStatus: (id: string, status: ReturnStatus) =>
    api.put<ReturnRequest>(`/admin/returns/${id}`, { status }),
};
