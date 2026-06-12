import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { Loader2, Package, ChevronRight } from "lucide-react";
import Card from "../../components/common/Card";
import EmptyState from "../../components/common/EmptyState";
import Pagination from "../../components/common/Pagination";
import { inputClass } from "../../components/common/AuthLayout";
import { adminService } from "../../services/adminService";
import { useToast } from "../../context/ToastContext";
import { formatPrice, orderStatusStyle, timeAgo, ORDER_STATUS_STYLES } from "../../utils/format";

const PAGE_SIZE = 10;

export default function OrdersPage() {
  const toast = useToast();
  const [orders, setOrders] = useState([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(true);
  const [status, setStatus] = useState("");
  const [from, setFrom] = useState("");
  const [to, setTo] = useState("");
  const [page, setPage] = useState(1);

  useEffect(() => {
    setLoading(true);
    adminService
      .fetchOrders({
        status: status || undefined,
        from: from || undefined,
        to: to || undefined,
        page,
        limit: PAGE_SIZE,
      })
      .then((data) => {
        setOrders(data.orders || []);
        setTotal(data.total || 0);
      })
      .catch(() => toast.error("Couldn't load orders."))
      .finally(() => setLoading(false));
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [status, from, to, page]);

  const totalPages = Math.max(1, Math.ceil(total / PAGE_SIZE));

  return (
    <div className="flex flex-col gap-5">
      <div className="animate-fade-slide-in">
        <h2 className="font-display text-2xl font-bold text-ink">Orders</h2>
        <p className="text-sm text-subtext mt-1">Browse and manage all orders.</p>
      </div>

      <div className="flex flex-col sm:flex-row gap-3 animate-fade-slide-in">
        <select
          value={status}
          onChange={(e) => {
            setStatus(e.target.value);
            setPage(1);
          }}
          className={`${inputClass} sm:max-w-[180px]`}
        >
          <option value="">All statuses</option>
          {Object.entries(ORDER_STATUS_STYLES).map(([value, s]) => (
            <option key={value} value={value}>
              {s.label}
            </option>
          ))}
        </select>
        <input
          type="date"
          value={from}
          onChange={(e) => {
            setFrom(e.target.value);
            setPage(1);
          }}
          className={`${inputClass} sm:max-w-[160px]`}
        />
        <input
          type="date"
          value={to}
          onChange={(e) => {
            setTo(e.target.value);
            setPage(1);
          }}
          className={`${inputClass} sm:max-w-[160px]`}
        />
      </div>

      {loading ? (
        <div className="flex items-center justify-center py-24">
          <Loader2 className="animate-spin text-wine" size={32} />
        </div>
      ) : orders.length === 0 ? (
        <EmptyState icon={Package} title="No orders found" message="Try adjusting your filters." />
      ) : (
        <>
          <div className="flex flex-col gap-3">
            {orders.map((order, i) => {
              const style = orderStatusStyle(order.status);
              return (
                <Link key={order._id} to={`/admin/orders/${order._id}`}>
                  <Card
                    className="p-4 sm:p-5 flex items-center gap-4 animate-pop-in"
                    style={{ animationDelay: `${Math.min(i, 9) * 40}ms` }}
                  >
                    <div className="flex-1 min-w-0">
                      <p className="font-semibold text-ink truncate">
                        {order.userId?.fullName || "Customer"}
                        <span className="text-subtext font-normal"> · {order.storeId?.storeName || "Store"}</span>
                      </p>
                      <p className="text-xs text-subtext mt-0.5">
                        #{order._id?.slice(-8).toUpperCase()} · {order.items?.length || 0} item{order.items?.length === 1 ? "" : "s"} · {timeAgo(order.createdAt)}
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
