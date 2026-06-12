import { useEffect, useState } from "react";
import { useSearchParams } from "react-router-dom";
import { Download, Printer, Search } from "lucide-react";
import Card from "../../components/common/Card";
import Button from "../../components/common/Button";
import Tabs from "../../components/common/Tabs";
import Pagination from "../../components/common/Pagination";
import AdminReportTable from "../../components/admin/AdminReportTable";
import BarChart from "../../components/storeOwner/charts/BarChart";
import DonutChart from "../../components/storeOwner/charts/DonutChart";
import { inputClass } from "../../components/common/AuthLayout";
import { adminService } from "../../services/adminService";
import { useToast } from "../../context/ToastContext";
import { downloadBlob } from "../../utils/exportCsv";
import { formatPrice, orderStatusStyle, ORDER_STATUS_STYLES } from "../../utils/format";

const PAGE_SIZE = 10;

const TABS = [
  { value: "users", label: "Users" },
  { value: "stores", label: "Stores" },
  { value: "orders", label: "Orders" },
  { value: "products", label: "Products" },
  { value: "ai", label: "AI Scans" },
  { value: "login-activity", label: "Login Activity" },
  { value: "notifications", label: "Notifications" },
  { value: "reviews", label: "Reviews" },
  { value: "revenue", label: "Revenue" },
];

const USER_STATUS_OPTIONS = [
  { value: "", label: "All users" },
  { value: "active", label: "Active" },
  { value: "inactive", label: "Inactive" },
  { value: "new", label: "New (30 days)" },
];

const USER_SORT_OPTIONS = [
  { value: "newest", label: "Newest" },
  { value: "oldest", label: "Oldest" },
  { value: "mostOrders", label: "Most Orders" },
  { value: "mostPurchases", label: "Most Purchases" },
  { value: "mostScans", label: "Most AI Scans" },
];

const STORE_FILTER_OPTIONS = [
  { value: "all", label: "All" },
  { value: "topRevenue", label: "Top Revenue" },
  { value: "mostOrders", label: "Most Orders" },
  { value: "highestRating", label: "Highest Rating" },
  { value: "newest", label: "Newest" },
];

const PRODUCT_FILTER_OPTIONS = [
  { value: "all", label: "All" },
  { value: "bestSelling", label: "Best Selling" },
  { value: "leastSelling", label: "Least Selling" },
  { value: "highestRated", label: "Highest Rated" },
  { value: "lowestRated", label: "Lowest Rated" },
  { value: "outOfStock", label: "Out of Stock" },
];

