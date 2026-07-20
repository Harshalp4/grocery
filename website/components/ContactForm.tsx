"use client";

import { useState } from "react";

export function ContactForm() {
  const [sent, setSent] = useState(false);

  if (sent) {
    return (
      <div className="flex flex-col items-center justify-center rounded-[26px] bg-white p-10 text-center ring-1 ring-line">
        <div className="grid h-14 w-14 place-items-center rounded-full bg-sage-soft text-2xl">
          ✅
        </div>
        <h2 className="mt-4 font-serif text-2xl font-semibold text-ink">
          Thanks for reaching out!
        </h2>
        <p className="mt-2 max-w-sm text-sm text-ink/65">
          We&rsquo;ve got your message and will get back to you within one working day.
        </p>
        <button
          type="button"
          onClick={() => setSent(false)}
          className="mt-6 rounded-full border border-line px-5 py-2.5 text-sm font-semibold text-ink hover:border-brand hover:text-brand"
        >
          Send another
        </button>
      </div>
    );
  }

  return (
    <form
      onSubmit={(e) => {
        e.preventDefault();
        // Demo only — no data leaves the browser. Wire to your backend/email service to go live.
        setSent(true);
      }}
      className="rounded-[26px] bg-white p-6 ring-1 ring-line sm:p-8"
    >
      <div className="grid gap-4 sm:grid-cols-2">
        <Field label="Name" name="name" placeholder="Priya Deshpande" required />
        <Field label="Phone" name="phone" type="tel" placeholder="+91 …" required />
      </div>
      <div className="mt-4">
        <Field label="Email" name="email" type="email" placeholder="you@example.com" required />
      </div>
      <div className="mt-4">
        <label className="mb-1.5 block text-sm font-medium text-ink" htmlFor="topic">
          Topic
        </label>
        <select
          id="topic"
          name="topic"
          className="w-full rounded-xl border border-line bg-beige/40 px-4 py-3 text-sm text-ink outline-none focus:border-brand focus:ring-2 focus:ring-brand/20"
        >
          <option>Order help</option>
          <option>Subscriptions</option>
          <option>Society bulk order</option>
          <option>Partner with us</option>
          <option>Something else</option>
        </select>
      </div>
      <div className="mt-4">
        <label className="mb-1.5 block text-sm font-medium text-ink" htmlFor="message">
          Message
        </label>
        <textarea
          id="message"
          name="message"
          rows={4}
          required
          placeholder="How can we help?"
          className="w-full resize-none rounded-xl border border-line bg-beige/40 px-4 py-3 text-sm text-ink outline-none focus:border-brand focus:ring-2 focus:ring-brand/20"
        />
      </div>
      <button
        type="submit"
        className="mt-6 w-full rounded-full bg-brand px-6 py-3.5 text-sm font-semibold text-white transition-colors hover:bg-brand-dark"
      >
        Send message
      </button>
      <p className="mt-3 text-center text-xs text-muted">
        We&rsquo;ll only use your details to respond to this enquiry.
      </p>
    </form>
  );
}

function Field({
  label,
  name,
  type = "text",
  placeholder,
  required,
}: {
  label: string;
  name: string;
  type?: string;
  placeholder?: string;
  required?: boolean;
}) {
  return (
    <div>
      <label className="mb-1.5 block text-sm font-medium text-ink" htmlFor={name}>
        {label}
      </label>
      <input
        id={name}
        name={name}
        type={type}
        required={required}
        placeholder={placeholder}
        className="w-full rounded-xl border border-line bg-beige/40 px-4 py-3 text-sm text-ink outline-none focus:border-brand focus:ring-2 focus:ring-brand/20"
      />
    </div>
  );
}
