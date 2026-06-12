import { useEffect, useMemo, useState } from "react";
import { Plus, Search, Pencil, Trash2, Eye, EyeOff, Loader2 } from "lucide-react";
import Card from "../../components/common/Card";
import Button from "../../components/common/Button";
import EmptyState from "../../components/common/EmptyState";
import Tabs from "../../components/common/Tabs";
import Pagination from "../../components/common/Pagination";
import ConfirmDialog from "../../components/common/ConfirmDialog";
import { resolveImageUrl } from "../../services/api";
import { useStoreOwner } from "../../context/StoreOwnerContext";
import { useToast } from "../../context/ToastContext";
import { storeOwnerService } from "../../services/storeOwnerService";
import { formatPrice } from "../../utils/format";
import { inputClass } from "../../components/common/AuthLayout";
import ProductFormModal from "./ProductFormModal";
import { Package } from "lucide-react";

const PAGE_SIZE = 8;

const FILTERS = [
  { value: "all", label: "All" },
  { value: "in_stock", label: "In Stock" },
  { value: "low_stock", label: "Low Stock" },
  { value: "out_of_stock", label: "Out of Stock" },
  { value: "hidden", label: "Hidden" },
];

export default function ProductsPage() {
  const { store } = useStoreOwner();
  const toast = useToast();
  const [products, setProducts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [filter, setFilter] = useState("all");
  const [page, setPage] = useState(1);
  const [modalOpen, setModalOpen] = useState(false);
  const [editing, setEditing] = useState(null);
  const [deleting, setDeleting] = useState(null);
  const [deleteLoading, setDeleteLoading] = useState(false);

  const load = () => {
    if (!store?._id) return;
    setLoading(true);
    storeOwnerService
      .fetchStoreProducts(store._id, true)
      .then(setProducts)
      .catch(() => toast.error("Couldn't load products."))
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    load();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [store?._id]);

  const filtered = useMemo(() => {
    let list = products;
    const q = search.trim().toLowerCase();
    if (q) {
      list = list.filter(
        (sp) =>
          sp.productId?.name?.toLowerCase().includes(q) ||
          sp.productId?.brand?.toLowerCase().includes(q)
      );
    }
    switch (filter) {
      case "in_stock":
        return list.filter((sp) => sp.stockCount > 5);
      case "low_stock":
        return list.filter((sp) => sp.stockCount > 0 && sp.stockCount <= 5);
      case "out_of_stock":
        return list.filter((sp) => sp.stockCount === 0 || !sp.isAvailable);
      case "hidden":
        return list.filter((sp) => sp.productId?.isHidden);
      default:
        return list;
    }
  }, [products, search, filter]);

  const totalPages = Math.max(1, Math.ceil(filtered.length / PAGE_SIZE));
  const pageItems = filtered.slice((page - 1) * PAGE_SIZE, page * PAGE_SIZE);

  const handleToggleHidden = async (sp) => {
    try {
      await storeOwnerService.updateProduct(sp.productId._id, { isHidden: !sp.productId.isHidden });
      toast.success(sp.productId.isHidden ? "Product is now visible." : "Product hidden from shop.");
      load();
    } catch {
      toast.error("Couldn't update product visibility.");
    }
  };

  const handleDelete = async () => {
    if (!deleting) return;
    setDeleteLoading(true);
    try {
      await storeOwnerService.deleteStoreProduct(deleting._id);
      toast.success("Product removed from your store.");
      setDeleting(null);
      load();
    } catch {
      toast.error("Couldn't remove product.");
    } finally {
      setDeleteLoading(false);
    }
  };

  return (
    <div className="flex flex-col gap-5">
      <div className="flex flex-wrap items-center justify-between gap-3 animate-fade-slide-in">
        <div>
          <h2 className="font-display text-2xl font-bold text-ink">Products</h2>
          <p className="text-sm text-subtext mt-1">Manage your store's catalog and stock.</p>
        </div>
        <Button
          onClick={() => {
            setEditing(null);
            setModalOpen(true);
          }}
        >
          <Plus size={16} /> Add Product
        </Button>
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
            placeholder="Search products..."
            className={`${inputClass} pl-9`}
          />
        </div>
        <Tabs
          tabs={FILTERS}
          value={filter}
          onChange={(v) => {
            setFilter(v);
            setPage(1);
          }}
        />
      </div>

      {loading ? (
        <div className="flex items-center justify-center py-24">
          <Loader2 className="animate-spin text-wine" size={32} />
        </div>
      ) : filtered.length === 0 ? (
        <EmptyState
          icon={Package}
          title="No products found"
          message="Try adjusting your filters or add a new product to your store."
        />
      ) : (
        <>
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
            {pageItems.map((sp, i) => {
              const p = sp.productId || {};
              const outOfStock = sp.stockCount === 0 || !sp.isAvailable;
              const lowStock = sp.stockCount > 0 && sp.stockCount <= 5;
              return (
                <Card
                  key={sp._id}
                  className="p-4 flex flex-col gap-2 animate-pop-in"
                  style={{ animationDelay: `${Math.min(i, 7) * 40}ms` }}
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
                    {outOfStock && (
                      <span className="absolute top-2 right-2 text-[10px] font-semibold px-2 py-0.5 rounded-full bg-red-50 text-red-600">
                        Out of stock
                      </span>
                    )}
                    {!outOfStock && lowStock && (
                      <span className="absolute top-2 right-2 text-[10px] font-semibold px-2 py-0.5 rounded-full bg-orange-50 text-orange-600">
                        Low stock
                      </span>
                    )}
                  </div>
                  <div className="min-w-0">
                    <p className="font-semibold text-ink truncate">{p.name}</p>
                    <p className="text-xs text-subtext truncate">{p.brand}</p>
                  </div>
                  <div className="flex items-center justify-between">
                    <p className="font-bold text-wine">{formatPrice(sp.price, sp.currency)}</p>
                    <p className="text-xs text-subtext">Stock: {sp.stockCount}</p>
                  </div>
                  <div className="flex items-center gap-2 mt-1">
                    <Button
                      variant="secondary"
                      size="sm"
                      className="flex-1"
                      onClick={() => {
                        setEditing(sp);
                        setModalOpen(true);
                      }}
                    >
                      <Pencil size={14} /> Edit
                    </Button>
                    <button
                      onClick={() => handleToggleHidden(sp)}
                      title={p.isHidden ? "Show product" : "Hide product"}
                      className="p-2 rounded-full text-wine hover:bg-soft-pink transition-all"
                    >
                      {p.isHidden ? <EyeOff size={16} /> : <Eye size={16} />}
                    </button>
                    <button
                      onClick={() => setDeleting(sp)}
                      title="Remove from store"
                      className="p-2 rounded-full text-danger hover:bg-soft-pink transition-all"
                    >
                      <Trash2 size={16} />
                    </button>
                  </div>
                </Card>
              );
            })}
          </div>
          <Pagination page={page} totalPages={totalPages} onChange={setPage} />
        </>
      )}

      <ProductFormModal
        open={modalOpen}
        onClose={() => setModalOpen(false)}
        storeId={store?._id}
        sellerId={store?.sellerId}
        storeProduct={editing}
        onSaved={() => {
          setModalOpen(false);
          load();
        }}
      />

      <ConfirmDialog
        open={!!deleting}
        onClose={() => setDeleting(null)}
        onConfirm={handleDelete}
        title="Remove Product"
        message={`Remove "${deleting?.productId?.name}" from your store? This won't delete it from the catalog.`}
        confirmLabel="Remove"
        variant="primary"
        loading={deleteLoading}
      />
    </div>
  );
}
