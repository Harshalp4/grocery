/**
 * Payment service abstraction.
 *
 * - COD is real: nothing to charge now, collected on delivery.
 * - Online (UPI/card) is a TEST STUB today: it simulates a successful capture
 *   so the full order flow is testable without a live gateway. When you add
 *   Razorpay test/live keys (RAZORPAY_KEY_ID / RAZORPAY_KEY_SECRET), replace
 *   the stub branch with a real order+capture call — the return shape is the
 *   same, so nothing downstream changes.
 */

export type PaymentMethod = 'upi' | 'card' | 'cod';
export type PaymentStatus = 'pending' | 'paid' | 'failed';

export interface PaymentResult {
  status: PaymentStatus;
  ref: string | null;
}

const hasRazorpay =
  !!process.env.RAZORPAY_KEY_ID && !!process.env.RAZORPAY_KEY_SECRET;

export async function charge(
  method: PaymentMethod,
  amountRupees: number,
): Promise<PaymentResult> {
  if (method === 'cod') {
    return { status: 'pending', ref: null }; // collected on delivery
  }

  if (hasRazorpay) {
    // TODO: real Razorpay flow — create order, verify signature on webhook.
    // Kept as a clear seam; requires the razorpay SDK + keys.
    throw new Error('Razorpay integration not implemented yet');
  }

  // --- TEST STUB: simulate an instant successful online payment ---
  const ref = `SIMULATED-${method.toUpperCase()}-${Date.now()}`;
  return { status: 'paid', ref };
}

export const paymentsMode = hasRazorpay ? 'razorpay' : 'stub';
