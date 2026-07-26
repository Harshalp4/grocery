import { Header } from "@/components/Header";
import { Hero } from "@/components/Hero";
import { ValueBanner } from "@/components/ValueBanner";
import { Categories } from "@/components/Categories";
import { Journey } from "@/components/Journey";
import { Quality } from "@/components/Quality";
import { BestSellers } from "@/components/BestSellers";
import { ServiceModels } from "@/components/ServiceModels";
import { AIPlanner } from "@/components/AIPlanner";
import { Combos } from "@/components/Combos";
import { Testimonials } from "@/components/Testimonials";
import { Referrals } from "@/components/Referrals";
import { DownloadCTA } from "@/components/DownloadCTA";
import { Footer } from "@/components/Footer";
import {
  getBestSellers,
  getCategories,
  getCombos,
} from "@/lib/api";

export default async function Home() {
  // Live catalog data (with static fallback when the backend is unreachable).
  const [categories, bestSellers, combos] = await Promise.all([
    getCategories(),
    getBestSellers(),
    getCombos(),
  ]);

  return (
    <>
      <Header />
      <main>
        <Hero />
        <ValueBanner />
        <Categories categories={categories} />
        <Journey />
        <Quality />
        <BestSellers products={bestSellers} />
        <ServiceModels />
        <AIPlanner />
        <Combos combos={combos} />
        <Testimonials />
        <Referrals />
        <DownloadCTA />
      </main>
      <Footer />
    </>
  );
}
