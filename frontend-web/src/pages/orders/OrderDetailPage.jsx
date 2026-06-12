import { useEffect, useState } from "react";
import { useParams, Link } from "react-router-dom";
import { Loader2, Package, MapPin, Phone, CheckCircle2, Star, Send, CircleDot } from "lucide-react";
import Card from "../../components/common/Card";
import Button from "../../components/common/Button";
import EmptyState from "../../components/common/EmptyState";
import { resolveImageUrl } from "../../services/api";
import { useAuth } from "../../context/AuthContext";
import { useToast } from "../../context/ToastContext";
import { orderService } from "../../services/orderService";
import { formatPrice, orderStatusStyle, timeAgo } from "../../utils/format";

function RateStoreForm({ onSubmit, submitting }) {
  const [rating, setRating] = useState(5);
  const [comment, setComment] = useState("");

  return (
    <form
      onSubmit={(e) => {
        e.preventDefault();
        onSubmit({ rating, comment });
      }}
      className="flex flex-col gap-3"
    >
      <div className="flex items-center gap-1">
        {[1, 2, 3, 4, 5].map((n) => (
          <button key={n} type="button" onClick={() => setRating(n)} aria-label={`${n} star`} className="hover:scale-110 transition-transform">
            <Star size={22} className={n <= rating ? "text-gold fill-gold" : "text-divider"} />
          </button>
        ))}
      </div>
      <textarea
        value={comment}
        onChange={(e) => setComment(e.target.value)}
        placeholder="How was your experience with this store?"
        rows={2}
        className="w-full rounded-xl border border-divider bg-cream/50 px-4 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-wine/40 focus:border-wine transition-all resize-none"
      />
      <Button type="submit" disabled={submitting} size="sm" className="self-start">
        {submitting ? <Loader2 size={15} className="animate-spin" /> : <Send size={15} />}
        Submit review
      </Button>
    </form>
  );
}

