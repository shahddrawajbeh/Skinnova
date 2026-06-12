import { useEffect, useState } from "react";
import { Search, Loader2, Store as StoreIcon, MapPin, Star } from "lucide-react";
import Card from "../../components/common/Card";
import Pagination from "../../components/common/Pagination";
import EmptyState from "../../components/common/EmptyState";
import { inputClass } from "../../components/common/AuthLayout";
import { adminService } from "../../services/adminService";
import { useToast } from "../../context/ToastContext";
import { resolveImageUrl } from "../../services/api";
import StoreDetailModal from "../../components/admin/StoreDetailModal";

const PAGE_SIZE = 12;

const APPROVAL_STYLES = {
  pending: "bg-amber-50 text-amber-600",
  approved: "bg-emerald-50 text-emerald-600",
  rejected: "bg-red-50 text-red-600",
};

export default function StoresPage() {
  const toast = useToast();
  const [stores, setStores] = useState([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [isActive, setIsActive] = useState("");
  const [approvalStatus, setApprovalStatus] = useState("");
  const [page, setPage] = useState(1);
  const [selectedId, setSelectedId] = useState(null);

  const load = () => {
    setLoading(true);
    adminService
      .fetchStores({
        search: search || undefined,
        isActive: isActive || undefined,
        approvalStatus: approvalStatus || undefined,
        page,
        limit: PAGE_SIZE,
      })
      .then((data) => {
        setStores(data.stores || []);
        setTotal(data.total || 0);
      })
      .catch(() => toast.error("Couldn't load stores."))
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    const t = setTimeout(load, 300);
    return () => clearTimeout(t);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [search, isActive, approvalStatus, page]);

  const totalPages = Math.max(1, Math.ceil(total / PAGE_SIZE));

  return (
    <div className="flex flex-col gap-5">
      <div className="animate-fade-slide-in">
        <h2 className="font-display text-2xl font-bold text-ink">Stores</h2>
        <p className="text-sm text-subtext mt-1">Browse and manage seller storefronts.</p>
      </div>

      <div className="flex flex-col sm:flex-row gap-3 animate-fade-slide-in">
        <div className="relative flex-1 max-w-sm">
          <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-subtext" />
          <input
            type="text"
            value={search}
            onChange={(e) => {
              setSearch(e.target.value);
              setPage(1);
            }}
            placeholder="Search by store name or city..."
            className={`${inputClass} pl-9`}
          />
        </div>
        <select
          value={isActive}
          onChange={(e) => {
            setIsActive(e.target.value);
            setPage(1);
          }}
          className={`${inputClass} sm:max-w-[160px]`}
        >
          <option value="">All statuses</option>
          <option value="true">Active</option>
          <option value="false">Inactive</option>
        </select>
        <select
          value={approvalStatus}
          onChange={(e) => {
            setApprovalStatus(e.target.value);
            setPage(1);
          }}
          className={`${inputClass} sm:max-w-[180px]`}
        >
          <option value="">All approval states</option>
          <option value="pending">Pending</option>
          <option value="approved">Approved</option>
          <option value="rejected">Rejected</option>
        </select>
      </div>

      {loading ? (
        <div className="flex items-center justify-center py-24">
          <Loader2 className="animate-spin text-wine" size={32} />
        </div>
      ) : stores.length === 0 ? (
        <EmptyState icon={StoreIcon} title="No stores found" message="Try adjusting your search or filters." />
      ) : (
        <>
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
            {stores.map((s, i) => (
              <Card
                key={s._id}
                className="p-4 flex flex-col gap-2 cursor-pointer animate-pop-in"
                style={{ animationDelay: `${Math.min(i, 11) * 30}ms` }}
                onClick={() => setSelectedId(s._id)}
              >
                <div className="flex items-center gap-3">
                  {s.logoUrl ? (
                    <img src={resolveImageUrl(s.logoUrl)} alt="" className="h-12 w-12 rounded-xl object-cover shrink-0" />
                  ) : (
                    <div className="h-12 w-12 rounded-xl bg-soft-pink flex items-center justify-center text-wine font-bold shrink-0">
                      {s.storeName?.[0]?.toUpperCase() || "S"}
                    </div>
                  )}
                  <div className="min-w-0">
                    <p className="font-semibold text-ink truncate">{s.storeName}</p>
                    <p className="text-xs text-subtext truncate flex items-center gap-1">
                      <MapPin size={12} /> {s.city}
                    </p>
                  </div>
                </div>
                <p className="text-xs text-subtext truncate">{s.sellerId?.fullName}</p>
                <div className="flex items-center gap-1.5 flex-wrap">
                  <span className={`inline-flex items-center gap-1 text-[10px] font-semibold px-2 py-0.5 rounded-full ${APPROVAL_STYLES[s.approvalStatus] || APPROVAL_STYLES.pending}`}>
                    {s.approvalStatus}
                  </span>
                  <span className={`inline-block text-[10px] font-semibold px-2 py-0.5 rounded-full ${s.isActive === false ? "bg-red-50 text-red-600" : "bg-emerald-50 text-emerald-600"}`}>
                    {s.isActive === false ? "Inactive" : "Active"}
                  </span>
                  {s.isVerified && (
                    <span className="inline-flex items-center gap-1 text-[10px] font-semibold px-2 py-0.5 rounded-full bg-gold/20 text-wine-dark">
                      <Star size={10} /> {s.verificationLevel}
                    </span>
                  )}
                </div>
              </Card>
            ))}
          </div>
          <Pagination page={page} totalPages={totalPages} onChange={setPage} />
        </>
      )}

      {selectedId && (
        <StoreDetailModal storeId={selectedId} onClose={() => setSelectedId(null)} onChange={load} />
      )}
    </div>
  );
}
