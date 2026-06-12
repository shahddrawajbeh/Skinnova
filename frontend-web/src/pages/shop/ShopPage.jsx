import { useEffect, useMemo, useState } from "react";
import { Search, ShoppingBag, Store as StoreIcon } from "lucide-react";
import Card from "../../components/common/Card";
import SectionHeader from "../../components/common/SectionHeader";
import HorizontalSlider from "../../components/common/HorizontalSlider";
import { SkeletonRow } from "../../components/common/Skeleton";
import EmptyState from "../../components/common/EmptyState";
import ProductCard from "../../components/product/ProductCard";
import StoreCard from "../../components/store/StoreCard";
import { useAuth } from "../../context/AuthContext";
import { useToast } from "../../context/ToastContext";
import { productService } from "../../services/productService";
import { storeService } from "../../services/storeService";
import { favoriteService } from "../../services/favoriteService";
import { quickAddToCart } from "../../utils/cartHelpers";

export default function ShopPage() {
  const { isAuthenticated, user } = useAuth();
  const toast = useToast();

  const [products, setProducts] = useState([]);
  const [stores, setStores] = useState([]);
  const [favoriteIds, setFavoriteIds] = useState(new Set());
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [activeCategory, setActiveCategory] = useState("all");

  useEffect(() => {
    let mounted = true;
    Promise.all([productService.fetchProducts(), storeService.fetchStores()])
      .then(([p, s]) => {
        if (!mounted) return;
        setProducts(p);
        setStores(s);
      })
      .catch(() => mounted && toast.error("Couldn't load the shop right now."))
      .finally(() => mounted && setLoading(false));
    return () => {
      mounted = false;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  useEffect(() => {
    if (!isAuthenticated || !user?.userId) return;
    let mounted = true;
    favoriteService
      .fetchFavorites(user.userId)
      .then((favs) => mounted && setFavoriteIds(new Set(favs.map((f) => f._id))))
      .catch(() => {});
    return () => {
      mounted = false;
    };
  }, [isAuthenticated, user?.userId]);

  const categories = useMemo(() => {
    const set = new Set();
    products.forEach((p) => p.category && set.add(p.category));
    return ["all", ...Array.from(set)];
  }, [products]);

  const filteredProducts = useMemo(() => {
    return products.filter((p) => {
      const matchesCategory = activeCategory === "all" || p.category === activeCategory;
      const matchesSearch =
        !search.trim() ||
        `${p.name} ${p.brand}`.toLowerCase().includes(search.trim().toLowerCase());
      return matchesCategory && matchesSearch;
    });
  }, [products, activeCategory, search]);

  const handleToggleFavorite = async (product) => {
    if (!isAuthenticated) {
      toast.info("Log in to save favorites.");
      return;
    }
    const wasFavorite = favoriteIds.has(product._id);
    setFavoriteIds((prev) => {
      const next = new Set(prev);
      wasFavorite ? next.delete(product._id) : next.add(product._id);
      return next;
    });
    try {
      await favoriteService.toggleFavorite(user.userId, product._id);
    } catch {
      toast.error("Couldn't update favorites.");
      setFavoriteIds((prev) => {
        const next = new Set(prev);
        wasFavorite ? next.add(product._id) : next.delete(product._id);
        return next;
      });
    }
  };

  const handleAddToCart = async (product) => {
    if (!isAuthenticated) {
      toast.info("Log in to add items to your cart.");
      return;
    }
    await quickAddToCart({ userId: user.userId, product, toast });
  };

  const isFiltering = activeCategory !== "all" || search.trim().length > 0;

  return (
    <div className="flex flex-col gap-12 animate-fade-slide-in">
      <section className="gradient-banner rounded-3xl px-6 py-10 sm:px-12 sm:py-14 text-white relative overflow-hidden">
        <div className="absolute -top-16 -right-10 h-56 w-56 rounded-full bg-white/10 blur-3xl" />
        <div className="relative max-w-2xl">
          <h1 className="font-display text-3xl sm:text-5xl font-bold mb-3">Shop Skincare</h1>
          <p className="text-white/85 text-sm sm:text-base mb-6">
            Discover products picked for your skin from trusted local sellers.
          </p>
          <div className="relative max-w-md">
            <Search size={18} className="absolute left-4 top-1/2 -translate-y-1/2 text-wine/60" />
            <input
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="Search products or brands..."
              className="w-full rounded-full border-0 bg-white/95 pl-11 pr-4 py-3 text-sm text-ink
                focus:outline-none focus:ring-2 focus:ring-gold shadow-lg"
            />
          </div>
        </div>
      </section>

      <section className="flex gap-2 overflow-x-auto no-scrollbar pb-1">
        {categories.map((cat) => (
          <button
            key={cat}
            onClick={() => setActiveCategory(cat)}
            className={`shrink-0 px-5 py-2 rounded-full text-sm font-semibold capitalize transition-all
              ${
                activeCategory === cat
                  ? "bg-wine text-white shadow-md"
                  : "bg-soft-pink text-wine hover:bg-dusty-rose-light"
              }`}
          >
            {cat}
          </button>
        ))}
      </section>

      {!isFiltering && (
        <section>
          <SectionHeader title="Featured Products" subtitle="Fresh picks from across the marketplace" />
          {loading ? (
            <SkeletonRow count={5} />
          ) : products.length > 0 ? (
            <HorizontalSlider>
              {products.slice(0, 12).map((p) => (
                <ProductCard
                  key={p._id}
                  product={p}
                  isFavorite={favoriteIds.has(p._id)}
                  onToggleFavorite={handleToggleFavorite}
                  onAddToCart={handleAddToCart}
                />
              ))}
            </HorizontalSlider>
          ) : (
            <Card className="p-8 text-center text-subtext text-sm">No products available yet.</Card>
          )}
        </section>
      )}

      {!isFiltering && (
        <section>
          <SectionHeader title="Trusted Stores" subtitle="Browse storefronts from our sellers" />
          {loading ? (
            <SkeletonRow count={4} itemClassName="w-64 h-32" />
          ) : stores.length > 0 ? (
            <HorizontalSlider>
              {stores.map((s) => (
                <StoreCard key={s._id} store={s} />
              ))}
            </HorizontalSlider>
          ) : (
            <Card className="p-8 text-center text-subtext text-sm flex flex-col items-center gap-2">
              <StoreIcon size={28} className="text-dusty-rose" />
              No stores available yet.
            </Card>
          )}
        </section>
      )}

      <section>
        <SectionHeader
          title={isFiltering ? "Search Results" : "All Products"}
          subtitle={`${filteredProducts.length} product${filteredProducts.length === 1 ? "" : "s"}`}
        />
        {loading ? (
          <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-4">
            {Array.from({ length: 10 }).map((_, i) => (
              <SkeletonRow key={i} count={1} />
            ))}
          </div>
        ) : filteredProducts.length > 0 ? (
          <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-4">
            {filteredProducts.map((p, i) => (
              <div key={p._id} className="animate-pop-in" style={{ animationDelay: `${Math.min(i, 9) * 40}ms` }}>
                <ProductCard
                  product={p}
                  className="!w-full"
                  isFavorite={favoriteIds.has(p._id)}
                  onToggleFavorite={handleToggleFavorite}
                  onAddToCart={handleAddToCart}
                />
              </div>
            ))}
          </div>
        ) : (
          <EmptyState
            icon={ShoppingBag}
            title="No products found"
            message="Try a different search term or category."
          />
        )}
      </section>
    </div>
  );
}
