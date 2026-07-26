export function Logo({ light = false }: { light?: boolean }) {
  return (
    <span className="inline-flex items-center gap-2 font-serif text-xl font-semibold tracking-tight">
      <svg
        width="26"
        height="26"
        viewBox="0 0 32 32"
        fill="none"
        aria-hidden="true"
        className="shrink-0"
      >
        <circle cx="16" cy="16" r="16" fill={light ? "#ffffff" : "#b65b3c"} />
        <path
          d="M16 24c-4-1-7-4.5-7-9 3 0 6 1 7.5 3.2C18 16 21 15 24 15c0 4.5-3 8-8 9Z"
          fill={light ? "#b65b3c" : "#e9ede1"}
        />
        <path
          d="M16 24c0-3 .4-5.6 2-8"
          stroke={light ? "#6b7a55" : "#e0a458"}
          strokeWidth="1.4"
          strokeLinecap="round"
        />
      </svg>
      <span className={light ? "text-white" : "text-ink"}>
        Farm<span className="text-brand">Fresh</span>
      </span>
    </span>
  );
}
