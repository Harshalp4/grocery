import type { Metadata } from "next";
import { Fraunces, Inter } from "next/font/google";
import "./globals.css";

const inter = Inter({
  subsets: ["latin"],
  variable: "--font-inter",
  display: "swap",
});

const fraunces = Fraunces({
  subsets: ["latin"],
  variable: "--font-fraunces",
  display: "swap",
  weight: ["400", "500", "600", "700"],
});

const SITE_URL = "https://farmfresh.example.com";

export const metadata: Metadata = {
  metadataBase: new URL(SITE_URL),
  title: "FarmFresh — Farm-to-Home Groceries, Delivered Daily in Mumbai",
  description:
    "Farm-fresh staples, dairy, oils and spices you can trust — sourced direct, quality-graded and delivered same day across Mumbai & Navi Mumbai.",
  keywords: [
    "grocery delivery Mumbai",
    "farm fresh groceries",
    "online kirana Mumbai",
    "monthly grocery subscription",
    "Navi Mumbai grocery",
  ],
  openGraph: {
    title: "FarmFresh — Farm-to-Home Groceries, Delivered Daily",
    description:
      "Trusted, tested, farm-sourced groceries delivered across Mumbai & Navi Mumbai.",
    url: SITE_URL,
    siteName: "FarmFresh",
    type: "website",
    images: [{ url: "/images/hero.jpg", width: 1800, height: 1200 }],
  },
  twitter: {
    card: "summary_large_image",
    title: "FarmFresh — Farm-to-Home Groceries",
    description:
      "Trusted, tested, farm-sourced groceries delivered across Mumbai & Navi Mumbai.",
    images: ["/images/hero.jpg"],
  },
};

export default function RootLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en" className={`${inter.variable} ${fraunces.variable}`}>
      <body className="min-h-screen antialiased">{children}</body>
    </html>
  );
}
