import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'Delete your FarmFresh24 account',
  description:
    'How to delete your FarmFresh24 account and what happens to your data.',
};

const wrap: React.CSSProperties = {
  maxWidth: 720,
  margin: '0 auto',
  padding: '48px 22px 80px',
  color: '#26312b',
  lineHeight: 1.65,
};
const h1: React.CSSProperties = { fontSize: 30, fontWeight: 800, color: '#2f6b46', margin: '0 0 6px' };
const h2: React.CSSProperties = { fontSize: 19, fontWeight: 700, margin: '30px 0 8px' };
const muted: React.CSSProperties = { color: '#6c7871', fontSize: 14 };
const li: React.CSSProperties = { margin: '6px 0' };

export default function DeleteAccountPage() {
  return (
    <main style={wrap}>
      <h1 style={h1}>Delete your FarmFresh24 account</h1>
      <p style={muted}>
        FarmFresh24 is operated by <strong>Bit2Sky India Pvt. Ltd.</strong> This page
        explains how to delete your account and what happens to your data.
      </p>

      <h2 style={h2}>Option 1 — Delete from within the app</h2>
      <ol>
        <li style={li}>Open the <strong>FarmFresh24</strong> app.</li>
        <li style={li}>Go to the <strong>Profile</strong> tab.</li>
        <li style={li}>Tap <strong>Delete account</strong>.</li>
        <li style={li}>Confirm. Your account is deleted immediately and you are signed out.</li>
      </ol>

      <h2 style={h2}>Option 2 — Request deletion by email</h2>
      <p>
        If you can&apos;t access the app, email{' '}
        <a href="mailto:support@farmfresh24.app">support@farmfresh24.app</a> from your
        registered email address with the subject <em>&ldquo;Delete my account&rdquo;</em>.
        We verify the request and complete deletion within <strong>7 days</strong>.
      </p>

      <h2 style={h2}>What is deleted</h2>
      <p>Deleting your account permanently and immediately removes:</p>
      <ul>
        <li style={li}>Your profile — name, email address and mobile number</li>
        <li style={li}>Your saved delivery addresses</li>
        <li style={li}>Your cart and wishlist</li>
      </ul>

      <h2 style={h2}>What is retained, and for how long</h2>
      <p>
        Records of your past orders (items, amounts and delivery details) are kept in a
        form <strong>detached from your personal account</strong> for legal, tax and
        accounting purposes for up to <strong>7 years</strong>, as required by applicable
        law, after which they are deleted.
      </p>

      <h2 style={h2}>Contact</h2>
      <p style={muted}>
        Questions about deletion or your data: {' '}
        <a href="mailto:support@farmfresh24.app">support@farmfresh24.app</a>
        <br />
        Bit2Sky India Pvt. Ltd. · Navi Mumbai, Maharashtra, India
      </p>
      <p style={{ ...muted, marginTop: 24 }}>Last updated: August 2026</p>
    </main>
  );
}
