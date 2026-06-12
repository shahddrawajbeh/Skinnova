import { useEffect, useState } from "react";
import { Search, Upload, Loader2 } from "lucide-react";
import Modal from "../../components/common/Modal";
import Button from "../../components/common/Button";
import Tabs from "../../components/common/Tabs";
import { inputClass, FormField } from "../../components/common/AuthLayout";
import { resolveImageUrl } from "../../services/api";
import { productService } from "../../services/productService";
import { storeOwnerService } from "../../services/storeOwnerService";
import { useToast } from "../../context/ToastContext";

const EMPTY_FORM = {
  name: "",
  brand: "",
  category: "",
  shortDescription: "",
  price: "",
  currency: "ILS",
  stockCount: "",
  discountPercent: "",
  imageUrl: "",
};

export default function ProductFormModal({ open, onClose, storeId, sellerId, storeProduct, onSaved }) {
  const toast = useToast();
  const isEdit = !!storeProduct;
  const [tab, setTab] = useState("catalog");
  const [form, setForm] = useState(EMPTY_FORM);
  const [imageFile, setImageFile] = useState(null);
  const [imagePreview, setImagePreview] = useState("");
  const [submitting, setSubmitting] = useState(false);

  // Catalog search state
  const [search, setSearch] = useState("");
  const [catalog, setCatalog] = useState([]);
  const [catalogLoading, setCatalogLoading] = useState(false);
  const [selectedProduct, setSelectedProduct] = useState(null);

  useEffect(() => {
    if (!open) return;
    if (isEdit) {
      const p = storeProduct.productId || {};
      setForm({
        name: p.name || "",
        brand: p.brand || "",
        category: p.category || "",
        shortDescription: p.shortDescription || "",
        price: storeProduct.price ?? "",
        currency: storeProduct.currency || "ILS",
        stockCount: storeProduct.stockCount ?? "",
        discountPercent: p.discountPercent ?? "",
        imageUrl: p.imageUrl || "",
      });
      setImagePreview(p.imageUrl ? resolveImageUrl(p.imageUrl) : "");
      setTab("details");
    } else {
      setForm(EMPTY_FORM);
      setImageFile(null);
      setImagePreview("");
      setSelectedProduct(null);
      setSearch("");
      setTab("catalog");
    }
  }, [open, isEdit, storeProduct]);

  useEffect(() => {
    if (!open || isEdit || tab !== "catalog") return;
    setCatalogLoading(true);
    productService
      .fetchProducts()
      .then(setCatalog)
      .finally(() => setCatalogLoading(false));
  }, [open, isEdit, tab]);

  if (!open) return null;

  const filteredCatalog = catalog.filter((p) => {
    const q = search.trim().toLowerCase();
    if (!q) return true;
    return p.name?.toLowerCase().includes(q) || p.brand?.toLowerCase().includes(q);
  });

  const handleField = (key) => (e) => setForm((f) => ({ ...f, [key]: e.target.value }));

  const handleImageChange = (e) => {
    const file = e.target.files?.[0];
    if (!file) return;
    setImageFile(file);
    setImagePreview(URL.createObjectURL(file));
  };

  const selectCatalogProduct = (product) => {
    setSelectedProduct(product);
    setForm((f) => ({
      ...f,
      price: product.price ?? "",
      currency: product.currency || "ILS",
      stockCount: product.stockCount ?? "",
    }));
  };

  const handleAddFromCatalog = async () => {
    if (!selectedProduct) {
      toast.error("Select a product from the catalog first.");
      return;
    }
    setSubmitting(true);
    try {
      await storeOwnerService.addStoreProduct({
        storeId,
        productId: selectedProduct._id,
        sellerId,
        price: Number(form.price) || 0,
        currency: form.currency,
        stockCount: Number(form.stockCount) || 0,
      });
      toast.success("Product added to your store.");
      onSaved();
    } catch (err) {
      toast.error(err.response?.data?.message || "Couldn't add product.");
    } finally {
      setSubmitting(false);
    }
  };

  const handleSaveDetails = async () => {
    if (!form.name || !form.brand) {
      toast.error("Name and brand are required.");
      return;
    }
    setSubmitting(true);
    try {
      let imageUrl = form.imageUrl;
      if (imageFile) {
        const res = await storeOwnerService.uploadProductImage(imageFile);
        imageUrl = res.imageUrl;
      }

      const productPayload = {
        name: form.name,
        brand: form.brand,
        category: form.category,
        shortDescription: form.shortDescription,
        discountPercent: Number(form.discountPercent) || 0,
        imageUrl,
      };

      if (isEdit) {
        const productId = storeProduct.productId?._id;
        await storeOwnerService.updateProduct(productId, productPayload);
        await storeOwnerService.updateStoreProduct(storeProduct._id, {
          price: Number(form.price) || 0,
          stockCount: Number(form.stockCount) || 0,
        });
        toast.success("Product updated.");
      } else {
        const created = await storeOwnerService.createProduct({
          ...productPayload,
          price: Number(form.price) || 0,
          currency: form.currency,
          stockCount: Number(form.stockCount) || 0,
          isPublished: true,
        });
        const product = created.product || created;
        await storeOwnerService.addStoreProduct({
          storeId,
          productId: product._id,
          sellerId,
          price: Number(form.price) || 0,
          currency: form.currency,
          stockCount: Number(form.stockCount) || 0,
        });
        toast.success("Product created and added to your store.");
      }
      onSaved();
    } catch (err) {
      toast.error(err.response?.data?.message || "Couldn't save product.");
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <Modal open={open} onClose={onClose} title={isEdit ? "Edit Product" : "Add Product"} size="lg">
      {!isEdit && (
        <Tabs
          className="mb-4"
          value={tab}
          onChange={setTab}
          tabs={[
            { value: "catalog", label: "From Catalog" },
            { value: "details", label: "New Product" },
          ]}
        />
      )}

      {tab === "catalog" && !isEdit ? (
        <div className="flex flex-col gap-3">
          <div className="relative">
            <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-subtext" />
            <input
              type="text"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="Search products by name or brand..."
              className={`${inputClass} pl-9`}
            />
          </div>

          {catalogLoading ? (
            <div className="flex items-center justify-center py-8">
              <Loader2 className="animate-spin text-wine" size={24} />
            </div>
          ) : (
            <div className="max-h-56 overflow-y-auto flex flex-col gap-1 border border-divider rounded-xl p-2">
              {filteredCatalog.slice(0, 50).map((p) => (
                <button
                  key={p._id}
                  onClick={() => selectCatalogProduct(p)}
                  className={`flex items-center gap-3 p-2 rounded-xl text-left transition-colors ${
                    selectedProduct?._id === p._id ? "bg-soft-pink" : "hover:bg-beige"
                  }`}
                >
                  {p.imageUrl ? (
                    <img src={resolveImageUrl(p.imageUrl)} alt="" className="h-10 w-10 rounded-lg object-cover" />
                  ) : (
                    <div className="h-10 w-10 rounded-lg bg-soft-pink" />
                  )}
                  <div className="min-w-0">
                    <p className="text-sm font-medium text-ink truncate">{p.name}</p>
                    <p className="text-xs text-subtext truncate">{p.brand}</p>
                  </div>
                </button>
              ))}
              {filteredCatalog.length === 0 && (
                <p className="text-sm text-subtext text-center py-4">No products found.</p>
              )}
            </div>
          )}

          {selectedProduct && (
            <div className="grid grid-cols-2 gap-3">
              <FormField label="Your Price">
                <input type="number" min="0" step="0.01" value={form.price} onChange={handleField("price")} className={inputClass} />
              </FormField>
              <FormField label="Currency">
                <input type="text" value={form.currency} onChange={handleField("currency")} className={inputClass} />
              </FormField>
              <FormField label="Stock Count">
                <input type="number" min="0" value={form.stockCount} onChange={handleField("stockCount")} className={inputClass} />
              </FormField>
            </div>
          )}

          <Button onClick={handleAddFromCatalog} disabled={submitting || !selectedProduct} className="self-end">
            {submitting ? "Adding..." : "Add to Store"}
          </Button>
        </div>
      ) : (
        <div className="flex flex-col gap-3">
          <div className="flex items-center gap-4">
            <div className="h-20 w-20 rounded-xl overflow-hidden bg-soft-pink shrink-0 flex items-center justify-center">
              {imagePreview ? (
                <img src={imagePreview} alt="" className="h-full w-full object-cover" />
              ) : (
                <Upload size={20} className="text-wine/50" />
              )}
            </div>
            <label className="cursor-pointer">
              <span className="inline-flex items-center gap-2 px-4 py-2 rounded-full text-sm font-semibold bg-soft-pink text-wine hover:bg-dusty-rose-light transition-all">
                <Upload size={14} /> Upload Image
              </span>
              <input type="file" accept="image/*" className="hidden" onChange={handleImageChange} />
            </label>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
            <FormField label="Product Name">
              <input type="text" value={form.name} onChange={handleField("name")} className={inputClass} />
            </FormField>
            <FormField label="Brand">
              <input type="text" value={form.brand} onChange={handleField("brand")} className={inputClass} />
            </FormField>
            <FormField label="Category">
              <input type="text" value={form.category} onChange={handleField("category")} className={inputClass} />
            </FormField>
            <FormField label="Discount %">
              <input type="number" min="0" max="100" value={form.discountPercent} onChange={handleField("discountPercent")} className={inputClass} />
            </FormField>
            <FormField label="Price">
              <input type="number" min="0" step="0.01" value={form.price} onChange={handleField("price")} className={inputClass} />
            </FormField>
            <FormField label="Currency">
              <input type="text" value={form.currency} onChange={handleField("currency")} className={inputClass} />
            </FormField>
            <FormField label="Stock Count">
              <input type="number" min="0" value={form.stockCount} onChange={handleField("stockCount")} className={inputClass} />
            </FormField>
          </div>

          <FormField label="Short Description">
            <textarea
              value={form.shortDescription}
              onChange={handleField("shortDescription")}
              rows={3}
              className={inputClass}
            />
          </FormField>

          <Button onClick={handleSaveDetails} disabled={submitting} className="self-end">
            {submitting ? "Saving..." : isEdit ? "Save Changes" : "Create & Add to Store"}
          </Button>
        </div>
      )}
    </Modal>
  );
}
