import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "FarmFresh Admin",
  description: "Manage FarmFresh — products, categories, combos, and more.",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className="h-full antialiased">
      <body
        className="min-h-full flex flex-col"
        style={{
          fontFamily:
            "'Segoe UI', system-ui, -apple-system, Roboto, Helvetica, Arial, sans-serif",
        }}
      >
        {children}
      </body>
    </html>
  );
}
