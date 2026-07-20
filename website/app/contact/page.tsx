import type { Metadata } from "next";
import { Header } from "@/components/Header";
import { Footer } from "@/components/Footer";
import { PageHeader } from "@/components/PageHeader";
import { ContactForm } from "@/components/ContactForm";

export const metadata: Metadata = {
  title: "Contact FarmFresh",
  description:
    "Get in touch with FarmFresh — support, partnerships, and society bulk orders across Mumbai & Navi Mumbai.",
};

const CHANNELS = [
  { icon: "💬", title: "WhatsApp", value: "+91 90000 00000", note: "Fastest for order help" },
  { icon: "✉️", title: "Email", value: "hello@farmfresh.example", note: "We reply within a day" },
  { icon: "🏢", title: "Partnerships", value: "partners@farmfresh.example", note: "Farms & societies" },
];

export default function ContactPage() {
  return (
    <>
      <Header />
      <main>
        <PageHeader
          eyebrow="Contact"
          title="We&rsquo;d love to hear from you"
          subtitle="Questions about an order, a partnership, or getting your society onboarded? Reach out — a real person will get back to you."
        />

        <section className="mx-auto max-w-7xl px-5 py-14 md:py-20">
          <div className="grid gap-10 lg:grid-cols-[1fr_1.1fr]">
            <div>
              <div className="space-y-4">
                {CHANNELS.map((c) => (
                  <div
                    key={c.title}
                    className="flex items-start gap-4 rounded-2xl bg-white p-5 ring-1 ring-line"
                  >
                    <span className="grid h-11 w-11 shrink-0 place-items-center rounded-full bg-sage-soft text-xl">
                      {c.icon}
                    </span>
                    <div>
                      <p className="text-sm font-semibold text-ink">{c.title}</p>
                      <p className="text-sm text-brand">{c.value}</p>
                      <p className="text-xs text-muted">{c.note}</p>
                    </div>
                  </div>
                ))}
              </div>
              <div className="mt-6 rounded-2xl bg-beige p-5 ring-1 ring-line">
                <p className="text-sm font-semibold text-ink">FarmFresh Retail Pvt. Ltd.</p>
                <p className="mt-1 text-sm text-ink/65">
                  Fresh Hub, Andheri East, Mumbai 400069
                  <br />
                  Serving Mumbai &amp; Navi Mumbai · 7am–10pm daily
                </p>
              </div>
            </div>

            <ContactForm />
          </div>
        </section>
      </main>
      <Footer />
    </>
  );
}
