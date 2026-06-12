import { useEffect, useState } from "react";
import { Search, Loader2, Package, Eye, EyeOff, Trash2, Star } from "lucide-react";
import Card from "../../components/common/Card";
import Button from "../../components/common/Button";
import Modal from "../../components/common/Modal";
import ConfirmDialog from "../../components/common/ConfirmDialog";
import Pagination from "../../components/common/Pagination";
import EmptyState from "../../components/common/EmptyState";
import { inputClass } from "../../components/common/AuthLayout";
import { adminService } from "../../services/adminService";
import { useToast } from "../../context/ToastContext";
import { resolveImageUrl } from "../../services/api";
import { formatPrice } from "../../utils/format";

const PAGE_SIZE = 12;

export default function ProductsPage() {
  const toast = useToast();
  const [products, setProducts] = useState([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [category, setCategory] = useState("");
  const [brand, setBrand] = useState("");
  const [hiddenOnly, setHiddenOnly] = useState(false);
  const [page, setPage] = useState(1);
  const [selected, setSelected] = useState(null);
  const [deleting, setDeleting] = useState(null);
  const [actionLoading, setActionLoading] = useState(false);

  const load = () => {
    setLoading(true);
    adminService
      .fetchProducts({
        search: search || undefined,
        category: category || undefined,
        brand: brand || undefined,
        isHidden: hiddenOnly ? true : undefined,
        page,
        limit: PAGE_SIZE,
      })
      .then((data) => {
        setProducts(data.products || []);
        setTotal(data.total || 0);
      })
      .catch(() => toast.error("Couldn't load products."))
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    const t = setTimeout(load, 300);
    return () => clearTimeout(t);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [search, category, brand, hiddenOnly, page]);

  const totalPages = Math.max(1, Math.ceil(total / PAGE_SIZE));

  const handleToggleHidden = async (product) => {
    try {
      const res = await adminService.toggleProductHidden(product._id);
      toast.success(res.isHidden ? "Product hidden." : "Product is now visible.");
      setProducts((list) => list.map((p) => (p._id === product._id ? { ...p, isHidden: res.isHidden } : p)));
      setSelected((s) => (s?._id === product._id ? { ...s, isHidden: res.isHidden } : s));
    } catch {
      toast.error("Couldn't update product visibility.");
    }
  };

  const handleDelete = async () => {
    if (!deleting) return;
    setActionLoading(true);
    try {
      await adminService.deleteProduct(deleting._id);
      toast.success("Product deleted.");
      setDeleting(null);
      setSelected(null);
      load();
    } catch {
      toast.error("Couldn't delete product.");
    } finally {
      setActionLoading(false);
    }
  };

  return (
    <div className="flex flex-col gap-5">
      <div className="animate-fade-slide-in">
        <h2 className="font-display text-2xl font-bold text-ink">Products</h2>
        <p className="text-sm text-subtext mt-1">Browse the catalog and moderate listings.</p>
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
            placeholder="Search by name or brand..."
            className={`${inputClass} pl-9`}
          />
        </div>
        <input
          type="text"
          value={category}
          onChange={(e) => {
            setCategory(e.target.value);
            setPage(1);
          }}
          placeholder="Category"
          className={`${inputClass} sm:max-w-[160px]`}
        />
        <input
          type="text"
          value={brand}
          onChange={(e) => {
            setBrand(e.target.value);
            setPage(1);
          }}
          placeholder="Brand"
          className={`${inputClass} sm:max-w-[160px]`}
        />
        <label className="flex items-center gap-2 text-sm text-ink whitespace-nowrap px-1">
          <input
            type="checkbox"
            checked={hiddenOnly}
            onChange={(e) => {
              setHiddenOnly(e.target.checked);
              setPage(1);
            }}
          />
          Hidden only
        </label>
      </div>

      {loading ? (
        <div className="flex items-center justify-center py-24">
          <Loader2 className="animate-spin text-wine" size={32} />
        </div>
      ) : products.length === 0 ? (
        <EmptyState icon={Package} title="No products found" message="Try adjusting your search or filters." />
      ) : (
        <>
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
            {products.map((p, i) => (
              <Card
                key={p._id}
                className="p-4 flex flex-col gap-2 cursor-pointer animate-pop-in"
                style={{ animationDelay: `${Math.min(i, 11) * 30}ms` }}
                onClick={() => setSelected(p)}
              >
                <div className="relative h-32 rounded-xl overflow-hidden bg-soft-pink">
                  {p.imageUrl ? (
                    <img src={resolveImageUrl(p.imageUrl)} alt="" className="h-full w-full object-cover" />
                  ) : (
                    <div className="h-full w-full flex items-center justify-center text-wine/30 font-display text-2xl">
                      S
                    </div>
                  )}
                  {p.isHidden && (
                    <span className="absolute top-2 left-2 text-[10px] font-semibold px-2 py-0.5 rounded-full bg-ink/70 text-white">
                      Hidden
                    </span>
                  )}
                </div>
                <div className="min-w-0">
                  <p className="font-semibold text-ink truncate">{p.name}</p>
                  <p className="text-xs text-subtext truncate">{p.brand} · {p.category || "—"}</p>
                </div>
                <div className="flex items-center justify-between">
                  <p className="font-bold text-wine">{formatPrice(p.price, p.currency)}</p>
                  <p className="text-xs text-subtext flex items-center gap-1">
                    <Star size={12} className="text-gold" /> {p.rating?.toFixed?.(1) || "0.0"}
                  </p>
                </div>
              </Card>
            ))}
          </div>
          <Pagination page={page} totalPages={totalPages} onChange={setPage} />
        </>
      )}

      <Modal open={!!selected} onClose={() => setSelected(null)} title="Product Details" size="lg">
        {selected && (
          <div className="flex flex-col gap-4">
            <div className="flex items-center gap-4">
              <div className="h-20 w-20 rounded-2xl overflow-hidden bg-soft-pink shrink-0">
                {selected.imageUrl ? (
                  <img src={resolveImageUrl(selected.imageUrl)} alt="" className="h-full w-full object-cover" />
                ) : (
                  <div className="h-full w-full flex items-center justify-center text-wine/30 font-display text-2xl">S</div>
                )}
              </div>
              <div className="min-w-0 flex-1">
                <p className="font-display text-lg font-bold text-ink truncate">{selected.name}</p>
                <p className="text-sm text-subtext truncate">{selected.brand} · {selected.category || "—"}</p>
              </div>
              <span className={`inline-block text-xs font-semibold px-2.5 py-1 rounded-full shrink-0 ${selected.isHidden ? "bg-ink/70 text-white" : "bg-emerald-50 text-emerald-600"}`}>
                {selected.isHidden ? "Hidden" : "Visible"}
              </span>
            </div>

            <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
              <div className="rounded-xl bg-soft-pink/50 px-3 py-2.5">
                <p className="text-xs text-subtext">Price</p>
                <p className="text-sm font-semibold text-ink">{formatPrice(selected.price, selected.currency)}</p>
              </div>
              <div className="rounded-xl bg-soft-pink/50 px-3 py-2.5">
                <p className="text-xs text-subtext">Stock</p>
                <p className="text-sm font-semibold text-ink">{selected.stockCount ?? 0}</p>
              </div>
              <div className="rounded-xl bg-soft-pink/50 px-3 py-2.5">
                <p className="text-xs text-subtext">Rating</p>
                <p className="text-sm font-semibold text-ink">{selected.rating?.toFixed?.(1) || "0.0"}</p>
              </div>
              <div className="rounded-xl bg-soft-pink/50 px-3 py-2.5">
                <p className="text-xs text-subtext">Reviews</p>
                <p className="text-sm font-semibold text-ink">{selected.reviews?.length || 0}</p>
              </div>
            </div>

            {selected.shortDescription && (
              <div>
                <p className="text-xs text-subtext mb-1">Description</p>
                <p className="text-sm text-ink">{selected.shortDescription}</p>
              </div>
            )}

            {selected.recommendedFor?.concerns?.length > 0 && (
              <div>
                <p className="text-xs text-subtext mb-1">Recommended for</p>
                <div className="flex flex-wrap gap-1.5">
                  {selected.recommendedFor.concerns.map((c) => (
                    <span key={c} className="text-[11px] font-semibold px-2 py-0.5 rounded-full bg-soft-pink text-wine">
                      {c}
                    </span>
                  ))}
                </div>
              </div>
            )}

            <div className="flex flex-wrap items-center justify-between gap-2 pt-2 border-t border-divider">
              <Button variant="secondary" size="sm" onClick={() => handleToggleHidden(selected)}>
                {selected.isHidden ? <Eye size={14} /> : <EyeOff size={14} />}
                {selected.isHidden ? "Show Product" : "Hide Product"}
              </Button>
              <Button
                variant="outline"
                size="sm"
                className="!border-danger !text-danger hover:!bg-danger hover:!text-white"
                onClick={() => setDeleting(selected)}
              >
                <Trash2 size={14} /> Delete Product
              </Button>
            </div>
          </div>
        )}
      </Modal>

      <ConfirmDialog
        open={!!deleting}
        onClose={() => setDeleting(null)}
        onConfirm={handleDelete}
        title="Delete Product"
        message={`Permanently delete "${deleting?.name}"? This cannot be undone.`}
        confirmLabel="Delete"
        loading={actionLoading}
      />
    </div>
  );
}
