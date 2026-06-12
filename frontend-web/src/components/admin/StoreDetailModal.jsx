import { useEffect, useState } from "react";
import { Loader2, Trash2, Star, Users as UsersIcon } from "lucide-react";
import Modal from "../common/Modal";
import Button from "../common/Button";
import ConfirmDialog from "../common/ConfirmDialog";
import { inputClass } from "../common/AuthLayout";
import { adminService } from "../../services/adminService";
import { useToast } from "../../context/ToastContext";
import { resolveImageUrl } from "../../services/api";

const APPROVAL_STYLES = {
  pending: "bg-amber-50 text-amber-600",
  approved: "bg-emerald-50 text-emerald-600",
  rejected: "bg-red-50 text-red-600",
};

export default function StoreDetailModal({ storeId, onClose, onChange }) {
  const toast = useToast();
  const [store, setStore] = useState(null);
  const [loading, setLoading] = useState(false);
  const [form, setForm] = useState(null);
  const [badge, setBadge] = useState({ verificationLevel: "standard", isVerified: false });
  const [savingForm, setSavingForm] = useState(false);
  const [savingBadge, setSavingBadge] = useState(false);
  const [pendingAction, setPendingAction] = useState(null);
  const [actionLoading, setActionLoading] = useState(false);

  useEffect(() => {
    if (!storeId) return;
    setLoading(true);
    adminService
      .fetchStore(storeId)
      .then((data) => {
        setStore(data);
        setForm({
          storeName: data.storeName || "",
          city: data.city || "",
          phone: data.phone || "",
          address: data.address || "",
          description: data.description || "",
        });
        setBadge({
          verificationLevel: data.verificationLevel || "standard",
          isVerified: !!data.isVerified,
        });
      })
      .catch(() => toast.error("Couldn't load store."))
      .finally(() => setLoading(false));
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [storeId]);

  const handleSaveForm = async () => {
    if (!store) return;
    setSavingForm(true);
    try {
      const updated = await adminService.updateStore(store._id, form);
      setStore(updated);
      toast.success("Store updated.");
      onChange?.();
    } catch {
      toast.error("Couldn't update store.");
    } finally {
      setSavingForm(false);
    }
  };

  const handleSaveBadge = async () => {
    if (!store) return;
    setSavingBadge(true);
    try {
      const updated = await adminService.setStoreBadge(store._id, badge);
      setStore(updated);
      toast.success("Verification updated.");
      onChange?.();
    } catch {
      toast.error("Couldn't update verification.");
    } finally {
      setSavingBadge(false);
    }
  };

  const handleToggleActive = async () => {
    if (!store) return;
    setActionLoading(true);
    try {
      const res = await adminService.toggleStoreActive(store._id);
      setStore((s) => ({ ...s, isActive: res.isActive }));
      toast.success(res.isActive ? "Store activated." : "Store deactivated.");
      setPendingAction(null);
      onChange?.();
    } catch {
      toast.error("Couldn't update store status.");
    } finally {
      setActionLoading(false);
    }
  };

  const handleDelete = async () => {
    if (!store) return;
    setActionLoading(true);
    try {
      await adminService.deleteStore(store._id);
      toast.success("Store deleted.");
      setPendingAction(null);
      onChange?.();
      onClose();
    } catch {
      toast.error("Couldn't delete store.");
    } finally {
      setActionLoading(false);
    }
  };

  return (
    <>
      <Modal open={!!storeId} onClose={onClose} title="Store Details" size="xl">
        {loading || !store ? (
          <div className="flex items-center justify-center py-12">
            <Loader2 className="animate-spin text-wine" size={28} />
          </div>
        ) : (
          <div className="flex flex-col gap-5">
            <div className="flex items-center gap-4">
              {store.logoUrl ? (
                <img src={resolveImageUrl(store.logoUrl)} alt="" className="h-16 w-16 rounded-2xl object-cover" />
              ) : (
                <div className="h-16 w-16 rounded-2xl bg-soft-pink flex items-center justify-center text-wine font-bold text-xl">
                  {store.storeName?.[0]?.toUpperCase() || "S"}
                </div>
              )}
              <div className="min-w-0 flex-1">
                <p className="font-display text-lg font-bold text-ink truncate">{store.storeName}</p>
                <p className="text-sm text-subtext truncate">
                  {store.sellerId?.fullName} · {store.sellerId?.email}
                </p>
              </div>
              <div className="flex flex-col items-end gap-1 shrink-0">
                <span className={`inline-block text-xs font-semibold px-2.5 py-1 rounded-full ${APPROVAL_STYLES[store.approvalStatus] || APPROVAL_STYLES.pending}`}>
                  {store.approvalStatus}
                </span>
                <span className={`inline-block text-xs font-semibold px-2.5 py-1 rounded-full ${store.isActive === false ? "bg-red-50 text-red-600" : "bg-emerald-50 text-emerald-600"}`}>
                  {store.isActive === false ? "Inactive" : "Active"}
                </span>
              </div>
            </div>

            {store.approvalStatus === "rejected" && store.rejectionReason && (
              <div className="rounded-xl bg-red-50 text-red-600 text-sm px-3 py-2.5">
                <span className="font-semibold">Rejection reason: </span>
                {store.rejectionReason}
              </div>
            )}

            <div className="grid grid-cols-2 sm:grid-cols-3 gap-3">
              <div className="rounded-xl bg-soft-pink/50 px-3 py-2.5 flex items-center gap-2">
                <Star size={16} className="text-gold" />
                <div>
                  <p className="text-xs text-subtext">Rating</p>
                  <p className="text-sm font-semibold text-ink">{store.rating?.toFixed(1) || "0.0"}</p>
                </div>
              </div>
              <div className="rounded-xl bg-soft-pink/50 px-3 py-2.5 flex items-center gap-2">
                <UsersIcon size={16} className="text-wine" />
                <div>
                  <p className="text-xs text-subtext">Followers</p>
                  <p className="text-sm font-semibold text-ink">{store.followersCount || 0}</p>
                </div>
              </div>
              <div className="rounded-xl bg-soft-pink/50 px-3 py-2.5">
                <p className="text-xs text-subtext">Joined</p>
                <p className="text-sm font-semibold text-ink">
                  {store.createdAt ? new Date(store.createdAt).toLocaleDateString() : "—"}
                </p>
              </div>
            </div>

            <div>
              <h4 className="font-semibold text-ink mb-2">Store Info</h4>
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs text-subtext mb-1">Store Name</label>
                  <input
                    className={inputClass}
                    value={form.storeName}
                    onChange={(e) => setForm((f) => ({ ...f, storeName: e.target.value }))}
                  />
                </div>
                <div>
                  <label className="block text-xs text-subtext mb-1">City</label>
                  <input
                    className={inputClass}
                    value={form.city}
                    onChange={(e) => setForm((f) => ({ ...f, city: e.target.value }))}
                  />
                </div>
                <div>
                  <label className="block text-xs text-subtext mb-1">Phone</label>
                  <input
                    className={inputClass}
                    value={form.phone}
                    onChange={(e) => setForm((f) => ({ ...f, phone: e.target.value }))}
                  />
                </div>
                <div>
                  <label className="block text-xs text-subtext mb-1">Address</label>
                  <input
                    className={inputClass}
                    value={form.address}
                    onChange={(e) => setForm((f) => ({ ...f, address: e.target.value }))}
                  />
                </div>
                <div className="sm:col-span-2">
                  <label className="block text-xs text-subtext mb-1">Description</label>
                  <textarea
                    className={`${inputClass} min-h-[80px]`}
                    value={form.description}
                    onChange={(e) => setForm((f) => ({ ...f, description: e.target.value }))}
                  />
                </div>
              </div>
              <div className="mt-3">
                <Button size="sm" onClick={handleSaveForm} disabled={savingForm}>
                  {savingForm ? "Saving..." : "Save Changes"}
                </Button>
              </div>
            </div>

            <div>
              <h4 className="font-semibold text-ink mb-2">Verification</h4>
              <div className="flex flex-wrap items-end gap-3">
                <div>
                  <label className="block text-xs text-subtext mb-1">Verification Level</label>
                  <select
                    className={inputClass}
                    value={badge.verificationLevel}
                    onChange={(e) => setBadge((b) => ({ ...b, verificationLevel: e.target.value }))}
                  >
                    <option value="standard">Standard</option>
                    <option value="premium">Premium</option>
                    <option value="trusted">Trusted</option>
                  </select>
                </div>
                <label className="flex items-center gap-2 text-sm text-ink pb-2.5">
                  <input
                    type="checkbox"
                    checked={badge.isVerified}
                    onChange={(e) => setBadge((b) => ({ ...b, isVerified: e.target.checked }))}
                  />
                  Verified
                </label>
                <Button size="sm" variant="secondary" onClick={handleSaveBadge} disabled={savingBadge}>
                  {savingBadge ? "Saving..." : "Save"}
                </Button>
              </div>
            </div>

            <div className="flex flex-wrap items-center justify-between gap-2 pt-2 border-t border-divider">
              <Button
                variant="secondary"
                size="sm"
                onClick={() => setPendingAction("toggle-active")}
                disabled={actionLoading}
              >
                {store.isActive === false ? "Activate" : "Deactivate"}
              </Button>
              <Button
                variant="outline"
                size="sm"
                className="!border-danger !text-danger hover:!bg-danger hover:!text-white"
                onClick={() => setPendingAction("delete")}
                disabled={actionLoading}
              >
                <Trash2 size={14} /> Delete Store
              </Button>
            </div>
          </div>
        )}
      </Modal>

      <ConfirmDialog
        open={pendingAction === "toggle-active"}
        onClose={() => setPendingAction(null)}
        onConfirm={handleToggleActive}
        title={store?.isActive === false ? "Activate Store" : "Deactivate Store"}
        message={
          store?.isActive === false
            ? `Reactivate "${store?.storeName}"? It will become visible to customers again.`
            : `Deactivate "${store?.storeName}"? It will be hidden from customers.`
        }
        confirmLabel={store?.isActive === false ? "Activate" : "Deactivate"}
        loading={actionLoading}
      />

      <ConfirmDialog
        open={pendingAction === "delete"}
        onClose={() => setPendingAction(null)}
        onConfirm={handleDelete}
        title="Delete Store"
        message={`Permanently delete "${store?.storeName}"? This cannot be undone.`}
        confirmLabel="Delete"
        loading={actionLoading}
      />
    </>
  );
}
