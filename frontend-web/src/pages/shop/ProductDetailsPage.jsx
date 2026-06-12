import { useEffect, useState } from "react";
import { useParams, useNavigate, Link } from "react-router-dom";
import {
  Star,
  Heart,
  ShoppingCart,
  Loader2,
  Store as StoreIcon,
  CheckCircle2,
  Send,
} from "lucide-react";
import Card from "../../components/common/Card";
import Button from "../../components/common/Button";
import EmptyState from "../../components/common/EmptyState";
import { resolveImageUrl } from "../../services/api";
import { useAuth } from "../../context/AuthContext";
import { useToast } from "../../context/ToastContext";
import { productService } from "../../services/productService";
import { storeService } from "../../services/storeService";
import { favoriteService } from "../../services/favoriteService";
import { cartService } from "../../services/cartService";
import { timeAgo, formatPrice } from "../../utils/format";

const WHATS_INSIDE_LABELS = {
  alcoholFree: "Alcohol-free",
  euAllergenFree: "EU allergen-free",
  fragranceFree: "Fragrance-free",
  oilFree: "Oil-free",
  parabenFree: "Paraben-free",
  siliconeFree: "Silicone-free",
  sulfateFree: "Sulfate-free",
  crueltyFree: "Cruelty-free",
  fungalAcneSafe: "Fungal acne safe",
  reefSafe: "Reef-safe",
  vegan: "Vegan",
};

function ReviewForm({ onSubmit, submitting }) {
  const [rating, setRating] = useState(5);
  const [title, setTitle] = useState("");
  const [comment, setComment] = useState("");

  const handleSubmit = (e) => {
    e.preventDefault();
    onSubmit({ rating, title, comment });
    setTitle("");
    setComment("");
  };

  return (
    <form onSubmit={handleSubmit} className="flex flex-col gap-3">
      <div className="flex items-center gap-1">
        {[1, 2, 3, 4, 5].map((n) => (
          <button
            key={n}
            type="button"
            onClick={() => setRating(n)}
            aria-label={`${n} star`}
            className="hover:scale-110 transition-transform"
          >
            <Star size={22} className={n <= rating ? "text-gold fill-gold" : "text-divider"} />
          </button>
        ))}
      </div>
      <input
        value={title}
        onChange={(e) => setTitle(e.target.value)}
        placeholder="Review title (optional)"
        className="w-full rounded-xl border border-divider bg-cream/50 px-4 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-wine/40 focus:border-wine transition-all"
      />
      <textarea
        value={comment}
        onChange={(e) => setComment(e.target.value)}
        placeholder="Share your experience with this product..."
        rows={3}
        required
        className="w-full rounded-xl border border-divider bg-cream/50 px-4 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-wine/40 focus:border-wine transition-all resize-none"
      />
      <Button type="submit" disabled={submitting} size="sm" className="self-start">
        {submitting ? <Loader2 size={15} className="animate-spin" /> : <Send size={15} />}
        Post review
      </Button>
    </form>
  );
}

