import { useEffect, useState } from "react";
import { useParams, Link } from "react-router-dom";
import { Loader2, Package, MapPin, Phone, CircleDot, Store } from "lucide-react";
import Card from "../../components/common/Card";
import Button from "../../components/common/Button";
import EmptyState from "../../components/common/EmptyState";
import ConfirmDialog from "../../components/common/ConfirmDialog";
import { inputClass } from "../../components/common/AuthLayout";
import { resolveImageUrl } from "../../services/api";
import { useToast } from "../../context/ToastContext";
import { adminService } from "../../services/adminService";
import { formatPrice, orderStatusStyle, timeAgo, ORDER_STATUS_STYLES } from "../../utils/format";

export default function OrderDetailPage() {
  const { id } = useParams();
  const toast = useToast();

  const [order, setOrder] = useState(null);
  const [loading, setLoading] = useState(true);
  const [statusValue, setStatusValue] = useState("");
  const [pendingStatus, setPendingStatus] = useState(null);
  const [updating, setUpdating] = useState(false);

  const load = () => {
    adminService
      .fetchOrder(id)
      .then((data) => {
        setOrder(data);
        setStatusValue(data.status);
      })
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
      const data = await adminService.updateOrderStatus(id, pendingStatus);
      setOrder(data);
      setStatusValue(data.status);
      toast.success("Order status updated.");
      setPendingStatus(null);
    } catch {
      toast.error("Couldn't update order status.");
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
          <Button to="/admin/orders" variant="secondary">
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
          <Link to="/admin/orders" className="text-sm text-wine hover:underline">
            ← Back to orders
          </Link>
          <h1 className="font-display text-2xl sm:text-3xl font-bold text-ink mt-1">
            Order #{order._id?.slice(-8).toUpperCase()}
          </h1>
          <p className="text-xs text-subtext mt-1">Placed {timeAgo(order.createdAt)}</p>
        </div>
        <span className={`text-sm font-semibold px-4 py-1.5 rounded-full self-start ${style.bg} ${style.fg}`}>
          {style.label}
        </span>
      </div>

      <Card className="p-5 flex flex-wrap items-end gap-3">
        <div className="flex-1 min-w-[160px]">
          <label className="block text-xs text-subtext mb-1">Order status</label>
          <select value={statusValue} onChange={(e) => setStatusValue(e.target.value)} className={inputClass}>
            {Object.entries(ORDER_STATUS_STYLES).map(([value, s]) => (
              <option key={value} value={value}>
                {s.label}
              </option>
            ))}
          </select>
        </div>
        <Button onClick={() => setPendingStatus(statusValue)} disabled={statusValue === order.status}>
          Update Status
        </Button>
      </Card>

      <Card className="p-5 flex items-center gap-3">
        {order.storeId?.logoUrl ? (
          <img src={resolveImageUrl(order.storeId.logoUrl)} alt="" className="h-12 w-12 rounded-xl object-cover" />
        ) : (
          <div className="h-12 w-12 rounded-xl bg-soft-pink flex items-center justify-center text-wine font-bold shrink-0">
            <Store size={20} />
          </div>
        )}
        <div className="min-w-0 flex-1">
          <p className="font-semibold text-ink truncate">{order.storeId?.storeName || "Store"}</p>
          {order.storeId?.phone && (
            <p className="text-xs text-subtext flex items-center gap-1">
              <Phone size={12} /> {order.storeId.phone}
            </p>
          )}
        </div>
        <div className="text-right shrink-0">
          <p className="text-xs text-subtext">Customer</p>
          <p className="text-sm font-semibold text-ink">{order.userId?.fullName || "Unknown"}</p>
          <p className="text-xs text-subtext">{order.userId?.email}</p>
        </div>
      </Card>

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
        message={`Set this order's status to "${orderStatusStyle(pendingStatus).label}"? The customer will be notified.`}
        confirmLabel="Update"
        loading={updating}
      />
    </div>
  );
}
