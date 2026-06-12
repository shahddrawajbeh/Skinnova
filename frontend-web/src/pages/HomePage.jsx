import { useEffect, useState } from "react";
import {
  Sparkles,
  Camera,
  ArrowRight,
  Sun,
  Moon,
  ShoppingBag,
  Users,
  ScanFace,
  CheckCircle2,
} from "lucide-react";
import Button from "../components/common/Button";
import Card from "../components/common/Card";
import SectionHeader from "../components/common/SectionHeader";
import HorizontalSlider from "../components/common/HorizontalSlider";
import { SkeletonRow } from "../components/common/Skeleton";
import { AppDownloadBanner } from "../components/common/AppDownloadCTA";
import ProductCard from "../components/product/ProductCard";
import PostCard from "../components/community/PostCard";
import { useAuth } from "../context/AuthContext";
import { productService } from "../services/productService";
import { communityService } from "../services/communityService";
import { routineService } from "../services/routineService";

export default function HomePage() {
  const { isAuthenticated, user } = useAuth();
  const [products, setProducts] = useState([]);
  const [loadingProducts, setLoadingProducts] = useState(true);
  const [posts, setPosts] = useState([]);
  const [loadingPosts, setLoadingPosts] = useState(true);
  const [routine, setRoutine] = useState(null);
  const [loadingRoutine, setLoadingRoutine] = useState(isAuthenticated);

  useEffect(() => {
    let mounted = true;
    productService
      .fetchProducts()
      .then((data) => mounted && setProducts(data.slice(0, 10)))
      .catch(() => mounted && setProducts([]))
      .finally(() => mounted && setLoadingProducts(false));

    communityService
      .fetchFeed({ filter: "latest", limit: 6 })
      .then((data) => mounted && setPosts(data.slice(0, 6)))
      .catch(() =>
        communityService
          .fetchPosts()
          .then((data) => mounted && setPosts(data.slice(0, 6)))
          .catch(() => mounted && setPosts([]))
      )
      .finally(() => mounted && setLoadingPosts(false));

    return () => {
      mounted = false;
    };
  }, []);

  useEffect(() => {
    if (!isAuthenticated || !user?.userId) {
      setLoadingRoutine(false);
      return;
    }
    let mounted = true;
    setLoadingRoutine(true);
    routineService
      .getActiveRoutine(user.userId)
      .then((data) => mounted && setRoutine(data))
      .catch(() => mounted && setRoutine(null))
      .finally(() => mounted && setLoadingRoutine(false));
    return () => {
      mounted = false;
    };
  }, [isAuthenticated, user?.userId]);

  return (
    <div className="flex flex-col gap-16 sm:gap-20 pb-8">
      {/* Hero */}
      <section className="gradient-banner rounded-3xl px-6 py-12 sm:px-12 sm:py-20 text-white relative overflow-hidden animate-fade-slide-in">
        <div className="absolute -top-16 -right-16 h-64 w-64 rounded-full bg-white/10 blur-3xl" />
        <div className="absolute -bottom-20 -left-10 h-72 w-72 rounded-full bg-gold/20 blur-3xl" />
        <div className="relative max-w-2xl">
          <span className="inline-flex items-center gap-2 rounded-full bg-white/15 px-4 py-1.5 text-xs font-semibold tracking-wide uppercase mb-4">
            <Sparkles size={14} /> AI-Powered Skincare
          </span>
          <h1 className="font-display text-4xl sm:text-6xl font-bold leading-tight mb-4">
            Your Skin, Understood.
          </h1>
          <p className="text-white/85 text-base sm:text-lg mb-8 max-w-xl">
            Scan your skin with AI, discover what it needs, and get a personalized
            morning &amp; evening routine — plus shop products picked just for you.
          </p>
          <div className="flex flex-wrap gap-3">
            <Button to="/scan" variant="gold" size="lg">
              <ScanFace size={18} /> Start AI Skin Scan
            </Button>
            {!isAuthenticated && (
              <Button to="/register" variant="outline" size="lg" className="!border-white !text-white hover:!bg-white hover:!text-wine">
                Create free account <ArrowRight size={16} />
              </Button>
            )}
          </div>
        </div>
      </section>

      {/* AI scan + routine preview */}
      <section className="grid sm:grid-cols-2 gap-6">
        <Card className="p-6 sm:p-8 flex flex-col gap-4 animate-fade-slide-in">
          <div className="h-12 w-12 rounded-2xl bg-soft-pink text-wine flex items-center justify-center">
            <Camera size={22} />
          </div>
          <div>
            <h3 className="font-display text-xl font-bold text-ink mb-1">AI Skin Scan</h3>
            <p className="text-subtext text-sm">
              Upload a photo and let our AI detect acne, blackheads, wrinkles, pores, and
              more — then get a personalized routine in seconds.
            </p>
          </div>
          <div className="flex flex-wrap items-center gap-2 text-xs text-subtext">
            <span className="px-2.5 py-1 rounded-full bg-soft-pink text-wine font-medium">Upload photo</span>
            <span className="px-2.5 py-1 rounded-full bg-soft-pink text-wine font-medium">Skin score</span>
            <span className="px-2.5 py-1 rounded-full bg-soft-pink text-wine font-medium">Routine builder</span>
          </div>
          <Button to="/scan" className="self-start mt-auto">
            Try it now <ArrowRight size={16} />
          </Button>
        </Card>

        <Card className="p-6 sm:p-8 flex flex-col gap-4 animate-fade-slide-in">
          <div className="h-12 w-12 rounded-2xl bg-soft-pink text-wine flex items-center justify-center">
            <Sun size={22} />
          </div>
          {loadingRoutine ? (
            <div className="space-y-2 flex-1">
              <div className="h-5 w-2/3 gradient-shimmer rounded-lg" />
              <div className="h-4 w-full gradient-shimmer rounded-lg" />
              <div className="h-4 w-5/6 gradient-shimmer rounded-lg" />
            </div>
          ) : routine ? (
            <>
              <div>
                <h3 className="font-display text-xl font-bold text-ink mb-1">
                  {routine.routineName || "Your Skin Routine"}
                </h3>
                <p className="text-subtext text-sm">Morning steps to keep you on track today.</p>
              </div>
              <ul className="flex flex-col gap-2">
                {(routine.morning || []).slice(0, 3).map((step) => (
                  <li key={step._id} className="flex items-center gap-2 text-sm text-ink">
                    <CheckCircle2 size={16} className="text-wine shrink-0" />
                    {step.stepName}
                  </li>
                ))}
                {(routine.morning || []).length === 0 && (
                  <li className="text-sm text-subtext">No morning steps yet.</li>
                )}
              </ul>
              <Button to="/routine" variant="secondary" className="self-start mt-auto">
                View My Routine <ArrowRight size={16} />
              </Button>
            </>
          ) : (
            <>
              <div>
                <h3 className="font-display text-xl font-bold text-ink mb-1">
                  Personalized Routines
                </h3>
                <p className="text-subtext text-sm">
                  After your first AI skin scan, we'll build a custom morning and evening
                  routine — and track your progress with streaks and points.
                </p>
              </div>
              <div className="flex items-center gap-4 text-subtext text-sm mt-auto">
                <span className="flex items-center gap-1.5">
                  <Sun size={15} className="text-gold" /> Morning
                </span>
                <span className="flex items-center gap-1.5">
                  <Moon size={15} className="text-wine" /> Evening
                </span>
              </div>
              <Button to="/scan" variant="secondary" className="self-start">
                Get my routine <ArrowRight size={16} />
              </Button>
            </>
          )}
        </Card>
      </section>

      {/* Shop preview */}
      <section>
        <SectionHeader
          title="Shop Skincare"
          subtitle="Hand-picked products from trusted sellers"
          to="/shop"
        />
        {loadingProducts ? (
          <SkeletonRow count={5} />
        ) : products.length > 0 ? (
          <HorizontalSlider>
            {products.map((p) => (
              <ProductCard key={p._id} product={p} />
            ))}
          </HorizontalSlider>
        ) : (
          <Card className="p-8 text-center text-subtext text-sm flex flex-col items-center gap-2">
            <ShoppingBag size={28} className="text-dusty-rose" />
            No products available yet — check back soon!
          </Card>
        )}
      </section>

      {/* Community preview */}
      <section>
        <SectionHeader
          title="From the Community"
          subtitle="Tips, reviews, and routines shared by Skinova users"
          to="/community"
        />
        {loadingPosts ? (
          <SkeletonRow count={3} itemClassName="w-72 h-48" />
        ) : posts.length > 0 ? (
          <HorizontalSlider itemClassName="w-72 sm:w-80">
            {posts.map((post) => (
              <PostCard key={post._id} post={post} />
            ))}
          </HorizontalSlider>
        ) : (
          <Card className="p-8 text-center text-subtext text-sm flex flex-col items-center gap-2">
            <Users size={28} className="text-dusty-rose" />
            No community posts yet — be the first to share!
          </Card>
        )}
      </section>

      {/* App download CTA */}
      <section>
        <AppDownloadBanner message="Continue your skincare journey on the app" />
      </section>
    </div>
  );
}
