import { useEffect, useMemo, useState } from "react";
import { Link } from "react-router-dom";
import { Loader2, Package, ChevronRight } from "lucide-react";
import Card from "../../components/common/Card";
import EmptyState from "../../components/common/EmptyState";
import Tabs from "../../components/common/Tabs";
import Pagination from "../../components/common/Pagination";
import { useStoreOwner } from "../../context/StoreOwnerContext";
import { useToast } from "../../context/ToastContext";
import { storeOwnerService } from "../../services/storeOwnerService";
import { formatPrice, orderStatusStyle, timeAgo, ORDER_STATUS_STYLES } from "../../utils/format";

const PAGE_SIZE = 8;

const STATUS_TABS = [
  { value: "all", label: "All" },
  ...Object.entries(ORDER_STATUS_STYLES).map(([value, s]) => ({ value, label: s.label })),
];

export default function OrdersPage() {
  const { store } = useStoreOwner();
  const toast = useToast();
  const [orders, setOrders] = useState([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState("all");
  const [page, setPage] = useState(1);

  useEffect(() => {
    if (!store?._id) return;
    storeOwnerService
      .fetchOrders(store._id)
      .then(setOrders)
      .catch(() => toast.error("Couldn't load orders."))
      .finally(() => setLoading(false));
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [store?._id]);

  const filtered = useMemo(() => {
    if (filter === "all") return orders;
    return orders.filter((o) => o.status === filter);
  }, [orders, filter]);

  const totalPages = Math.max(1, Math.ceil(filtered.length / PAGE_SIZE));
  const pageItems = filtered.slice((page - 1) * PAGE_SIZE, page * PAGE_SIZE);

  if (loading) {
    return (
      <div className="flex items-center justify-center py-24">
        <Loader2 className="animate-spin text-wine" size={32} />
      </div>
    );
  }

  return (
    <div className="flex flex-col gap-5">
      <div className="animate-fade-slide-in">
        <h2 className="font-display text-2xl font-bold text-ink">Orders</h2>
        <p className="text-sm text-subtext mt-1">View and manage incoming orders.</p>
      </div>

      <Tabs
        tabs={STATUS_TABS}
        value={filter}
        onChange={(v) => {
          setFilter(v);
          setPage(1);
        }}
      />

      {filtered.length === 0 ? (
        <EmptyState
          icon={Package}
          title="No orders found"
          message="Orders matching this filter will show up here."
        />
      ) : (
        <>
          <div className="flex flex-col gap-3">
            {pageItems.map((order, i) => {
              const style = orderStatusStyle(order.status);
              return (
                <Link key={order._id} to={`/store-owner/orders/${order._id}`}>
                  <Card
                    className="p-4 sm:p-5 flex items-center gap-4 animate-pop-in"
                    style={{ animationDelay: `${Math.min(i, 7) * 40}ms` }}
                  >
                    <div className="flex-1 min-w-0">
                      <p className="font-semibold text-ink truncate">{order.userId?.fullName || "Customer"}</p>
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
          <Pagination page={page} totalPages={totalPages} onChange={setPage} />
        </>
      )}
    </div>
  );
}
