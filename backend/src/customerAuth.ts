import type { NextFunction, Request, Response } from 'express';
import jwt from 'jsonwebtoken';

const JWT_SECRET = process.env.JWT_SECRET ?? 'dev-secret';
const TOKEN_TTL = '30d';

/**
 * Dev mode returns the generated OTP in the API response so login is testable
 * without an SMS provider. Set OTP_DEV_MODE=false (and wire real SMS in
 * `sendSms`) for production.
 */
export const OTP_DEV_MODE = process.env.OTP_DEV_MODE !== 'false';

export interface CustomerClaims {
  sub: string; // userId
  phone: string;
  role: 'customer';
}

export function signCustomerToken(userId: string, phone: string): string {
  const claims: CustomerClaims = { sub: userId, phone, role: 'customer' };
  return jwt.sign(claims, JWT_SECRET, { expiresIn: TOKEN_TTL });
}

/** Generate a 4-digit OTP. */
export function generateOtp(): string {
  // 1000–9999
  return String(1000 + Math.floor(Math.random() * 9000));
}

/**
 * Deliver the OTP. In dev this just logs it; wire MSG91/Twilio here for prod.
 */
export async function sendSms(phone: string, code: string): Promise<void> {
  // eslint-disable-next-line no-console
  console.log(`[OTP] ${phone} -> ${code}`);
  // TODO(prod): await smsProvider.send(phone, `Your FarmFresh OTP is ${code}`);
}

/** Middleware — requires a valid customer bearer token. */
export function requireCustomer(req: Request, res: Response, next: NextFunction) {
  const header = req.headers.authorization ?? '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : '';
  if (!token) return res.status(401).json({ error: 'Missing token' });
  try {
    const claims = jwt.verify(token, JWT_SECRET) as CustomerClaims;
    if (claims.role !== 'customer') throw new Error('not customer');
    (req as Request & { customer?: CustomerClaims }).customer = claims;
    next();
  } catch {
    return res.status(401).json({ error: 'Invalid or expired token' });
  }
}
