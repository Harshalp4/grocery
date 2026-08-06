import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'FarmFresh24 Privacy Policy',
  description: 'How FarmFresh24 collects, uses, and protects your data.',
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

export default function PrivacyPage() {
  return (
    <main style={wrap}>
      <h1 style={h1}>Privacy Policy</h1>
      <p style={muted}>
        FarmFresh24 (&ldquo;the app&rdquo;) is operated by <strong>Bit2Sky India Pvt. Ltd.</strong>
        {' '}This policy explains what we collect, why, and your choices.
      </p>

      <h2 style={h2}>Information we collect</h2>
      <ul>
        <li style={li}><strong>Account details</strong> — name, email address, mobile number.</li>
        <li style={li}><strong>Delivery addresses</strong> and <strong>location</strong> — used to set your delivery address and show delivery on a map.</li>
        <li style={li}><strong>Order information</strong> — items ordered, amounts, delivery slot and status.</li>
        <li style={li}><strong>Device &amp; notification token</strong> — to send order updates via push notifications.</li>
      </ul>

      <h2 style={h2}>How we use your information</h2>
      <ul>
        <li style={li}>Create your account and sign you in (email one-time code, or Google Sign-In).</li>
        <li style={li}>Process, deliver and track your orders.</li>
        <li style={li}>Send order updates and important notifications.</li>
        <li style={li}>Provide customer support and improve the service.</li>
      </ul>

      <h2 style={h2}>Service providers we share with</h2>
      <p>We use trusted processors only to run the service, and we do <strong>not</strong> sell your data:</p>
      <ul>
        <li style={li}><strong>Google Firebase</strong> — authentication (Google Sign-In) and push notifications.</li>
        <li style={li}><strong>Resend</strong> — sending your email sign-in code.</li>
        <li style={li}><strong>Cloudinary</strong> — storing product and delivery-proof images.</li>
        <li style={li}><strong>Cloud hosting</strong> — running our servers and database.</li>
      </ul>

      <h2 style={h2}>Data security</h2>
      <p>All data is encrypted in transit using HTTPS/TLS.</p>

      <h2 style={h2}>Data retention</h2>
      <p>
        We keep your account data until you delete your account. Past order records may be
        retained in a form detached from your account for legal, tax and accounting
        purposes for up to 7 years.
      </p>

      <h2 style={h2}>Your rights</h2>
      <ul>
        <li style={li}><strong>Access &amp; correct</strong> — view and edit your name and mobile number in the app (Profile &rarr; Edit profile).</li>
        <li style={li}><strong>Delete</strong> — remove your account and associated data any time (Profile &rarr; Delete account, or see our{' '}
          <a href="/delete-account">account deletion page</a>).</li>
      </ul>

      <h2 style={h2}>Children</h2>
      <p>FarmFresh24 is intended for users aged 18 and over and is not directed at children.</p>

      <h2 style={h2}>Contact</h2>
      <p style={muted}>
        <a href="mailto:support@farmfresh24.app">support@farmfresh24.app</a>
        <br />
        Bit2Sky India Pvt. Ltd. · Navi Mumbai, Maharashtra, India
      </p>
      <p style={{ ...muted, marginTop: 24 }}>Last updated: August 2026</p>
    </main>
  );
}
