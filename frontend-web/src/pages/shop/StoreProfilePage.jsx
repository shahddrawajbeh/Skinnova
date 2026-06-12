import { useEffect, useState } from "react";
import { useParams } from "react-router-dom";
import { Star, Store as StoreIcon, MapPin, Clock, Truck, Loader2, ShoppingBag } from "lucide-react";
import Card from "../../components/common/Card";
import Button from "../../components/common/Button";
import EmptyState from "../../components/common/EmptyState";
import ProductCard from "../../components/product/ProductCard";
import { resolveImageUrl } from "../../services/api";
import { useAuth } from "../../context/AuthContext";
import { useToast } from "../../context/ToastContext";
import { storeService } from "../../services/storeService";
import { favoriteService } from "../../services/favoriteService";
import { cartService } from "../../services/cartService";
import { timeAgo } from "../../utils/format";

export default function StoreProfilePage() {
  const { id } = useParams();
  const { isAuthenticated, user } = useAuth();
  const toast = useToast();

  const [store, setStore] = useState(null);
  const [storeProducts, setStoreProducts] = useState([]);
  const [reviews, setReviews] = useState([]);
  const [favoriteIds, setFavoriteIds] = useState(new Set());
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let mounted = true;
    setLoading(true);
    Promise.all([
      storeService.fetchStoreById(id),
      storeService.fetchStoreProducts(id),
      storeService.fetchStoreReviews(id),
    ])
      .then(([s, sp, r]) => {
        if (!mounted) return;
        setStore(s);
        setStoreProducts(sp);
        setReviews(r);
      })
      .catch(() => mounted && setStore(null))
      .finally(() => mounted && setLoading(false));
    return () => {
      mounted = false;
    };
  }, [id]);

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

  const handleAddToCart = async (storeProduct) => {
    if (!isAuthenticated) {
      toast.info("Log in to add items to your cart.");
      return;
    }
    try {
      await cartService.addToCart({
        userId: user.userId,
        productId: storeProduct.productId._id,
        storeId: id,
        quantity: 1,
        price: storeProduct.price,
        currency: storeProduct.currency,
      });
      toast.success("Added to cart!");
    } catch (err) {
      toast.error(err.response?.data?.message || "Couldn't add to cart.");
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center py-24">
        <Loader2 className="animate-spin text-wine" size={32} />
      </div>
    );
  }

  if (!store) {
    return (
      <EmptyState
        icon={StoreIcon}
        title="Store not found"
        message="This store may no longer be available."
        action={
          <Button to="/shop" variant="secondary">
            Back to shop
          </Button>
        }
      />
    );
  }

  const delivery = store.deliveryInfo || {};

  return (
    <div className="flex flex-col gap-10 animate-fade-slide-in">
      <section className="rounded-3xl overflow-hidden">
        <div className="h-40 sm:h-56 bg-soft-pink relative">
          {store.coverImageUrl ? (
            <img src={resolveImageUrl(store.coverImageUrl)} alt="" className="h-full w-full object-cover" />
          ) : (
            <div className="h-full w-full gradient-banner" />
          )}
        </div>
        <div className="bg-white px-6 sm:px-10 pb-6 -mt-10 relative flex flex-col sm:flex-row sm:items-end gap-4 rounded-b-3xl border border-divider border-t-0">
          <div className="h-20 w-20 rounded-2xl bg-white shadow-md border border-divider flex items-center justify-center overflow-hidden shrink-0">
            {store.logoUrl ? (
              <img src={resolveImageUrl(store.logoUrl)} alt={store.storeName} className="h-full w-full object-cover" />
            ) : (
              <StoreIcon size={28} className="text-wine" />
            )}
          </div>
          <div className="flex-1 pt-3 sm:pt-0">
            <h1 className="font-display text-2xl sm:text-3xl font-bold text-ink">{store.storeName}</h1>
            <div className="flex flex-wrap items-center gap-3 text-sm text-subtext mt-1">
              {store.rating != null && (
                <span className="flex items-center gap-1">
                  <Star size={14} className="text-gold fill-gold" /> {Number(store.rating).toFixed(1)}
                </span>
              )}
              {store.city && (
                <span className="flex items-center gap-1">
                  <MapPin size={14} /> {store.city}
                </span>
              )}
              {store.responseTime && (
                <span className="flex items-center gap-1">
                  <Clock size={14} /> Response {store.responseTime}
                </span>
              )}
              {store.shippingTime && (
                <span className="flex items-center gap-1">
                  <Truck size={14} /> Ships in {store.shippingTime}
                </span>
              )}
            </div>
          </div>
        </div>
      </section>

      {store.description && (
        <section>
          <p className="text-subtext text-sm leading-relaxed max-w-3xl">{store.description}</p>
        </section>
      )}

      {delivery.areas?.length > 0 && (
        <section>
          <h2 className="font-display text-xl font-bold text-ink mb-3">Delivery areas</h2>
          <div className="flex flex-wrap gap-2">
            {delivery.areas.map((a, i) => (
              <span key={i} className="text-xs font-medium px-3 py-1.5 rounded-full bg-soft-pink text-wine">
                {a.name} · {a.time}
              </span>
            ))}
          </div>
        </section>
      )}

      <section>
        <h2 className="font-display text-xl font-bold text-ink mb-3">Products</h2>
        {storeProducts.length === 0 ? (
          <Card className="p-8 text-center text-subtext text-sm flex flex-col items-center gap-2">
            <ShoppingBag size={28} className="text-dusty-rose" />
            No products listed yet.
          </Card>
        ) : (
          <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-4">
            {storeProducts
              .filter((sp) => sp.productId)
              .map((sp, i) => (
                <div key={sp._id} className="animate-pop-in" style={{ animationDelay: `${Math.min(i, 9) * 40}ms` }}>
                  <ProductCard
                    className="!w-full"
                    product={{ ...sp.productId, price: sp.price, currency: sp.currency }}
                    isFavorite={favoriteIds.has(sp.productId._id)}
                    onToggleFavorite={handleToggleFavorite}
                    onAddToCart={() => handleAddToCart(sp)}
                  />
                </div>
              ))}
          </div>
        )}
      </section>

      <section>
        <h2 className="font-display text-xl font-bold text-ink mb-3">Reviews</h2>
        {reviews.length === 0 ? (
          <p className="text-sm text-subtext">No reviews yet.</p>
        ) : (
          <div className="flex flex-col gap-3">
            {reviews.map((r) => (
              <Card key={r._id} className="p-4">
                <div className="flex items-center justify-between mb-1">
                  <p className="font-semibold text-ink text-sm">{r.userName}</p>
                  <p className="text-xs text-subtext">{timeAgo(r.createdAt)}</p>
                </div>
                <div className="flex items-center gap-0.5 mb-1.5">
                  {[1, 2, 3, 4, 5].map((n) => (
                    <Star key={n} size={13} className={n <= r.rating ? "text-gold fill-gold" : "text-divider"} />
                  ))}
                </div>
                {r.comment && <p className="text-sm text-subtext">{r.comment}</p>}
              </Card>
            ))}
          </div>
        )}
      </section>
    </div>
  );
}
