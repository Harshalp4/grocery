import type { Metadata } from "next";
import { LegalDoc, type LegalSection } from "@/components/LegalDoc";

export const metadata: Metadata = {
  title: "Terms & Conditions — FarmFresh",
  description:
    "The terms that govern your use of the FarmFresh app, website, and services.",
};

const SECTIONS: LegalSection[] = [
  {
    id: "acceptance",
    heading: "Acceptance of terms",
    body: [
      "These Terms & Conditions govern your access to and use of the FarmFresh website, mobile app, and services operated by FarmFresh Retail Pvt. Ltd. By creating an account or placing an order, you agree to be bound by these terms.",
      "If you do not agree, please do not use our services.",
    ],
  },
  {
    id: "eligibility",
    heading: "Eligibility & accounts",
    body: [
      {
        list: [
          "You must be at least 18 years old and capable of entering into a binding contract.",
          "You are responsible for keeping your account credentials and OTP confidential.",
          "You agree to provide accurate, current information and to update it as needed.",
          "You are responsible for all activity that occurs under your account.",
        ],
      },
    ],
  },
  {
    id: "orders",
    heading: "Orders & pricing",
    body: [
      "All orders are subject to acceptance and availability. We may refuse or cancel an order at our discretion, including where an item is out of stock or a pricing error occurs.",
      {
        list: [
          "Prices are listed in Indian Rupees (₹) and are inclusive of applicable taxes unless stated otherwise.",
          "Product weights are approximate for fresh produce; final billing reflects actual weight where applicable.",
          "Promotional prices and coupons are subject to their specific terms and may be withdrawn at any time.",
        ],
      },
    ],
  },
  {
    id: "delivery",
    heading: "Delivery",
    body: [
      "We currently deliver across Mumbai and Navi Mumbai. Delivery slots and times are estimates and may be affected by weather, traffic, or other factors beyond our control.",
      "You agree to provide a valid address and to be available (or nominate someone) to receive the order during the selected slot.",
    ],
  },
  {
    id: "payments",
    heading: "Payments",
    body: [
      "We accept Cash on Delivery, with online payment methods (UPI, cards) offered where available. Online payments are processed by third-party providers, and you agree to their terms. FarmFresh does not store full payment credentials.",
    ],
  },
  {
    id: "subscriptions",
    heading: "Subscriptions",
    body: [
      "Subscription plans renew automatically according to the schedule you select. You may pause, skip, edit, or cancel a subscription at any time before the next processing cut-off through the app. Charges already processed are governed by our Refund Policy.",
    ],
  },
  {
    id: "conduct",
    heading: "Acceptable use",
    body: [
      "You agree not to misuse our services, including by:",
      {
        list: [
          "Attempting to defraud, abuse promotions, or place fraudulent orders.",
          "Interfering with or disrupting the platform, servers, or networks.",
          "Copying, scraping, or reverse-engineering any part of the service.",
          "Using the service for any unlawful purpose.",
        ],
      },
    ],
  },
  {
    id: "ip",
    heading: "Intellectual property",
    body: [
      "All content on the FarmFresh app and website — including the name, logo, text, graphics, and software — is owned by or licensed to FarmFresh and protected by law. You may not use it without our prior written permission.",
    ],
  },
  {
    id: "liability",
    heading: "Limitation of liability",
    body: [
      "To the maximum extent permitted by law, FarmFresh is not liable for any indirect, incidental, or consequential damages arising from your use of the service. Our total liability for any claim is limited to the amount you paid for the relevant order.",
    ],
  },
  {
    id: "law",
    heading: "Governing law & disputes",
    body: [
      "These terms are governed by the laws of India. Any disputes are subject to the exclusive jurisdiction of the courts of Mumbai, Maharashtra.",
    ],
  },
  {
    id: "changes",
    heading: "Changes to these terms",
    body: [
      "We may revise these terms from time to time. The updated version will be posted here with a new “last updated” date, and continued use of the service constitutes acceptance of the changes.",
    ],
  },
];

export default function TermsPage() {
  return (
    <LegalDoc
      eyebrow="Legal"
      title="Terms & Conditions"
      updated="19 July 2026"
      intro="These terms set out the rules for using FarmFresh — please read them carefully before placing an order."
      sections={SECTIONS}
    />
  );
}
