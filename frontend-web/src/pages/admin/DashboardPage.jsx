import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import {
  Users,
  Store,
  ShoppingBag,
  Package,
  Wallet,
  Inbox,
  ChevronRight,
  Bell,
  FileText,
} from "lucide-react";
import Card from "../../components/common/Card";
import Button from "../../components/common/Button";
import { Skeleton } from "../../components/common/Skeleton";
import StatCard from "../../components/storeOwner/StatCard";
import { adminService } from "../../services/adminService";
import { formatPrice, orderStatusStyle, timeAgo } from "../../utils/format";

export default function DashboardPage() {
  const [stats, setStats] = useState(null);
  const [reportsStats, setReportsStats] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    Promise.all([adminService.fetchStats(), adminService.fetchReportsStats()])
      .then(([s, r]) => {
        setStats(s);
        setReportsStats(r);
      })
      .finally(() => setLoading(false));
  }, []);

  if (loading || !stats) {
    return (
      <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-6 gap-4">
        {Array.from({ length: 6 }).map((_, i) => (
          <Skeleton key={i} className="h-24" />
        ))}
      </div>
    );
  }

  const { counts, latestUsers = [], latestStores = [], recentOrders = [] } = stats;

  return (
    <div className="flex flex-col gap-6">
      <div className="animate-fade-slide-in">
        <h2 className="font-display text-2xl font-bold text-ink">Admin Dashboard</h2>
        <p className="text-sm text-subtext mt-1">Overview of platform activity.</p>
      </div>

      <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-6 gap-4">
        <StatCard icon={Users} label="Users" value={counts?.users ?? 0} delay={0} />
        <StatCard icon={Store} label="Stores" value={counts?.stores ?? 0} delay={50} />
        <StatCard icon={ShoppingBag} label="Orders" value={counts?.orders ?? 0} delay={100} />
        <StatCard icon={Package} label="Products" value={counts?.products ?? 0} delay={150} />
        <StatCard
          icon={Wallet}
          label="Total Revenue"
          value={formatPrice(reportsStats?.totalRevenue, "ILS")}
          delay={200}
        />
        <Link to="/admin/store-requests">
          <StatCard
            icon={Inbox}
            label="Pending Store Requests"
            value={counts?.pendingStores ?? 0}
            accent="gold"
            delay={250}
          />
        </Link>
      </div>

      <div className="flex flex-wrap gap-3 animate-fade-slide-in">
        <Button to="/admin/store-requests" variant="secondary" size="sm">
          <Inbox size={16} /> Store Requests
        </Button>
        <Button to="/admin/notifications" variant="secondary" size="sm">
          <Bell size={16} /> Notifications
        </Button>
        <Button to="/admin/reports" variant="secondary" size="sm">
          <FileText size={16} /> Reports
        </Button>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
        <Card className="p-5 animate-fade-slide-in" hover={false}>
          <div className="flex items-center justify-between mb-4">
            <h3 className="font-semibold text-ink">Recent Users</h3>
            <Link to="/admin/users" className="text-sm font-semibold text-wine hover:underline">
              View all
            </Link>
          </div>
          {latestUsers.length ? (
            <div className="flex flex-col gap-2">
              {latestUsers.map((u) => (
                <div key={u._id} className="flex items-center justify-between gap-3 px-1 py-1.5">
                  <div className="min-w-0">
                    <p className="text-sm font-medium text-ink truncate">{u.fullName}</p>
                    <p className="text-xs text-subtext truncate">{u.email}</p>
                  </div>
                  <span className="text-xs text-subtext shrink-0">{timeAgo(u.createdAt)}</span>
                </div>
              ))}
            </div>
          ) : (
            <p className="text-sm text-subtext">No users yet.</p>
          )}
        </Card>

        <Card className="p-5 animate-fade-slide-in" hover={false}>
          <div className="flex items-center justify-between mb-4">
            <h3 className="font-semibold text-ink">Recent Stores</h3>
            <Link to="/admin/stores" className="text-sm font-semibold text-wine hover:underline">
              View all
            </Link>
          </div>
          {latestStores.length ? (
            <div className="flex flex-col gap-2">
              {latestStores.map((s) => (
                <div key={s._id} className="flex items-center justify-between gap-3 px-1 py-1.5">
                  <div className="min-w-0">
                    <p className="text-sm font-medium text-ink truncate">{s.storeName}</p>
                    <p className="text-xs text-subtext truncate">{s.sellerId?.fullName}</p>
                  </div>
                  <span className="text-xs text-subtext shrink-0">{timeAgo(s.createdAt)}</span>
                </div>
              ))}
            </div>
          ) : (
            <p className="text-sm text-subtext">No stores yet.</p>
          )}
        </Card>

        <Card className="p-5 animate-fade-slide-in" hover={false}>
          <div className="flex items-center justify-between mb-4">
            <h3 className="font-semibold text-ink">Recent Orders</h3>
            <Link to="/admin/orders" className="text-sm font-semibold text-wine hover:underline">
              View all
            </Link>
          </div>
          {recentOrders.length ? (
            <div className="flex flex-col gap-2">
              {recentOrders.map((order) => {
                const style = orderStatusStyle(order.status);
                return (
                  <Link
                    key={order._id}
                    to={`/admin/orders/${order._id}`}
                    className="flex items-center justify-between gap-3 rounded-xl px-1 py-1.5 hover:bg-soft-pink transition-colors"
                  >
                    <div className="min-w-0">
                      <p className="text-sm font-medium text-ink truncate">
                        {order.userId?.fullName || "Unknown"}
                      </p>
                      <p className="text-xs text-subtext truncate">{order.storeId?.storeName}</p>
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
