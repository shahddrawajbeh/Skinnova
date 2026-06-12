import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { Loader2, Package, ChevronRight } from "lucide-react";
import Card from "../../components/common/Card";
import Button from "../../components/common/Button";
import EmptyState from "../../components/common/EmptyState";
import { resolveImageUrl } from "../../services/api";
import { useAuth } from "../../context/AuthContext";
import { useToast } from "../../context/ToastContext";
import { orderService } from "../../services/orderService";
import { formatPrice, orderStatusStyle, timeAgo } from "../../utils/format";

export default function OrdersPage() {
  const { user } = useAuth();
  const toast = useToast();
  const [orders, setOrders] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    orderService
      .fetchOrders(user.userId)
      .then((data) => setOrders(data || []))
      .catch(() => toast.error("Couldn't load your orders."))
      .finally(() => setLoading(false));
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [user.userId]);

  if (loading) {
    return (
      <div className="flex items-center justify-center py-24">
        <Loader2 className="animate-spin text-wine" size={32} />
      </div>
    );
  }

  if (orders.length === 0) {
    return (
      <EmptyState
        icon={Package}
        title="No orders yet"
        message="Your orders will show up here once you check out."
        action={
          <Button to="/shop" size="md">
            Browse the shop
          </Button>
        }
      />
    );
  }

  return (
    <div className="max-w-4xl mx-auto flex flex-col gap-6 animate-fade-slide-in">
      <h1 className="font-display text-3xl sm:text-4xl font-bold text-ink">My Orders</h1>

      <div className="flex flex-col gap-3">
        {orders.map((order, i) => {
          const style = orderStatusStyle(order.status);
          const previewItems = order.items?.slice(0, 3) || [];
          return (
            <Link key={order._id} to={`/orders/${order._id}`}>
              <Card
                className="p-4 sm:p-5 flex items-center gap-4 animate-pop-in"
                style={{ animationDelay: `${Math.min(i, 9) * 50}ms` }}
              >
                <div className="flex -space-x-3 shrink-0">
                  {previewItems.map((it, i) => (
                    <div key={i} className="h-14 w-14 rounded-xl overflow-hidden bg-soft-pink border-2 border-white">
                      {it.productId?.imageUrl ? (
                        <img src={resolveImageUrl(it.productId.imageUrl)} alt="" className="h-full w-full object-cover" />
                      ) : (
                        <div className="h-full w-full flex items-center justify-center text-wine/30 font-display">S</div>
                      )}
                    </div>
                  ))}
                </div>
                <div className="flex-1 min-w-0">
                  <p className="font-semibold text-ink truncate">{order.storeId?.storeName || "Order"}</p>
                  <p className="text-xs text-subtext mt-0.5">
                    {order.items?.length || 0} item{order.items?.length === 1 ? "" : "s"} · {timeAgo(order.createdAt)}
                  </p>
                </div>
                <div className="text-right shrink-0">
                  <p className="font-bold text-wine">{formatPrice(order.total, order.items?.[0]?.currency)}</p>
                  <span className={`inline-block mt-1 text-[11px] font-semibold px-2.5 py-1 rounded-full ${style.bg} ${style.fg}`}>
                    {style.label}
                  </span>
                </div>
                <ChevronRight size={18} className="text-subtext shrink-0" />
              </Card>
            </Link>
          );
        })}
      </div>
    </div>
  );
}
