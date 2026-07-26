// Typed client for the FarmFresh admin API. Stores the JWT in localStorage and
// attaches it to every request. Base URL from NEXT_PUBLIC_API_BASE.

export const API_BASE =
  process.env.NEXT_PUBLIC_API_BASE ?? 'http://localhost:4000';

const TOKEN_KEY = 'ff_admin_token';

export const auth = {
  get token(): string | null {
    if (typeof window === 'undefined') return null;
    return window.localStorage.getItem(TOKEN_KEY);
  },
  set(token: string) {
    window.localStorage.setItem(TOKEN_KEY, token);
  },
  clear() {
    window.localStorage.removeItem(TOKEN_KEY);
  },
  get isAuthed() {
    return !!this.token;
  },
};

export class ApiError extends Error {
  constructor(public status: number, message: string) {
    super(message);
  }
}

async function request<T>(
  path: string,
  options: RequestInit = {},
): Promise<T> {
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    ...(options.headers as Record<string, string> | undefined),
  };
  const token = auth.token;
  if (token) headers.Authorization = `Bearer ${token}`;

  const res = await fetch(`${API_BASE}${path}`, { ...options, headers });

  if (res.status === 401) {
    auth.clear();
    if (typeof window !== 'undefined' && !path.includes('/login')) {
      window.location.href = '/login';
    }
    throw new ApiError(401, 'Unauthorized');
  }
  if (!res.ok) {
    let msg = `Request failed (${res.status})`;
    try {
      const body = await res.json();
      if (body?.error) msg = typeof body.error === 'string' ? body.error : msg;
    } catch {
      /* ignore */
    }
    throw new ApiError(res.status, msg);
  }
  if (res.status === 204) return undefined as T;
  return res.json() as Promise<T>;
}

export const api = {
  get: <T>(path: string) => request<T>(path),
  post: <T>(path: string, body: unknown) =>
    request<T>(path, { method: 'POST', body: JSON.stringify(body) }),
  put: <T>(path: string, body: unknown) =>
    request<T>(path, { method: 'PUT', body: JSON.stringify(body) }),
  del: <T>(path: string) => request<T>(path, { method: 'DELETE' }),
};

export async function login(email: string, password: string) {
  const { token } = await api.post<{ token: string }>('/admin/login', {
    email,
    password,
  });
  auth.set(token);
  return token;
}
