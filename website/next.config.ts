import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // Live product/category images come from the FarmFresh backend (Render/localhost).
  // Local marketing images live in /public and need no remote pattern.
  images: {
    remotePatterns: [
      { protocol: "https", hostname: "**" },
      { protocol: "http", hostname: "localhost" },
    ],
  },
};

export default nextConfig;