const REPORT_CONFIGS = {
  users: {
    rowsKey: "users",
    paginated: true,
    csvName: "user_report.csv",
    columns: [
      { key: "fullName", label: "Name" },
      { key: "email", label: "Email" },
      { key: "phone", label: "Phone", render: (r) => r.phone || "—" },
      { key: "createdAt", label: "Joined", render: (r) => (r.createdAt ? new Date(r.createdAt).toLocaleDateString() : "—") },
      { key: "ordersCount", label: "Orders" },
      { key: "aiScanCount", label: "AI Scans" },
      { key: "totalSpent", label: "Total Spent", render: (r) => formatPrice(r.totalSpent, "ILS") },
      { key: "statusLabel", label: "Status" },
    ],
  },
  stores: {
    rowsKey: "stores",
    paginated: true,
    csvName: "store_report.csv",
    columns: [
      { key: "storeName", label: "Store" },
      { key: "owner", label: "Owner", render: (r) => r.owner || "—" },
      { key: "createdAt", label: "Joined", render: (r) => (r.createdAt ? new Date(r.createdAt).toLocaleDateString() : "—") },
      { key: "revenue", label: "Revenue", render: (r) => formatPrice(r.revenue, "ILS") },
      { key: "ordersCount", label: "Orders" },
      { key: "productsCount", label: "Products" },
      { key: "rating", label: "Rating", render: (r) => r.rating?.toFixed?.(1) || "0.0" },
      { key: "isApproved", label: "Approved", render: (r) => (r.approvalStatus === "approved" ? "Yes" : "No") },
    ],
  },
  orders: {
    rowsKey: "orders",
    paginated: true,
    csvName: "order_report.csv",
    columns: [
      { key: "orderId", label: "Order ID", render: (r) => r._id?.slice(-8).toUpperCase() },
      { key: "customer", label: "Customer", render: (r) => r.userId?.fullName || r.fullName || "—" },
      { key: "store", label: "Store", render: (r) => r.storeId?.storeName || "—" },
      { key: "itemsCount", label: "Items", render: (r) => r.items?.length || 0 },
      { key: "total", label: "Total", render: (r) => formatPrice(r.total, "ILS") },
      { key: "status", label: "Status", render: (r) => orderStatusStyle(r.status).label },
      { key: "paymentMethod", label: "Payment", render: (r) => r.paymentMethod?.toUpperCase() || "—" },
      { key: "createdAt", label: "Date", render: (r) => (r.createdAt ? new Date(r.createdAt).toLocaleDateString() : "—") },
    ],
  },
  products: {
    rowsKey: "products",
    paginated: true,
    csvName: "product_report.csv",
    columns: [
      { key: "name", label: "Product" },
      { key: "brand", label: "Brand" },
      { key: "storeCount", label: "Stores" },
      { key: "totalSold", label: "Units Sold" },
      { key: "totalStock", label: "Stock" },
      { key: "rating", label: "Rating", render: (r) => r.rating?.toFixed?.(1) || "0.0" },
      { key: "revenue", label: "Revenue", render: (r) => formatPrice(r.revenue, "ILS") },
    ],
  },
  ai: {
    rowsKey: "concerns",
    paginated: false,
    csvName: "ai_report.csv",
    columns: [
      { key: "concern", label: "Concern" },
      { key: "occurrences", label: "Occurrences" },
      { key: "avgSeverity", label: "Avg Severity" },
      { key: "percentage", label: "% of Scans", render: (r) => `${r.percentage}%` },
    ],
  },
  "login-activity": {
    rowsKey: "records",
    paginated: true,
    csvName: "login_activity_report.csv",
    columns: [
      { key: "user", label: "User", render: (r) => r.userId?.fullName || "—" },
      { key: "email", label: "Email", render: (r) => r.userId?.email || "—" },
      { key: "loginTime", label: "Login", render: (r) => (r.loginTime ? new Date(r.loginTime).toLocaleString() : "—") },
      { key: "logoutTime", label: "Logout", render: (r) => (r.logoutTime ? new Date(r.logoutTime).toLocaleString() : "Active") },
      { key: "duration", label: "Duration (min)", render: (r) => (r.sessionDuration ? Math.round(r.sessionDuration / 60) : "—") },
      { key: "device", label: "Device", render: (r) => r.device || "—" },
      { key: "platform", label: "Platform", render: (r) => r.platform || "—" },
      { key: "ipAddress", label: "IP Address", render: (r) => r.ipAddress || "—" },
    ],
  },
  notifications: {
    rowsKey: "notifications",
    paginated: false,
    csvName: "notification_report.csv",
    columns: [
      { key: "notification", label: "Notification" },
      { key: "type", label: "Type", render: (r) => r.type || "—" },
      { key: "recipients", label: "Recipients" },
      { key: "opened", label: "Opened" },
      { key: "openRate", label: "Open Rate" },
      { key: "createdAt", label: "Sent" },
    ],
  },
  reviews: {
    rowsKey: "stores",
    paginated: false,
    csvName: "review_report.csv",
    columns: [
      { key: "storeName", label: "Store" },
      { key: "reviewCount", label: "Reviews" },
      { key: "avgRating", label: "Avg Rating", render: (r) => r.avgRating?.toFixed?.(1) || "0.0" },
      { key: "positivePct", label: "Positive %" },
      { key: "negativePct", label: "Negative %" },
    ],
  },
  revenue: {
    rowsKey: "stores",
    paginated: false,
    csvName: "revenue_report.csv",
    columns: [
      { key: "storeName", label: "Store", render: (r) => r.storeName || "Unknown" },
      { key: "orders", label: "Orders" },
      { key: "revenue", label: "Revenue", render: (r) => formatPrice(r.revenue, "ILS") },
      { key: "cancelled", label: "Cancelled" },
      { key: "netRevenue", label: "Net Revenue", render: (r) => formatPrice(r.netRevenue, "ILS") },
    ],
  },
};

