import type { Metadata } from "next";
import { LegalDoc, type LegalSection } from "@/components/LegalDoc";

export const metadata: Metadata = {
  title: "Refund & Return Policy — FarmFresh",
  description:
    "How refunds, returns, and cancellations work at FarmFresh — quick, fair, and hassle-free.",
};

const SECTIONS: LegalSection[] = [
  {
    id: "promise",
    heading: "Our freshness promise",
    body: [
      "We stand behind every item we deliver. If something isn’t right — it arrived damaged, short-weight, spoiled, or simply not up to standard — we’ll make it right with a replacement or a refund. No lengthy forms, no hassle.",
    ],
  },
  {
    id: "eligible",
    heading: "What’s eligible",
    body: [
      "You can request a refund or replacement for:",
      {
        list: [
          "Items delivered damaged, spoiled, or expired.",
          "Wrong or missing items in your order.",
          "Short-weight fresh produce compared to what you were billed.",
          "Quality issues you notice on delivery or shortly after.",
        ],
      },
    ],
  },
  {
    id: "window",
    heading: "Time window",
    body: [
      "Please report any issue within 24 hours of delivery for perishable goods (fruits, vegetables, dairy, bakery) and within 7 days for non-perishable staples. Reporting promptly helps us investigate and resolve quickly.",
    ],
  },
  {
    id: "how",
    heading: "How to request a refund",
    body: [
      {
        list: [
          "Open the FarmFresh app and go to Orders → select the order → “Report an issue”.",
          "Choose the affected item(s) and, where possible, add a photo.",
          "Alternatively, contact us on WhatsApp or via the contact page with your order ID.",
        ],
      },
      "Our team typically responds within a few hours and resolves most requests the same day.",
    ],
  },
  {
    id: "method",
    heading: "Refund method & timeline",
    body: [
      {
        list: [
          "Prepaid orders: refunded to the original payment method, usually within 5–7 business days.",
          "Cash on Delivery orders: refunded to your FarmFresh wallet or bank account, as you prefer.",
          "Approved replacements are delivered in your next available slot at no extra charge.",
        ],
      },
    ],
  },
  {
    id: "cancellations",
    heading: "Cancellations",
    body: [
      "You can cancel an order free of charge before it is packed and dispatched. Once an order is out for delivery, it can no longer be cancelled, but you may refuse damaged or incorrect items at the door for a refund.",
      "For subscriptions, pause or cancel before the daily cut-off to avoid the next charge.",
    ],
  },
  {
    id: "exceptions",
    heading: "Exceptions",
    body: [
      "Refunds may not apply where an issue is reported outside the time window, where items were stored improperly after delivery, or in cases of evident misuse or fraud. We assess every request fairly and on its merits.",
    ],
  },
  {
    id: "help",
    heading: "Need help?",
    body: [
      "If you’re unhappy with a resolution, reach out and we’ll personally look into it. Your satisfaction is the whole point of FarmFresh.",
    ],
  },
];

export default function RefundsPage() {
  return (
    <LegalDoc
      eyebrow="Legal"
      title="Refund & Return Policy"
      updated="19 July 2026"
      intro="Not happy with something? We keep refunds and replacements quick and fair — here’s exactly how it works."
      sections={SECTIONS}
    />
  );
}
