import type { NextFunction, Request, Response } from 'express';
import jwt from 'jsonwebtoken';

const JWT_SECRET = process.env.JWT_SECRET ?? 'dev-secret';
const ADMIN_EMAIL = process.env.ADMIN_EMAIL ?? 'admin@farmfresh.local';
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD ?? 'farmfresh123';
const TOKEN_TTL = '12h';

export interface AdminClaims {
  sub: string;
  role: 'admin';
}

/** Validate credentials and issue a signed JWT. */
export function login(email: string, password: string): string | null {
  if (email !== ADMIN_EMAIL || password !== ADMIN_PASSWORD) return null;
  const claims: AdminClaims = { sub: email, role: 'admin' };
  return jwt.sign(claims, JWT_SECRET, { expiresIn: TOKEN_TTL });
}

/** Express middleware — rejects requests without a valid admin bearer token. */
export function requireAdmin(req: Request, res: Response, next: NextFunction) {
  const header = req.headers.authorization ?? '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : '';
  if (!token) return res.status(401).json({ error: 'Missing token' });
  try {
    const claims = jwt.verify(token, JWT_SECRET) as AdminClaims;
    if (claims.role !== 'admin') throw new Error('not admin');
    (req as Request & { admin?: AdminClaims }).admin = claims;
    next();
  } catch {
    return res.status(401).json({ error: 'Invalid or expired token' });
  }
}
