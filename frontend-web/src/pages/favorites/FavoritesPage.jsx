import { useEffect, useState } from "react";
import { Loader2, Heart } from "lucide-react";
import Button from "../../components/common/Button";
import EmptyState from "../../components/common/EmptyState";
import ProductCard from "../../components/product/ProductCard";
import { useAuth } from "../../context/AuthContext";
import { useToast } from "../../context/ToastContext";
import { favoriteService } from "../../services/favoriteService";
import { quickAddToCart } from "../../utils/cartHelpers";

export default function FavoritesPage() {
  const { user } = useAuth();
  const toast = useToast();

  const [products, setProducts] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    favoriteService
      .fetchFavorites(user.userId)
      .then((data) => setProducts(data || []))
      .catch(() => toast.error("Couldn't load your favorites."))
      .finally(() => setLoading(false));
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [user.userId]);

  const handleToggleFavorite = async (product) => {
    setProducts((prev) => prev.filter((p) => p._id !== product._id));
    try {
      await favoriteService.toggleFavorite(user.userId, product._id);
      toast.success("Removed from favorites.");
    } catch {
      toast.error("Couldn't update favorites.");
      setProducts((prev) => [...prev, product]);
    }
  };

  const handleAddToCart = async (product) => {
    await quickAddToCart({ userId: user.userId, product, toast });
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center py-24">
        <Loader2 className="animate-spin text-wine" size={32} />
      </div>
    );
  }

  if (products.length === 0) {
    return (
      <EmptyState
        icon={Heart}
        title="No favorites yet"
        message="Save products you love to find them here later."
        action={
          <Button to="/shop" size="md">
            Browse the shop
          </Button>
        }
      />
    );
  }

  return (
    <div className="flex flex-col gap-6 animate-fade-slide-in">
      <h1 className="font-display text-3xl sm:text-4xl font-bold text-ink">Favorites</h1>
      <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-4">
        {products.map((p, i) => (
          <div key={p._id} className="animate-pop-in" style={{ animationDelay: `${Math.min(i, 9) * 40}ms` }}>
            <ProductCard
              product={p}
              className="!w-full"
              isFavorite
              onToggleFavorite={handleToggleFavorite}
              onAddToCart={handleAddToCart}
            />
          </div>
        ))}
      </div>
    </div>
  );
}
