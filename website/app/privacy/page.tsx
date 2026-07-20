import type { Metadata } from "next";
import { LegalDoc, type LegalSection } from "@/components/LegalDoc";

export const metadata: Metadata = {
  title: "Privacy Policy — FarmFresh",
  description:
    "How FarmFresh collects, uses, and protects your personal information across our app and website.",
};

const SECTIONS: LegalSection[] = [
  {
    id: "intro",
    heading: "Introduction",
    body: [
      "FarmFresh Retail Pvt. Ltd. (“FarmFresh”, “we”, “us”) is committed to protecting your privacy. This policy explains what personal information we collect when you use our website and mobile app, how we use it, and the choices you have.",
      "By using FarmFresh, you agree to the collection and use of information in accordance with this policy.",
    ],
  },
  {
    id: "collect",
    heading: "Information we collect",
    body: [
      "We collect information you provide directly and information generated as you use our services:",
      {
        list: [
          "Account details: your name, phone number, email address, and delivery addresses.",
          "Order information: items purchased, order history, delivery slots, and preferences.",
          "Payment information: processed securely by our payment partners — we do not store full card or bank details on our servers.",
          "Device and usage data: device type, app version, IP address, and interactions with our app and website.",
          "Location data: your delivery area and, with your permission, precise location to improve delivery.",
        ],
      },
    ],
  },
  {
    id: "use",
    heading: "How we use your information",
    body: [
      {
        list: [
          "To process and deliver your orders and subscriptions.",
          "To provide customer support and respond to your enquiries.",
          "To send order updates, delivery notifications, and (with consent) offers.",
          "To improve our products, personalise recommendations, and prevent fraud.",
          "To comply with legal and regulatory obligations.",
        ],
      },
    ],
  },
  {
    id: "sharing",
    heading: "Sharing your information",
    body: [
      "We do not sell your personal information. We share it only with:",
      {
        list: [
          "Delivery and logistics partners, to fulfil your orders.",
          "Payment processors, to complete transactions securely.",
          "Service providers who help us operate (e.g. hosting, analytics, communications) under confidentiality obligations.",
          "Authorities, where required by law or to protect our rights and users.",
        ],
      },
    ],
  },
  {
    id: "security",
    heading: "Data security & retention",
    body: [
      "We use industry-standard technical and organisational measures to protect your data, including encryption in transit and access controls. No method of transmission is completely secure, but we work hard to safeguard your information.",
      "We retain personal data only as long as necessary to provide our services and meet legal obligations, after which it is deleted or anonymised.",
    ],
  },
  {
    id: "rights",
    heading: "Your rights & choices",
    body: [
      {
        list: [
          "Access, correct, or delete your personal information from your account or by contacting us.",
          "Opt out of promotional messages at any time via the unsubscribe link or app settings.",
          "Manage location and notification permissions from your device settings.",
          "Request a copy of the data we hold about you.",
        ],
      },
    ],
  },
  {
    id: "cookies",
    heading: "Cookies & analytics",
    body: [
      "Our website uses essential cookies to function and, with your consent, analytics cookies to understand usage and improve the experience. You can control non-essential cookies through your browser or our cookie banner.",
    ],
  },
  {
    id: "children",
    heading: "Children’s privacy",
    body: [
      "FarmFresh is intended for users aged 18 and over. We do not knowingly collect personal information from children. If you believe a child has provided us data, please contact us and we will remove it.",
    ],
  },
  {
    id: "changes",
    heading: "Changes to this policy",
    body: [
      "We may update this policy from time to time. Material changes will be notified via the app or website. Your continued use after changes take effect constitutes acceptance.",
    ],
  },
];

export default function PrivacyPage() {
  return (
    <LegalDoc
      eyebrow="Legal"
      title="Privacy Policy"
      updated="19 July 2026"
      intro="Your trust matters to us. This policy explains what data FarmFresh collects, how we use it, and the control you have over it."
      sections={SECTIONS}
    />
  );
}
