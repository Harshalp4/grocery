import Image from "next/image";

/* A decorative QR block (not a live code — swap for a real deep-link QR at launch). */
function QrArt() {
  const cells = [
    "1111111 0 1011 1111111",
    "1000001 0 0110 1000001",
    "1011101 1 1001 1011101",
    "1011101 0 0111 1011101",
    "1011101 1 1010 1011101",
    "1000001 0 0101 1000001",
    "1111111 1 1011 1111111",
    "0000000 0 0000 0000000",
    "1101011 1 0110 1010110",
    "0110100 0 1101 0101101",
    "1010011 1 0010 1110010",
    "0101101 0 1101 0011011",
    "0000000 1 0110 1111111",
    "1111111 0 1010 1000001",
    "1000001 1 0101 1011101",
    "1011101 0 1011 1011101",
    "1011101 1 0100 1000001",
    "1000001 0 1010 1111111",
    "1111111 1 0101 0000000",
  ].map((r) => r.replace(/ /g, ""));
  return (
    <svg viewBox="0 0 19 19" className="h-24 w-24" shapeRendering="crispEdges" aria-label="Scan to download">
      <rect width="19" height="19" fill="#fff" />
      {cells.flatMap((row, y) =>
        row.split("").map((c, x) =>
          c === "1" ? <rect key={`${x}-${y}`} x={x} y={y} width="1" height="1" fill="#96482c" /> : null,
        ),
      )}
    </svg>
  );
}

function AppStoreBadge() {
  return (
    <span className="flex items-center gap-2.5 rounded-xl bg-ink px-4 py-2.5 text-white transition-transform hover:-translate-y-0.5">
      <svg width="22" height="22" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
        <path d="M16.4 12.7c0-2 1.6-3 1.7-3-.9-1.4-2.4-1.6-2.9-1.6-1.2-.1-2.4.7-3 .7s-1.6-.7-2.6-.7c-1.3 0-2.6.8-3.3 2-1.4 2.4-.4 6 1 8 .7 1 1.4 2 2.5 2 1 0 1.4-.6 2.6-.6s1.5.6 2.6.6 1.7-.9 2.4-1.9c.7-1 1-2 1-2s-1.9-.7-2-2.9zM14.5 6.3c.5-.7.9-1.6.8-2.6-.8 0-1.8.6-2.4 1.2-.5.6-1 1.5-.8 2.4.9.1 1.8-.4 2.4-1z" />
      </svg>
      <span className="text-left leading-tight">
        <span className="block text-[10px] opacity-80">Download on the</span>
        <span className="block text-sm font-semibold">App Store</span>
      </span>
    </span>
  );
}

function GooglePlayBadge() {
  return (
    <span className="flex items-center gap-2.5 rounded-xl bg-ink px-4 py-2.5 text-white transition-transform hover:-translate-y-0.5">
      <svg width="20" height="22" viewBox="0 0 24 24" aria-hidden="true">
        <path d="M3.6 2.3c-.2.2-.3.5-.3.9v17.6c0 .4.1.7.3.9l.1.1L13.5 12v-.2L3.7 2.2l-.1.1z" fill="#00d4ff" />
        <path d="M17 15.3l-3.5-3.5v-.2L17 8.1l.1.1 4.1 2.4c1.2.7 1.2 1.8 0 2.5L17 15.3z" fill="#ffce00" />
        <path d="M17.1 15.2 13.5 11.7 3.6 21.6c.4.4 1 .5 1.7.1l11.8-6.5" fill="#ff3d47" />
        <path d="M17.1 8.2 5.3 1.7C4.6 1.3 4 1.4 3.6 1.8l9.9 9.9 3.6-3.5z" fill="#00f076" />
      </svg>
      <span className="text-left leading-tight">
        <span className="block text-[10px] opacity-80">GET IT ON</span>
        <span className="block text-sm font-semibold">Google Play</span>
      </span>
    </span>
  );
}

export function DownloadCTA() {
  return (
    <section id="download" className="mx-auto max-w-7xl px-5 pb-20">
      <div className="relative overflow-hidden rounded-[32px] bg-brand px-6 py-12 text-white sm:px-12 md:py-16">
        <div className="grid items-center gap-10 md:grid-cols-[1.3fr_1fr]">
          <div>
            <h2 className="font-serif text-3xl font-semibold sm:text-4xl">
              Get the FarmFresh app
            </h2>
            <p className="mt-3 max-w-md text-white/80">
              Shop farm-fresh groceries, plan your monthly kirana with AI, and track
              every delivery — all from your phone.
            </p>

            <div className="mt-7 flex flex-wrap items-center gap-4">
              <a href="#" aria-label="Download on the App Store"><AppStoreBadge /></a>
              <a href="#" aria-label="Get it on Google Play"><GooglePlayBadge /></a>
              <div className="flex items-center gap-3 rounded-xl bg-white p-2.5 pr-4">
                <QrArt />
                <span className="text-xs font-medium text-ink">
                  Scan to
                  <br />
                  download
                </span>
              </div>
            </div>
          </div>

          <div className="relative mx-auto hidden w-56 md:block">
            <div className="relative aspect-[9/19] w-full overflow-hidden rounded-[2.2rem] border-[6px] border-ink/80 bg-ink shadow-2xl">
              <Image
                src="/images/produce-basket.jpg"
                alt="FarmFresh app preview"
                fill
                sizes="224px"
                className="object-cover"
              />
              <div className="absolute inset-x-0 top-0 flex justify-center pt-2">
                <span className="h-4 w-20 rounded-full bg-ink/90" />
              </div>
              <div className="absolute inset-x-3 bottom-3 rounded-2xl bg-white/95 p-3 backdrop-blur">
                <p className="text-[11px] font-semibold text-ink">Monthly kirana ready</p>
                <p className="text-[10px] text-muted">18 items · ₹2,499 · save ₹420</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