export default function ReportsPage() {
  const toast = useToast();
  const [searchParams, setSearchParams] = useSearchParams();
  const initialTab = searchParams.get("tab");
  const [tab, setTab] = useState(REPORT_CONFIGS[initialTab] ? initialTab : "users");
  const [from, setFrom] = useState("");
  const [to, setTo] = useState("");
  const [search, setSearch] = useState("");
  const [status, setStatus] = useState("");
  const [sort, setSort] = useState("newest");
  const [filter, setFilter] = useState("all");
  const [device, setDevice] = useState("");
  const [page, setPage] = useState(1);
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [exporting, setExporting] = useState(false);

  const config = REPORT_CONFIGS[tab];

  const buildParams = () => {
    const params = {};
    if (from) params.from = from;
    if (to) params.to = to;
    if (config.paginated) {
      params.page = page;
      params.limit = PAGE_SIZE;
    }
    switch (tab) {
      case "users":
        if (status) params.status = status;
        if (sort) params.sort = sort;
        if (search) params.search = search;
        break;
      case "stores":
        if (filter) params.filter = filter;
        if (search) params.search = search;
        break;
      case "orders":
        if (status) params.status = status;
        if (search) params.search = search;
        break;
      case "products":
        if (filter) params.filter = filter;
        if (search) params.search = search;
        break;
      case "login-activity":
        if (device) params.device = device;
        break;
      case "reviews":
        if (search) params.search = search;
        break;
      default:
        break;
    }
    return params;
  };

  useEffect(() => {
    setLoading(true);
    const t = setTimeout(() => {
      adminService
        .fetchReport(tab, buildParams())
        .then(setData)
        .catch(() => toast.error("Couldn't load report."))
        .finally(() => setLoading(false));
    }, 300);
    return () => clearTimeout(t);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [tab, from, to, status, sort, filter, device, search, page]);

  const handleTabChange = (value) => {
    setTab(value);
    setPage(1);
    setSearchParams({ tab: value });
  };

  const handleExportCsv = async () => {
    setExporting(true);
    try {
      const params = buildParams();
      delete params.page;
      delete params.limit;
      const blob = await adminService.exportReportCsv(tab, params);
      downloadBlob(config.csvName, blob);
    } catch {
      toast.error("Couldn't export CSV.");
    } finally {
      setExporting(false);
    }
  };

  const rows = data?.[config.rowsKey] || [];
  const total = data?.total || 0;
  const totalPages = Math.max(1, Math.ceil(total / PAGE_SIZE));
  const summary = data?.summary;

  const renderSummary = () => {
    if (!data) return null;
    switch (tab) {
      case "users":
        return (
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <Card className="p-5 flex items-center justify-center" hover={false}>
              <DonutChart
                data={[
                  { label: "Active", value: summary.activeUsers, color: "var(--color-wine)" },
                  { label: "Inactive", value: summary.inactiveUsers, color: "var(--color-dusty-rose)" },
                ]}
                centerValue={summary.totalUsers}
                centerLabel="Total Users"
              />
            </Card>
            <Card className="p-5 flex flex-col items-center justify-center" hover={false}>
              <p className="text-xs text-subtext">New Users (30 days)</p>
              <p className="text-3xl font-bold text-wine mt-1">{summary.newUsers}</p>
            </Card>
          </div>
        );
      case "orders": {
        const other = Math.max(0, summary.totalOrders - summary.delivered - summary.cancelled);
        return (
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <Card className="p-5 flex items-center justify-center" hover={false}>
              <DonutChart
                data={[
                  { label: "Delivered", value: summary.delivered, color: "var(--color-wine)" },
                  { label: "Cancelled", value: summary.cancelled, color: "var(--color-dusty-rose)" },
                  { label: "Other", value: other, color: "var(--color-gold)" },
                ]}
                centerValue={summary.totalOrders}
                centerLabel="Total Orders"
              />
            </Card>
            <div className="grid grid-cols-1 gap-4">
              <Card className="p-5" hover={false}>
                <p className="text-xs text-subtext">Total Revenue (delivered)</p>
                <p className="text-2xl font-bold text-wine mt-1">{formatPrice(summary.totalRevenue, "ILS")}</p>
              </Card>
              <Card className="p-5" hover={false}>
                <p className="text-xs text-subtext">Avg Order Value</p>
                <p className="text-2xl font-bold text-ink mt-1">{formatPrice(summary.avgOrderValue, "ILS")}</p>
              </Card>
            </div>
          </div>
        );
      }
      case "stores":
        return (
          <Card className="p-5" hover={false}>
            <h3 className="font-semibold text-ink mb-4">Revenue by Store (this page)</h3>
            <BarChart
              data={rows.map((r) => ({ name: r.storeName?.slice(0, 12), value: r.revenue || 0 }))}
              valueKey="value"
              labelKey="name"
              color="var(--color-wine)"
              formatValue={(v) => v.toFixed(0)}
            />
          </Card>
        );
      case "products":
        return (
          <Card className="p-5" hover={false}>
            <h3 className="font-semibold text-ink mb-4">Units Sold (this page)</h3>
            <BarChart
              data={rows.map((r) => ({ name: r.name?.slice(0, 12), value: r.totalSold || 0 }))}
              valueKey="value"
              labelKey="name"
              color="var(--color-dusty-rose)"
            />
          </Card>
        );
      case "ai":
        return (
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
            <Card className="p-5" hover={false}>
              <p className="text-xs text-subtext">Total Scans</p>
              <p className="text-2xl font-bold text-wine mt-1">{summary.totalScans}</p>
            </Card>
            <Card className="p-5" hover={false}>
              <p className="text-xs text-subtext">Routines Generated</p>
              <p className="text-2xl font-bold text-ink mt-1">{summary.totalRoutines}</p>
            </Card>
            <Card className="p-5" hover={false}>
              <p className="text-xs text-subtext">Avg Skin Score</p>
              <p className="text-2xl font-bold text-ink mt-1">{summary.avgSkinScore}</p>
            </Card>
            <Card className="p-5 sm:col-span-3" hover={false}>
              <h3 className="font-semibold text-ink mb-4">Top Concerns</h3>
              <BarChart
                data={rows.map((r) => ({ name: r.concern?.slice(0, 12), value: Number(r.occurrences) || 0 }))}
                valueKey="value"
                labelKey="name"
                color="var(--color-wine)"
              />
            </Card>
          </div>
        );
      case "login-activity":
        return (
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
            <Card className="p-5" hover={false}>
              <p className="text-xs text-subtext">Total Logins</p>
              <p className="text-2xl font-bold text-wine mt-1">{summary.totalLogins}</p>
            </Card>
            <Card className="p-5" hover={false}>
              <p className="text-xs text-subtext">Avg Session</p>
              <p className="text-2xl font-bold text-ink mt-1">{summary.avgSessionMinutes} min</p>
            </Card>
            <Card className="p-5" hover={false}>
              <p className="text-xs text-subtext">Peak Hour</p>
              <p className="text-2xl font-bold text-ink mt-1">{summary.peakHour}</p>
            </Card>
          </div>
        );
      case "notifications":
        return (
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
            <div className="grid grid-cols-3 gap-4">
              <Card className="p-5" hover={false}>
                <p className="text-xs text-subtext">Total Sent</p>
                <p className="text-2xl font-bold text-wine mt-1">{summary.total}</p>
              </Card>
              <Card className="p-5" hover={false}>
                <p className="text-xs text-subtext">Opened</p>
                <p className="text-2xl font-bold text-ink mt-1">{summary.opened}</p>
              </Card>
              <Card className="p-5" hover={false}>
                <p className="text-xs text-subtext">Avg Open Rate</p>
                <p className="text-2xl font-bold text-ink mt-1">{summary.avgOpenRate}</p>
              </Card>
            </div>
            <Card className="p-5" hover={false}>
              <h3 className="font-semibold text-ink mb-4">Recipients</h3>
              <BarChart
                data={rows.map((r) => ({ name: r.notification?.slice(0, 12), value: r.recipients || 0 }))}
                valueKey="value"
                labelKey="name"
                color="var(--color-gold)"
              />
            </Card>
          </div>
        );
      case "reviews":
        return (
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
            <div className="grid grid-cols-3 gap-4">
              <Card className="p-5" hover={false}>
                <p className="text-xs text-subtext">Total Reviews</p>
                <p className="text-2xl font-bold text-wine mt-1">{summary.totalReviews}</p>
              </Card>
              <Card className="p-5" hover={false}>
                <p className="text-xs text-subtext">Highest Rated</p>
                <p className="text-2xl font-bold text-ink mt-1">{summary.highestRated?.toFixed?.(1) || "0.0"}</p>
              </Card>
              <Card className="p-5" hover={false}>
                <p className="text-xs text-subtext">Lowest Rated</p>
                <p className="text-2xl font-bold text-ink mt-1">{summary.lowestRated?.toFixed?.(1) || "0.0"}</p>
              </Card>
            </div>
            <Card className="p-5" hover={false}>
              <h3 className="font-semibold text-ink mb-4">Avg Rating by Store</h3>
              <BarChart
                data={rows.map((r) => ({ name: r.storeName?.slice(0, 12), value: r.avgRating || 0 }))}
                valueKey="value"
                labelKey="name"
                color="var(--color-gold)"
                formatValue={(v) => v.toFixed(1)}
              />
            </Card>
          </div>
        );
      case "revenue":
        return (
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
            <div className="grid grid-cols-2 gap-4">
              <Card className="p-5" hover={false}>
                <p className="text-xs text-subtext">Total Revenue</p>
                <p className="text-2xl font-bold text-wine mt-1">{formatPrice(summary?.totalRevenue, "ILS")}</p>
              </Card>
              <Card className="p-5" hover={false}>
                <p className="text-xs text-subtext">Avg Order Value</p>
                <p className="text-2xl font-bold text-ink mt-1">{formatPrice(summary?.avgOrderValue, "ILS")}</p>
              </Card>
            </div>
            <Card className="p-5" hover={false}>
              <h3 className="font-semibold text-ink mb-4">Net Revenue by Store</h3>
              <BarChart
                data={rows.map((r) => ({ name: r.storeName?.slice(0, 12), value: r.netRevenue || 0 }))}
                valueKey="value"
                labelKey="name"
                color="var(--color-wine)"
                formatValue={(v) => v.toFixed(0)}
              />
            </Card>
          </div>
        );
      default:
        return null;
    }
  };

  return (
    <div className="flex flex-col gap-5">
      <div className="flex flex-wrap items-center justify-between gap-3 animate-fade-slide-in">
        <div>
          <h2 className="font-display text-2xl font-bold text-ink">Reports</h2>
          <p className="text-sm text-subtext mt-1">Detailed platform reports with CSV export.</p>
        </div>
        <div className="flex items-center gap-2 print:hidden">
          <Button variant="secondary" size="sm" onClick={handleExportCsv} disabled={exporting}>
            <Download size={16} /> CSV
          </Button>
          <Button variant="outline" size="sm" onClick={() => window.print()}>
            <Printer size={16} /> PDF
          </Button>
        </div>
      </div>

      <div className="print:hidden">
        <Tabs tabs={TABS} value={tab} onChange={handleTabChange} />
      </div>

      <div className="flex flex-wrap gap-3 print:hidden">
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

        {tab === "users" && (
          <>
            <select
              value={status}
              onChange={(e) => {
                setStatus(e.target.value);
                setPage(1);
              }}
              className={`${inputClass} sm:max-w-[160px]`}
            >
              {USER_STATUS_OPTIONS.map((opt) => (
                <option key={opt.value} value={opt.value}>
                  {opt.label}
                </option>
              ))}
            </select>
            <select
              value={sort}
              onChange={(e) => {
                setSort(e.target.value);
                setPage(1);
              }}
              className={`${inputClass} sm:max-w-[180px]`}
            >
              {USER_SORT_OPTIONS.map((opt) => (
                <option key={opt.value} value={opt.value}>
                  {opt.label}
                </option>
              ))}
            </select>
            <div className="relative flex-1 max-w-sm">
              <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-subtext" />
              <input
                type="text"
                value={search}
                onChange={(e) => {
                  setSearch(e.target.value);
                  setPage(1);
                }}
                placeholder="Search by name, email, phone..."
                className={`${inputClass} pl-9`}
              />
            </div>
          </>
        )}

        {tab === "stores" && (
          <>
            <select
              value={filter}
              onChange={(e) => {
                setFilter(e.target.value);
                setPage(1);
              }}
              className={`${inputClass} sm:max-w-[180px]`}
            >
              {STORE_FILTER_OPTIONS.map((opt) => (
                <option key={opt.value} value={opt.value}>
                  {opt.label}
                </option>
              ))}
            </select>
            <div className="relative flex-1 max-w-sm">
              <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-subtext" />
              <input
                type="text"
                value={search}
                onChange={(e) => {
                  setSearch(e.target.value);
                  setPage(1);
                }}
                placeholder="Search by store name..."
                className={`${inputClass} pl-9`}
              />
            </div>
          </>
        )}

        {tab === "orders" && (
          <>
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
            <div className="relative flex-1 max-w-sm">
              <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-subtext" />
              <input
                type="text"
                value={search}
                onChange={(e) => {
                  setSearch(e.target.value);
                  setPage(1);
                }}
                placeholder="Search by customer name or city..."
                className={`${inputClass} pl-9`}
              />
            </div>
          </>
        )}

        {tab === "products" && (
          <>
            <select
              value={filter}
              onChange={(e) => {
                setFilter(e.target.value);
                setPage(1);
              }}
              className={`${inputClass} sm:max-w-[180px]`}
            >
              {PRODUCT_FILTER_OPTIONS.map((opt) => (
                <option key={opt.value} value={opt.value}>
                  {opt.label}
                </option>
              ))}
            </select>
            <div className="relative flex-1 max-w-sm">
              <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-subtext" />
              <input
                type="text"
                value={search}
                onChange={(e) => {
                  setSearch(e.target.value);
                  setPage(1);
                }}
                placeholder="Search by name or brand..."
                className={`${inputClass} pl-9`}
              />
            </div>
          </>
        )}

        {tab === "login-activity" && (
          <input
            type="text"
            value={device}
            onChange={(e) => {
              setDevice(e.target.value);
              setPage(1);
            }}
            placeholder="Filter by device..."
            className={`${inputClass} sm:max-w-[200px]`}
          />
        )}

        {tab === "reviews" && (
          <div className="relative flex-1 max-w-sm">
            <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-subtext" />
            <input
              type="text"
              value={search}
              onChange={(e) => {
                setSearch(e.target.value);
                setPage(1);
              }}
              placeholder="Search by store name..."
              className={`${inputClass} pl-9`}
            />
          </div>
        )}
      </div>

      {renderSummary()}

      <AdminReportTable columns={config.columns} rows={rows} loading={loading} />

      {config.paginated && totalPages > 1 && <Pagination page={page} totalPages={totalPages} onChange={setPage} />}
    </div>
  );
}
