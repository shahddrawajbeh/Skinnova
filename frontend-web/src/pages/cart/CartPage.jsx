import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { Minus, Plus, Trash2, Loader2, ShoppingCart, ArrowRight } from "lucide-react";
import Card from "../../components/common/Card";
import Button from "../../components/common/Button";
import EmptyState from "../../components/common/EmptyState";
import { resolveImageUrl } from "../../services/api";
import { useAuth } from "../../context/AuthContext";
import { useToast } from "../../context/ToastContext";
import { cartService } from "../../services/cartService";
import { formatPrice } from "../../utils/format";

export default function CartPage() {
  const { user } = useAuth();
  const toast = useToast();

  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(true);
  const [busyKey, setBusyKey] = useState(null);

  const load = () => {
    setLoading(true);
    cartService
      .fetchCart(user.userId)
      .then((data) => setItems(data || []))
      .catch(() => toast.error("Couldn't load your cart."))
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    load();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [user.userId]);

  const itemKey = (item) => `${item.productId?._id}_${item.storeId?._id}`;

  const handleQuantity = async (item, delta) => {
    const newQty = item.quantity + delta;
    if (newQty < 1) return;
    const key = itemKey(item);
    setBusyKey(key);
    try {
      await cartService.updateQuantity({
        userId: user.userId,
        productId: item.productId._id,
        storeId: item.storeId._id,
        quantity: newQty,
      });
      setItems((prev) =>
        prev.map((it) => (itemKey(it) === key ? { ...it, quantity: newQty } : it))
      );
    } catch (err) {
      toast.error(err.response?.data?.message || "Couldn't update quantity.");
    } finally {
      setBusyKey(null);
    }
  };

  const handleRemove = async (item) => {
    const key = itemKey(item);
    setBusyKey(key);
    try {
      await cartService.removeFromCart({
        userId: user.userId,
        productId: item.productId._id,
        storeId: item.storeId._id,
      });
      setItems((prev) => prev.filter((it) => itemKey(it) !== key));
      toast.success("Removed from cart.");
    } catch {
      toast.error("Couldn't remove item.");
    } finally {
      setBusyKey(null);
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center py-24">
        <Loader2 className="animate-spin text-wine" size={32} />
      </div>
    );
  }

  if (items.length === 0) {
    return (
      <EmptyState
        icon={ShoppingCart}
        title="Your cart is empty"
        message="Browse the shop to find products picked for your skin."
        action={
          <Button to="/shop" size="md">
            Go to shop
          </Button>
        }
      />
    );
  }

  const subtotal = items.reduce((sum, it) => sum + it.price * it.quantity, 0);
  const currency = items[0]?.currency || "ILS";

  return (
    <div className="max-w-4xl mx-auto flex flex-col gap-8 animate-fade-slide-in">
      <h1 className="font-display text-3xl sm:text-4xl font-bold text-ink">Your Cart</h1>

      <div className="flex flex-col gap-3">
        {items.map((item, i) => {
          const key = itemKey(item);
          const product = item.productId || {};
          const busy = busyKey === key;
          return (
            <Card
              key={key}
              className="p-4 flex items-center gap-4 animate-pop-in"
              style={{ animationDelay: `${Math.min(i, 9) * 50}ms` }}
            >
              <Link to={`/shop/product/${product._id}`} className="h-20 w-20 rounded-xl overflow-hidden bg-soft-pink shrink-0">
                {product.imageUrl ? (
                  <img src={resolveImageUrl(product.imageUrl)} alt={product.name} className="h-full w-full object-cover" />
                ) : (
                  <div className="h-full w-full flex items-center justify-center text-wine/30 font-display text-xl">S</div>
                )}
              </Link>
              <div className="flex-1 min-w-0">
                <p className="text-[11px] uppercase tracking-wide text-subtext truncate">{product.brand}</p>
                <Link to={`/shop/product/${product._id}`} className="font-semibold text-ink hover:text-wine transition-colors line-clamp-1">
                  {product.name}
                </Link>
                <p className="text-xs text-subtext mt-0.5">{item.storeId?.storeName}</p>
                <p className="text-sm font-bold text-wine mt-1">{formatPrice(item.price, item.currency)}</p>
              </div>
              <div className="flex items-center gap-2 shrink-0">
                <button
                  onClick={() => handleQuantity(item, -1)}
                  disabled={busy || item.quantity <= 1}
                  aria-label="Decrease quantity"
                  className="h-8 w-8 rounded-full border border-divider flex items-center justify-center text-wine hover:bg-soft-pink transition-all disabled:opacity-40"
                >
                  <Minus size={14} />
                </button>
                <span className="w-6 text-center font-semibold text-sm">{item.quantity}</span>
                <button
                  onClick={() => handleQuantity(item, 1)}
                  disabled={busy}
                  aria-label="Increase quantity"
                  className="h-8 w-8 rounded-full border border-divider flex items-center justify-center text-wine hover:bg-soft-pink transition-all disabled:opacity-40"
                >
                  <Plus size={14} />
                </button>
                <button
                  onClick={() => handleRemove(item)}
                  disabled={busy}
                  aria-label="Remove item"
                  className="h-8 w-8 rounded-full flex items-center justify-center text-subtext hover:text-danger hover:bg-soft-pink transition-all ml-1"
                >
                  {busy ? <Loader2 size={14} className="animate-spin" /> : <Trash2 size={14} />}
                </button>
              </div>
            </Card>
          );
        })}
      </div>

      <Card className="p-6 flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <p className="text-sm text-subtext">Subtotal</p>
          <p className="font-display text-2xl font-bold text-ink">{formatPrice(subtotal, currency)}</p>
          <p className="text-xs text-subtext mt-1">Delivery fees calculated at checkout.</p>
        </div>
        <Button to="/checkout" size="lg">
          Proceed to checkout <ArrowRight size={16} />
        </Button>
      </Card>
    </div>
  );
}
