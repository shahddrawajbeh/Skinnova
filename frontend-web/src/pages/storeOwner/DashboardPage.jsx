import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import {
  Package,
  ShoppingBag,
  Clock,
  Wallet,
  Star,
  Users,
  AlertTriangle,
  PackageX,
  ChevronRight,
  Loader2,
} from "lucide-react";
import Card from "../../components/common/Card";
import { Skeleton } from "../../components/common/Skeleton";
import { useStoreOwner } from "../../context/StoreOwnerContext";
import { storeOwnerService } from "../../services/storeOwnerService";
import { formatPrice, orderStatusStyle, timeAgo } from "../../utils/format";
import StatCard from "../../components/storeOwner/StatCard";
import LineChart from "../../components/storeOwner/charts/LineChart";
import DonutChart from "../../components/storeOwner/charts/DonutChart";
import BarChart from "../../components/storeOwner/charts/BarChart";

const STATUS_COLORS = {
  pending: "#f59e0b",
  confirmed: "#3b82f6",
  processing: "#8b5cf6",
  out_for_delivery: "#06b6d4",
  delivered: "var(--color-success)",
  cancelled: "var(--color-danger)",
};

const RANGE_OPTIONS = [7, 30, 90];

export default function DashboardPage() {
  const { store } = useStoreOwner();
  const [analytics, setAnalytics] = useState(null);
  const [timeseries, setTimeseries] = useState([]);
  const [days, setDays] = useState(30);
  const [loading, setLoading] = useState(true);
  const [chartLoading, setChartLoading] = useState(true);

  useEffect(() => {
    if (!store?._id) return;
    storeOwnerService
      .fetchAnalytics(store._id)
      .then(setAnalytics)
      .finally(() => setLoading(false));
  }, [store?._id]);

  useEffect(() => {
    if (!store?._id) return;
    setChartLoading(true);
    storeOwnerService
      .fetchTimeseries(store._id, days)
      .then(setTimeseries)
      .finally(() => setChartLoading(false));
  }, [store?._id, days]);

  if (loading || !analytics) {
    return (
      <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-6 gap-4">
        {Array.from({ length: 6 }).map((_, i) => (
          <Skeleton key={i} className="h-24" />
        ))}
      </div>
    );
  }

  const statusData = Object.entries(analytics.statusBreakdown || {}).map(([key, value]) => ({
    label: orderStatusStyle(key).label,
    value,
    color: STATUS_COLORS[key] || "var(--color-wine)",
  }));

  return (
    <div className="flex flex-col gap-6">
      <div className="animate-fade-slide-in">
        <h2 className="font-display text-2xl font-bold text-ink">
          Welcome back, {store?.storeName}
        </h2>
        <p className="text-sm text-subtext mt-1">Here's how your store is performing.</p>
      </div>

      {(analytics.lowStockCount > 0 ||
        analytics.outOfStockCount > 0 ||
        analytics.pendingOrders > 0) && (
        <div className="flex flex-col sm:flex-row gap-3 animate-fade-slide-in">
          {analytics.pendingOrders > 0 && (
            <Link
              to="/store-owner/orders"
              className="flex-1 flex items-center gap-3 rounded-2xl border border-amber-200 bg-amber-50 px-4 py-3 text-amber-700 hover:-translate-y-0.5 transition-transform"
            >
              <Clock size={18} />
              <span className="text-sm font-medium">
                {analytics.pendingOrders} order{analytics.pendingOrders === 1 ? "" : "s"} awaiting confirmation
              </span>
            </Link>
          )}
          {analytics.lowStockCount > 0 && (
            <Link
              to="/store-owner/products"
              className="flex-1 flex items-center gap-3 rounded-2xl border border-orange-200 bg-orange-50 px-4 py-3 text-orange-700 hover:-translate-y-0.5 transition-transform"
            >
              <AlertTriangle size={18} />
              <span className="text-sm font-medium">
                {analytics.lowStockCount} product{analytics.lowStockCount === 1 ? "" : "s"} low on stock
              </span>
            </Link>
          )}
          {analytics.outOfStockCount > 0 && (
            <Link
              to="/store-owner/products"
              className="flex-1 flex items-center gap-3 rounded-2xl border border-red-200 bg-red-50 px-4 py-3 text-red-700 hover:-translate-y-0.5 transition-transform"
            >
              <PackageX size={18} />
              <span className="text-sm font-medium">
                {analytics.outOfStockCount} product{analytics.outOfStockCount === 1 ? "" : "s"} out of stock
              </span>
            </Link>
          )}
        </div>
      )}

      <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-6 gap-4">
        <StatCard icon={Package} label="Products" value={analytics.productsCount} delay={0} />
        <StatCard icon={ShoppingBag} label="Total Orders" value={analytics.totalOrders} delay={50} />
        <StatCard icon={Clock} label="Pending Orders" value={analytics.pendingOrders} delay={100} />
        <StatCard
          icon={Wallet}
          label="Revenue (Month)"
          value={formatPrice(analytics.revenueThisMonth, "ILS")}
          delay={150}
        />
        <StatCard icon={Star} label="Rating" value={analytics.ratingAverage?.toFixed(1) || "0.0"} delay={200} />
        <StatCard icon={Users} label="Followers" value={analytics.followersCount} delay={250} />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
        <Card className="p-5 lg:col-span-2 animate-fade-slide-in" hover={false}>
          <div className="flex items-center justify-between mb-4">
            <h3 className="font-semibold text-ink">Revenue Over Time</h3>
            <div className="flex gap-1">
              {RANGE_OPTIONS.map((opt) => (
                <button
                  key={opt}
                  onClick={() => setDays(opt)}
                  className={`px-3 py-1 rounded-full text-xs font-medium transition-all ${
                    days === opt ? "bg-wine text-white" : "bg-soft-pink text-wine hover:bg-dusty-rose-light"
                  }`}
                >
                  {opt}d
                </button>
              ))}
            </div>
          </div>
          {chartLoading ? (
            <div className="flex items-center justify-center h-[220px]">
              <Loader2 className="animate-spin text-wine" size={28} />
            </div>
          ) : (
            <LineChart data={timeseries} valueKey="revenue" labelKey="date" />
          )}
        </Card>

        <Card className="p-5 animate-fade-slide-in" hover={false}>
          <h3 className="font-semibold text-ink mb-4">Orders by Status</h3>
          <DonutChart data={statusData} centerLabel="Total Orders" centerValue={analytics.totalOrders} />
        </Card>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        <Card className="p-5 animate-fade-slide-in" hover={false}>
          <h3 className="font-semibold text-ink mb-4">Top Products</h3>
          {analytics.topProducts?.length ? (
            <BarChart
              data={analytics.topProducts}
              valueKey="soldCount"
              labelKey="name"
              color="var(--color-dusty-rose)"
            />
          ) : (
            <p className="text-sm text-subtext">No sales yet.</p>
          )}
        </Card>

        <Card className="p-5 animate-fade-slide-in" hover={false}>
          <div className="flex items-center justify-between mb-4">
            <h3 className="font-semibold text-ink">Recent Orders</h3>
            <Link to="/store-owner/orders" className="text-sm font-semibold text-wine hover:underline">
              View all
            </Link>
          </div>
          {analytics.recentOrders?.length ? (
            <div className="flex flex-col gap-2">
              {analytics.recentOrders.map((order) => {
                const style = orderStatusStyle(order.status);
                return (
                  <Link
                    key={order._id}
                    to={`/store-owner/orders/${order._id}`}
                    className="flex items-center justify-between gap-3 rounded-xl px-3 py-2.5 hover:bg-soft-pink transition-colors"
                  >
                    <div className="min-w-0">
                      <p className="text-sm font-medium text-ink truncate">{order.customerName}</p>
                      <p className="text-xs text-subtext">
                        {order.itemsCount} item{order.itemsCount === 1 ? "" : "s"} · {timeAgo(order.createdAt)}
                      </p>
                    </div>
                    <div className="text-right shrink-0 flex items-center gap-2">
                      <div>
                        <p className="text-sm font-bold text-wine">{formatPrice(order.total, "ILS")}</p>
                        <span className={`inline-block text-[10px] font-semibold px-2 py-0.5 rounded-full ${style.bg} ${style.fg}`}>
                          {style.label}
                        </span>
                      </div>
                      <ChevronRight size={16} className="text-subtext" />
                    </div>
                  </Link>
                );
              })}
            </div>
          ) : (
            <p className="text-sm text-subtext">No orders yet.</p>
          )}
        </Card>
      </div>
    </div>
  );
}
