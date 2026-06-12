import { useEffect, useState } from "react";
import { Download, Printer, Loader2 } from "lucide-react";
import Card from "../../components/common/Card";
import Button from "../../components/common/Button";
import { adminService } from "../../services/adminService";
import { exportToCsv } from "../../utils/exportCsv";
import LineChart from "../../components/storeOwner/charts/LineChart";
import BarChart from "../../components/storeOwner/charts/BarChart";

export default function AnalyticsPage() {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    adminService
      .fetchAnalyticsCharts()
      .then(setData)
      .finally(() => setLoading(false));
  }, []);

  const handleExportCsv = () => {
    if (!data) return;
    const rows = data.monthlyRevenue.map((m, i) => ({
      month: m.month,
      revenue: m.value,
      orders: data.monthlyOrders[i]?.value || 0,
      newUsers: data.monthlyUsers[i]?.value || 0,
    }));
    exportToCsv(`analytics-${new Date().getFullYear()}`, rows);
  };

  return (
    <div className="flex flex-col gap-6">
      <div className="flex flex-wrap items-center justify-between gap-3 animate-fade-slide-in">
        <div>
          <h2 className="font-display text-2xl font-bold text-ink">Analytics</h2>
          <p className="text-sm text-subtext mt-1">Platform trends for {new Date().getFullYear()}.</p>
        </div>
        <div className="flex items-center gap-2 print:hidden">
          <Button variant="secondary" size="sm" onClick={handleExportCsv} disabled={!data}>
            <Download size={16} /> CSV
          </Button>
          <Button variant="outline" size="sm" onClick={() => window.print()}>
            <Printer size={16} /> PDF
          </Button>
        </div>
      </div>

      {loading || !data ? (
        <div className="flex items-center justify-center py-24">
          <Loader2 className="animate-spin text-wine" size={32} />
        </div>
      ) : (
        <>
          <Card className="p-5 animate-fade-slide-in" hover={false}>
            <h3 className="font-semibold text-ink mb-4">Monthly Revenue (delivered orders)</h3>
            <LineChart data={data.monthlyRevenue} valueKey="value" labelKey="month" />
          </Card>

          <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
            <Card className="p-5 animate-fade-slide-in" hover={false}>
              <h3 className="font-semibold text-ink mb-4">Monthly Orders</h3>
              <BarChart data={data.monthlyOrders} valueKey="value" labelKey="month" color="var(--color-dusty-rose)" />
            </Card>
            <Card className="p-5 animate-fade-slide-in" hover={false}>
              <h3 className="font-semibold text-ink mb-4">New Users</h3>
              <BarChart data={data.monthlyUsers} valueKey="value" labelKey="month" color="var(--color-gold)" />
            </Card>
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
            <Card className="p-5 animate-fade-slide-in" hover={false}>
              <h3 className="font-semibold text-ink mb-4">Best-Selling Products</h3>
              <BarChart
                data={data.bestSellingProducts.map((p) => ({ ...p, name: p.name?.slice(0, 12) }))}
                valueKey="value"
                labelKey="name"
                color="var(--color-wine)"
              />
            </Card>
            <Card className="p-5 animate-fade-slide-in" hover={false}>
              <h3 className="font-semibold text-ink mb-4">Top Stores by Revenue</h3>
              <BarChart
                data={data.storeSales.map((s) => ({ ...s, name: s.name?.slice(0, 12) }))}
                valueKey="value"
                labelKey="name"
                color="var(--color-dusty-rose)"
                formatValue={(v) => v.toFixed(0)}
              />
            </Card>
          </div>
        </>
      )}
    </div>
  );
}
