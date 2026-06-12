import { useEffect, useState } from "react";
import { Download, Printer, Loader2 } from "lucide-react";
import Card from "../../components/common/Card";
import Button from "../../components/common/Button";
import { resolveImageUrl } from "../../services/api";
import { useStoreOwner } from "../../context/StoreOwnerContext";
import { storeOwnerService } from "../../services/storeOwnerService";
import { exportToCsv } from "../../utils/exportCsv";
import { formatPrice } from "../../utils/format";
import LineChart from "../../components/storeOwner/charts/LineChart";
import BarChart from "../../components/storeOwner/charts/BarChart";

const RANGE_OPTIONS = [7, 30, 90];

export default function AnalyticsPage() {
  const { store } = useStoreOwner();
  const [days, setDays] = useState(30);
  const [timeseries, setTimeseries] = useState([]);
  const [analytics, setAnalytics] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!store?._id) return;
    setLoading(true);
    Promise.all([
      storeOwnerService.fetchTimeseries(store._id, days),
      storeOwnerService.fetchAnalytics(store._id),
    ])
      .then(([ts, an]) => {
        setTimeseries(ts);
        setAnalytics(an);
      })
      .finally(() => setLoading(false));
  }, [store?._id, days]);

  const totalRevenue = timeseries.reduce((sum, d) => sum + (d.revenue || 0), 0);
  const totalOrders = timeseries.reduce((sum, d) => sum + (d.orders || 0), 0);

  const handleExportCsv = () => {
    exportToCsv(
      `analytics-${store?.storeName || "store"}-${days}d`,
      timeseries.map((d) => ({ date: d.date, revenue: d.revenue, orders: d.orders }))
    );
  };

  return (
    <div className="flex flex-col gap-6">
      <div className="flex flex-wrap items-center justify-between gap-3 animate-fade-slide-in">
        <div>
          <h2 className="font-display text-2xl font-bold text-ink">Analytics</h2>
          <p className="text-sm text-subtext mt-1">Track revenue and order trends over time.</p>
        </div>
        <div className="flex items-center gap-2 print:hidden">
          <div className="flex gap-1">
            {RANGE_OPTIONS.map((opt) => (
              <button
                key={opt}
                onClick={() => setDays(opt)}
                className={`px-3 py-1.5 rounded-full text-xs font-medium transition-all ${
                  days === opt ? "bg-wine text-white" : "bg-soft-pink text-wine hover:bg-dusty-rose-light"
                }`}
              >
                Last {opt} days
              </button>
            ))}
          </div>
          <Button variant="secondary" size="sm" onClick={handleExportCsv}>
            <Download size={16} /> CSV
          </Button>
          <Button variant="outline" size="sm" onClick={() => window.print()}>
            <Printer size={16} /> PDF
          </Button>
        </div>
      </div>

      {loading ? (
        <div className="flex items-center justify-center py-24">
          <Loader2 className="animate-spin text-wine" size={32} />
        </div>
      ) : (
        <>
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
            <Card className="p-5 animate-pop-in" hover={false}>
              <p className="text-xs text-subtext">Revenue (last {days} days)</p>
              <p className="text-2xl font-bold text-wine mt-1">{formatPrice(totalRevenue, "ILS")}</p>
            </Card>
            <Card className="p-5 animate-pop-in" hover={false} style={{ animationDelay: "50ms" }}>
              <p className="text-xs text-subtext">Orders (last {days} days)</p>
              <p className="text-2xl font-bold text-ink mt-1">{totalOrders}</p>
            </Card>
            <Card className="p-5 animate-pop-in" hover={false} style={{ animationDelay: "100ms" }}>
              <p className="text-xs text-subtext">Lifetime Revenue</p>
              <p className="text-2xl font-bold text-ink mt-1">
                {formatPrice(analytics?.totalRevenue || 0, "ILS")}
              </p>
            </Card>
          </div>

          <Card className="p-5 animate-fade-slide-in" hover={false}>
            <h3 className="font-semibold text-ink mb-4">Revenue</h3>
            <LineChart data={timeseries} valueKey="revenue" labelKey="date" />
          </Card>

          <Card className="p-5 animate-fade-slide-in" hover={false}>
            <h3 className="font-semibold text-ink mb-4">Orders</h3>
            <BarChart
              data={timeseries.filter((_, i) => i % Math.max(1, Math.ceil(timeseries.length / 15)) === 0)}
              valueKey="orders"
              labelKey="date"
              color="var(--color-dusty-rose)"
              formatValue={(v) => v}
            />
          </Card>

          <Card className="p-5 animate-fade-slide-in" hover={false}>
            <h3 className="font-semibold text-ink mb-4">Top Products</h3>
            {analytics?.topProducts?.length ? (
              <div className="overflow-x-auto">
                <table className="w-full text-sm">
                  <thead>
                    <tr className="text-left text-subtext border-b border-divider">
                      <th className="py-2 pr-4 font-medium">Product</th>
                      <th className="py-2 pr-4 font-medium">Brand</th>
                      <th className="py-2 pr-4 font-medium">Units Sold</th>
                      <th className="py-2 pr-4 font-medium">Price</th>
                    </tr>
                  </thead>
                  <tbody>
                    {analytics.topProducts.map((p, i) => (
                      <tr key={i} className="border-b border-divider last:border-0">
                        <td className="py-2.5 pr-4 flex items-center gap-2">
                          {p.imageUrl && (
                            <img
                              src={resolveImageUrl(p.imageUrl)}
                              alt=""
                              className="h-8 w-8 rounded-lg object-cover"
                            />
                          )}
                          <span className="font-medium text-ink">{p.name}</span>
                        </td>
                        <td className="py-2.5 pr-4 text-subtext">{p.brand}</td>
                        <td className="py-2.5 pr-4 text-ink">{p.soldCount}</td>
                        <td className="py-2.5 pr-4 text-wine font-semibold">
                          {formatPrice(p.price, p.currency)}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            ) : (
              <p className="text-sm text-subtext">No sales yet.</p>
            )}
          </Card>
        </>
      )}
    </div>
  );
}
