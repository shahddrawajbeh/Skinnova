import { useEffect, useState } from "react";
import { useParams, Link } from "react-router-dom";
import { Loader2, Package, MapPin, Phone, CircleDot, ArrowRight, XCircle } from "lucide-react";
import Card from "../../components/common/Card";
import Button from "../../components/common/Button";
import EmptyState from "../../components/common/EmptyState";
import ConfirmDialog from "../../components/common/ConfirmDialog";
import { resolveImageUrl } from "../../services/api";
import { useToast } from "../../context/ToastContext";
import { storeOwnerService } from "../../services/storeOwnerService";
import { formatPrice, orderStatusStyle, timeAgo } from "../../utils/format";

const STATUS_FLOW = ["pending", "confirmed", "processing", "out_for_delivery", "delivered"];

export default function OrderDetailPage() {
  const { id } = useParams();
  const toast = useToast();

  const [order, setOrder] = useState(null);
  const [loading, setLoading] = useState(true);
  const [pendingStatus, setPendingStatus] = useState(null);
  const [updating, setUpdating] = useState(false);

  const load = () => {
    storeOwnerService
      .fetchOrderDetail(id)
      .then(setOrder)
      .catch(() => setOrder(null))
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    load();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [id]);

  const handleUpdateStatus = async () => {
    if (!pendingStatus) return;
    setUpdating(true);
    try {
      const data = await storeOwnerService.updateOrderStatus(id, pendingStatus);
      setOrder(data.order || data);
      toast.success("Order status updated.");
      setPendingStatus(null);
    } catch (err) {
      toast.error(err.response?.data?.message || "Couldn't update order status.");
    } finally {
      setUpdating(false);
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
          <Button to="/store-owner/orders" variant="secondary">
            Back to orders
          </Button>
        }
      />
    );
  }

  const style = orderStatusStyle(order.status);
  const currency = order.items?.[0]?.currency || "ILS";
  const flowIndex = STATUS_FLOW.indexOf(order.status);
  const nextStatus = flowIndex >= 0 && flowIndex < STATUS_FLOW.length - 1 ? STATUS_FLOW[flowIndex + 1] : null;
  const canCancel = order.status !== "delivered" && order.status !== "cancelled";

  return (
    <div className="max-w-3xl mx-auto flex flex-col gap-8 animate-fade-slide-in">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
        <div>
          <Link to="/store-owner/orders" className="text-sm text-wine hover:underline">
            ← Back to orders
          </Link>
          <h1 className="font-display text-2xl sm:text-3xl font-bold text-ink mt-1">
            {order.userId?.fullName || "Customer"}
          </h1>
          <p className="text-xs text-subtext mt-1">Placed {timeAgo(order.createdAt)}</p>
        </div>
        <span className={`text-sm font-semibold px-4 py-1.5 rounded-full self-start ${style.bg} ${style.fg}`}>
          {style.label}
        </span>
      </div>

      {(nextStatus || canCancel) && (
        <Card className="p-5 flex flex-wrap items-center gap-3">
          <p className="font-semibold text-ink mr-auto">Update order status</p>
          {nextStatus && (
            <Button onClick={() => setPendingStatus(nextStatus)}>
              Mark as {orderStatusStyle(nextStatus).label} <ArrowRight size={15} />
            </Button>
          )}
          {canCancel && (
            <Button variant="outline" onClick={() => setPendingStatus("cancelled")}>
              <XCircle size={15} /> Cancel order
            </Button>
          )}
        </Card>
      )}

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

      <ConfirmDialog
        open={!!pendingStatus}
        onClose={() => setPendingStatus(null)}
        onConfirm={handleUpdateStatus}
        title="Update Order Status"
        message={
          pendingStatus === "cancelled"
            ? "Cancel this order? The customer will be notified."
            : `Mark this order as "${orderStatusStyle(pendingStatus).label}"? The customer will be notified.`
        }
        confirmLabel={pendingStatus === "cancelled" ? "Cancel order" : "Confirm"}
        variant={pendingStatus === "cancelled" ? "outline" : "primary"}
        loading={updating}
      />
    </div>
  );
}