export default function ProductDetailsPage() {
  const { id } = useParams();
  const navigate = useNavigate();
  const { isAuthenticated, user, profile } = useAuth();
  const toast = useToast();

  const [product, setProduct] = useState(null);
  const [offers, setOffers] = useState([]);
  const [isFavorite, setIsFavorite] = useState(false);
  const [loading, setLoading] = useState(true);
  const [addingId, setAddingId] = useState(null);
  const [submittingReview, setSubmittingReview] = useState(false);

  useEffect(() => {
    let mounted = true;
    setLoading(true);
    Promise.all([productService.fetchProductById(id), storeService.fetchProductOffers(id)])
      .then(([p, o]) => {
        if (!mounted) return;
        setProduct(p);
        setOffers(o);
      })
      .catch(() => mounted && setProduct(null))
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
      .then((favs) => mounted && setIsFavorite(favs.some((f) => f._id === id)))
      .catch(() => {});
    return () => {
      mounted = false;
    };
  }, [isAuthenticated, user?.userId, id]);

  const handleToggleFavorite = async () => {
    if (!isAuthenticated) {
      toast.info("Log in to save favorites.");
      return;
    }
    setIsFavorite((f) => !f);
    try {
      await favoriteService.toggleFavorite(user.userId, id);
    } catch {
      toast.error("Couldn't update favorites.");
      setIsFavorite((f) => !f);
    }
  };

  const handleAddToCart = async (offer) => {
    if (!isAuthenticated) {
      toast.info("Log in to add items to your cart.");
      return;
    }
    setAddingId(offer._id);
    try {
      await cartService.addToCart({
        userId: user.userId,
        productId: id,
        storeId: offer.storeId?._id || offer.storeId,
        quantity: 1,
        price: offer.price,
        currency: offer.currency,
      });
      toast.success("Added to cart!");
    } catch (err) {
      toast.error(err.response?.data?.message || "Couldn't add to cart.");
    } finally {
      setAddingId(null);
    }
  };

  const handleAddReview = async ({ rating, title, comment }) => {
    if (!isAuthenticated) {
      toast.info("Log in to leave a review.");
      return;
    }
    setSubmittingReview(true);
    try {
      const data = await productService.addReview(id, {
        userId: user.userId,
        userName: profile?.fullName || "Skinova user",
        rating,
        title,
        comment,
      });
      setProduct((p) => ({ ...p, reviews: data.reviews, rating: data.rating }));
      toast.success("Thanks for your review!");
    } catch (err) {
      toast.error(err.response?.data?.message || "Couldn't post your review.");
    } finally {
      setSubmittingReview(false);
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center py-24">
        <Loader2 className="animate-spin text-wine" size={32} />
      </div>
    );
  }

  if (!product) {
    return (
      <EmptyState
        icon={ShoppingCart}
        title="Product not found"
        message="This product may have been removed."
        action={
          <Button to="/shop" variant="secondary">
            Back to shop
          </Button>
        }
      />
    );
  }

  const discount = product.discountPercent || 0;
  const finalPrice = discount > 0 ? product.price * (1 - discount / 100) : product.price;
  const tags = Object.entries(product.whatsInside || {}).filter(([, v]) => v);
  const recommended = product.recommendedFor || {};

  return (
    <div className="max-w-5xl mx-auto flex flex-col gap-10 animate-fade-slide-in">
      <button onClick={() => navigate(-1)} className="text-sm text-wine hover:underline self-start">
        ← Back
      </button>

      <section className="grid sm:grid-cols-2 gap-8">
        <div className="aspect-square rounded-3xl overflow-hidden bg-soft-pink">
          {product.imageUrl ? (
            <img src={resolveImageUrl(product.imageUrl)} alt={product.name} className="h-full w-full object-cover" />
          ) : (
            <div className="h-full w-full flex items-center justify-center text-wine/30 font-display text-6xl">S</div>
          )}
        </div>
        <div className="flex flex-col gap-3">
          <p className="text-xs uppercase tracking-wide text-subtext font-semibold">{product.brand}</p>
          <h1 className="font-display text-3xl font-bold text-ink">{product.name}</h1>
          {product.rating != null && product.rating > 0 && (
            <div className="flex items-center gap-1.5 text-sm text-subtext">
              <Star size={15} className="text-gold fill-gold" />
              {Number(product.rating).toFixed(1)} ({product.reviews?.length || 0} reviews)
            </div>
          )}
          <div className="flex items-center gap-3">
            {discount > 0 && (
              <span className="text-base text-subtext line-through">
                {formatPrice(product.price, product.currency)}
              </span>
            )}
            <span className="text-2xl font-bold text-wine">{formatPrice(finalPrice, product.currency)}</span>
            {discount > 0 && (
              <span className="bg-wine text-white text-xs font-bold px-2.5 py-1 rounded-full">-{discount}%</span>
            )}
          </div>
          {product.shortDescription && <p className="text-subtext text-sm leading-relaxed">{product.shortDescription}</p>}

          {tags.length > 0 && (
            <div className="flex flex-wrap gap-1.5 mt-1">
              {tags.map(([key]) => (
                <span key={key} className="flex items-center gap-1 text-[11px] font-medium px-2.5 py-1 rounded-full bg-soft-pink text-wine">
                  <CheckCircle2 size={11} /> {WHATS_INSIDE_LABELS[key] || key}
                </span>
              ))}
            </div>
          )}

          {(recommended.skinTypes?.length > 0 || recommended.concerns?.length > 0) && (
            <div className="flex flex-wrap gap-1.5">
              {[...(recommended.skinTypes || []), ...(recommended.concerns || [])].map((t) => (
                <span key={t} className="text-[11px] font-medium px-2.5 py-1 rounded-full bg-cream border border-divider text-subtext">
                  {t}
                </span>
              ))}
            </div>
          )}

          <button
            onClick={handleToggleFavorite}
            className={`mt-2 self-start flex items-center gap-2 px-5 py-2.5 rounded-full text-sm font-semibold border transition-all hover:scale-[1.03]
              ${isFavorite ? "bg-wine text-white border-wine" : "bg-white text-wine border-dusty-rose-light hover:bg-soft-pink"}`}
          >
            <Heart size={16} fill={isFavorite ? "currentColor" : "none"} />
            {isFavorite ? "Saved to favorites" : "Add to favorites"}
          </button>
        </div>
      </section>

      {product.directionsOfUse && (
        <section>
          <h2 className="font-display text-xl font-bold text-ink mb-2">Directions of use</h2>
          <p className="text-subtext text-sm leading-relaxed">{product.directionsOfUse}</p>
        </section>
      )}

      {product.ingredients?.length > 0 && (
        <section>
          <h2 className="font-display text-xl font-bold text-ink mb-3">Ingredients</h2>
          <div className="grid sm:grid-cols-2 gap-3">
            {product.ingredients.map((ing, i) => (
              <Card key={i} className="p-4">
                <p className="font-semibold text-ink text-sm">{ing.name}</p>
                {ing.description && <p className="text-xs text-subtext mt-1">{ing.description}</p>}
              </Card>
            ))}
          </div>
        </section>
      )}

      <section>
        <h2 className="font-display text-xl font-bold text-ink mb-3">Available at</h2>
        {offers.length === 0 ? (
          <Card className="p-6 text-sm text-subtext">Not currently available in any store.</Card>
        ) : (
          <div className="flex flex-col gap-3">
            {offers.map((offer) => (
              <Card key={offer._id} className="p-4 flex items-center justify-between gap-4 flex-wrap">
                <Link
                  to={`/shop/store/${offer.storeId?._id}`}
                  className="flex items-center gap-3 text-sm font-semibold text-ink hover:text-wine transition-colors"
                >
                  <div className="h-9 w-9 rounded-xl bg-soft-pink text-wine flex items-center justify-center overflow-hidden shrink-0">
                    {offer.storeId?.logoUrl ? (
                      <img src={resolveImageUrl(offer.storeId.logoUrl)} alt="" className="h-full w-full object-cover" />
                    ) : (
                      <StoreIcon size={16} />
                    )}
                  </div>
                  {offer.storeId?.storeName || "Store"}
                </Link>
                <div className="flex items-center gap-4">
                  <span className="font-bold text-wine">{formatPrice(offer.price, offer.currency)}</span>
                  <span className="text-xs text-subtext">
                    {offer.stockCount > 0 ? `${offer.stockCount} in stock` : "Out of stock"}
                  </span>
                  <Button
                    size="sm"
                    disabled={offer.stockCount <= 0 || addingId === offer._id}
                    onClick={() => handleAddToCart(offer)}
                  >
                    {addingId === offer._id ? <Loader2 size={14} className="animate-spin" /> : <ShoppingCart size={14} />}
                    Add to cart
                  </Button>
                </div>
              </Card>
            ))}
          </div>
        )}
      </section>

      <section>
        <h2 className="font-display text-xl font-bold text-ink mb-3">Reviews</h2>
        {isAuthenticated && (
          <Card className="p-4 mb-4">
            <ReviewForm onSubmit={handleAddReview} submitting={submittingReview} />
          </Card>
        )}
        {(product.reviews || []).length === 0 ? (
          <p className="text-sm text-subtext">No reviews yet. Be the first to share your experience!</p>
        ) : (
          <div className="flex flex-col gap-3">
            {product.reviews.map((r, i) => (
              <Card key={r._id || i} className="p-4">
                <div className="flex items-center justify-between mb-1">
                  <p className="font-semibold text-ink text-sm">{r.userName}</p>
                  <p className="text-xs text-subtext">{timeAgo(r.createdAt)}</p>
                </div>
                <div className="flex items-center gap-0.5 mb-1.5">
                  {[1, 2, 3, 4, 5].map((n) => (
                    <Star key={n} size={13} className={n <= r.rating ? "text-gold fill-gold" : "text-divider"} />
                  ))}
                </div>
                {r.title && <p className="font-semibold text-sm text-ink">{r.title}</p>}
                {r.comment && <p className="text-sm text-subtext mt-0.5">{r.comment}</p>}
              </Card>
            ))}
          </div>
        )}
      </section>
    </div>
  );
}