export default function OrderDetailPage() {
  const { id } = useParams();
  const { user, profile } = useAuth();
  const toast = useToast();

  const [order, setOrder] = useState(null);
  const [loading, setLoading] = useState(true);
  const [confirming, setConfirming] = useState(false);
  const [submittingRating, setSubmittingRating] = useState(false);

  const load = () => {
    orderService
      .fetchOrderById(id)
      .then((data) => setOrder(data))
      .catch(() => setOrder(null))
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    load();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [id]);

  const handleConfirmReceived = async () => {
    setConfirming(true);
    try {
      const data = await orderService.confirmReceived(id, user.userId);
      setOrder(data.order);
      toast.success("Thanks for confirming!");
    } catch (err) {
      toast.error(err.response?.data?.message || "Couldn't confirm receipt.");
    } finally {
      setConfirming(false);
    }
  };

  const handleRateStore = async ({ rating, comment }) => {
    setSubmittingRating(true);
    try {
      const data = await orderService.rateStore(id, {
        userId: user.userId,
        userName: profile?.fullName,
        rating,
        comment,
      });
      setOrder(data.order);
      toast.success("Thanks for your review! It's pending admin approval.");
    } catch (err) {
      toast.error(err.response?.data?.message || "Couldn't submit your review.");
    } finally {
      setSubmittingRating(false);
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center py-24">
        <Loader2 className="animate-spin text-wine" size={32} />
      </div>
    );
  }

  if (!order) {
    return (
      <EmptyState
        icon={Package}
        title="Order not found"
        action={
          <Button to="/orders" variant="secondary">
            Back to orders
          </Button>
        }
      />
    );
  }

  const style = orderStatusStyle(order.status);
  const currency = order.items?.[0]?.currency || "ILS";

  return (
    <div className="max-w-3xl mx-auto flex flex-col gap-8 animate-fade-slide-in">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
        <div>
          <Link to="/orders" className="text-sm text-wine hover:underline">
            ← Back to orders
          </Link>
          <h1 className="font-display text-2xl sm:text-3xl font-bold text-ink mt-1">
            {order.storeId?.storeName || "Order"}
          </h1>
          <p className="text-xs text-subtext mt-1">Placed {timeAgo(order.createdAt)}</p>
        </div>
        <span className={`text-sm font-semibold px-4 py-1.5 rounded-full self-start ${style.bg} ${style.fg}`}>
          {style.label}
        </span>
      </div>

      {order.trackingHistory?.length > 0 && (
        <Card className="p-5">
          <h2 className="font-display text-lg font-bold text-ink mb-4">Tracking</h2>
          <div className="flex flex-col gap-4">
            {order.trackingHistory.map((t, i) => {
              const tStyle = orderStatusStyle(t.status);
              const isLast = i === order.trackingHistory.length - 1;
              return (
                <div key={i} className="flex items-start gap-3">
                  <div className="flex flex-col items-center">
                    <div className={`h-3 w-3 rounded-full ${isLast ? "bg-wine" : "bg-divider"}`} />
                    {i < order.trackingHistory.length - 1 && <div className="w-px flex-1 bg-divider mt-1" style={{ minHeight: 24 }} />}
                  </div>
                  <div className="-mt-1">
                    <p className={`text-sm font-semibold ${isLast ? "text-ink" : "text-subtext"}`}>{tStyle.label}</p>
                    <p className="text-xs text-subtext">{timeAgo(t.changedAt)}</p>
                  </div>
                </div>
              );
            })}
          </div>
        </Card>
      )}

      <Card className="p-5 flex flex-col gap-3">
        <h2 className="font-display text-lg font-bold text-ink">Items</h2>
        {order.items?.map((item, i) => (
          <div key={i} className="flex items-center gap-3">
            <div className="h-14 w-14 rounded-xl overflow-hidden bg-soft-pink shrink-0">
              {item.productId?.imageUrl ? (
                <img src={resolveImageUrl(item.productId.imageUrl)} alt="" className="h-full w-full object-cover" />
              ) : (
                <div className="h-full w-full flex items-center justify-center text-wine/30 font-display">S</div>
              )}
            </div>
            <div className="flex-1 min-w-0">
              <p className="font-semibold text-ink text-sm line-clamp-1">{item.productId?.name || "Product"}</p>
              <p className="text-xs text-subtext">{item.productId?.brand}</p>
            </div>
            <p className="text-sm text-subtext shrink-0">
              {item.quantity} × {formatPrice(item.price, item.currency)}
            </p>
          </div>
        ))}
        <div className="h-px bg-divider my-1" />
        <div className="flex justify-between text-sm text-subtext">
          <span>Subtotal</span>
          <span>{formatPrice(order.subtotal, currency)}</span>
        </div>
        <div className="flex justify-between text-sm text-subtext">
          <span>Delivery fee</span>
          <span>{formatPrice(order.deliveryFee, currency)}</span>
        </div>
        <div className="flex justify-between font-bold text-ink">
          <span>Total</span>
          <span className="text-wine">{formatPrice(order.total, currency)}</span>
        </div>
      </Card>

      <Card className="p-5 flex flex-col gap-2">
        <h2 className="font-display text-lg font-bold text-ink mb-1">Delivery details</h2>
        <p className="flex items-center gap-2 text-sm text-ink">
          <MapPin size={15} className="text-wine shrink-0" /> {order.streetAddress}, {order.city}
        </p>
        <p className="flex items-center gap-2 text-sm text-ink">
          <Phone size={15} className="text-wine shrink-0" /> {order.phoneNumber}
        </p>
        {order.note && <p className="text-sm text-subtext mt-1">Note: {order.note}</p>}
        <p className="text-xs text-subtext mt-2 flex items-center gap-1.5">
          <CircleDot size={12} /> Payment: {order.paymentMethod?.toUpperCase()} ({order.paymentStatus})
        </p>
      </Card>

      {order.status === "delivered" && !order.userConfirmedDelivery && (
        <Card className="p-5 flex flex-col sm:flex-row sm:items-center justify-between gap-3">
          <div>
            <p className="font-semibold text-ink">Did you receive your order?</p>
            <p className="text-sm text-subtext">Confirm so we can close out this order.</p>
          </div>
          <Button onClick={handleConfirmReceived} disabled={confirming}>
            {confirming ? <Loader2 size={15} className="animate-spin" /> : <CheckCircle2 size={15} />}
            Confirm received
          </Button>
        </Card>
      )}

      {order.status === "delivered" && order.userConfirmedDelivery && !order.storeRated && (
        <Card className="p-5">
          <h2 className="font-display text-lg font-bold text-ink mb-3">Rate this store</h2>
          <RateStoreForm onSubmit={handleRateStore} submitting={submittingRating} />
        </Card>
      )}

      {order.storeRated && (
        <p className="text-sm text-subtext text-center flex items-center justify-center gap-2">
          <CheckCircle2 size={15} className="text-success" /> You've already rated this store.
        </p>
      )}
    </div>
  );
}
