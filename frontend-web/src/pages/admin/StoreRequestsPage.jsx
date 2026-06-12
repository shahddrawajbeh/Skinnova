import { useEffect, useState } from "react";
import { Loader2, Inbox, MapPin, Check, X } from "lucide-react";
import Card from "../../components/common/Card";
import Button from "../../components/common/Button";
import Modal from "../../components/common/Modal";
import ConfirmDialog from "../../components/common/ConfirmDialog";
import EmptyState from "../../components/common/EmptyState";
import { inputClass } from "../../components/common/AuthLayout";
import { adminService } from "../../services/adminService";
import { useToast } from "../../context/ToastContext";
import { resolveImageUrl } from "../../services/api";
import { timeAgo } from "../../utils/format";
import StoreDetailModal from "../../components/admin/StoreDetailModal";

export default function StoreRequestsPage() {
  const toast = useToast();
  const [stores, setStores] = useState([]);
  const [loading, setLoading] = useState(true);
  const [selectedId, setSelectedId] = useState(null);
  const [approving, setApproving] = useState(null);
  const [rejecting, setRejecting] = useState(null);
  const [rejectionReason, setRejectionReason] = useState("");
  const [actionLoading, setActionLoading] = useState(false);

  const load = () => {
    setLoading(true);
    adminService
      .fetchPendingStores()
      .then(setStores)
      .catch(() => toast.error("Couldn't load store requests."))
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    load();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const handleApprove = async () => {
    if (!approving) return;
    setActionLoading(true);
    try {
      await adminService.approveStore(approving._id);
      toast.success(`"${approving.storeName}" approved.`);
      setStores((list) => list.filter((s) => s._id !== approving._id));
      setApproving(null);
    } catch {
      toast.error("Couldn't approve store.");
    } finally {
      setActionLoading(false);
    }
  };

  const handleReject = async () => {
    if (!rejecting) return;
    setActionLoading(true);
    try {
      await adminService.rejectStore(rejecting._id, rejectionReason);
      toast.success(`"${rejecting.storeName}" rejected.`);
      setStores((list) => list.filter((s) => s._id !== rejecting._id));
      setRejecting(null);
      setRejectionReason("");
    } catch {
      toast.error("Couldn't reject store.");
    } finally {
      setActionLoading(false);
    }
  };

  return (
    <div className="flex flex-col gap-5">
      <div className="animate-fade-slide-in">
        <h2 className="font-display text-2xl font-bold text-ink">Store Requests</h2>
        <p className="text-sm text-subtext mt-1">Review and approve new store applications.</p>
      </div>

      {loading ? (
        <div className="flex items-center justify-center py-24">
          <Loader2 className="animate-spin text-wine" size={32} />
        </div>
      ) : stores.length === 0 ? (
        <EmptyState icon={Inbox} title="No pending store requests" message="New store applications will appear here." />
      ) : (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
          {stores.map((s, i) => (
            <Card key={s._id} className="p-4 flex flex-col gap-3 animate-pop-in" style={{ animationDelay: `${Math.min(i, 11) * 30}ms` }}>
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
              <div className="text-xs text-subtext">
                <p className="truncate">{s.sellerId?.fullName} · {s.sellerId?.email}</p>
                <p>Submitted {timeAgo(s.createdAt)}</p>
              </div>
              <div className="flex items-center gap-2 mt-1">
                <Button variant="secondary" size="sm" className="flex-1" onClick={() => setSelectedId(s._id)}>
                  View
                </Button>
                <Button size="sm" className="flex-1" onClick={() => setApproving(s)}>
                  <Check size={14} /> Approve
                </Button>
                <button
                  onClick={() => {
                    setRejecting(s);
                    setRejectionReason("");
                  }}
                  title="Reject"
                  className="p-2 rounded-full text-danger hover:bg-soft-pink transition-all"
                >
                  <X size={16} />
                </button>
              </div>
            </Card>
          ))}
        </div>
      )}

      {selectedId && (
        <StoreDetailModal storeId={selectedId} onClose={() => setSelectedId(null)} onChange={load} />
      )}

      <ConfirmDialog
        open={!!approving}
        onClose={() => setApproving(null)}
        onConfirm={handleApprove}
        title="Approve Store"
        message={`Approve "${approving?.storeName}"? The seller will be notified and gain access to the Store Owner dashboard.`}
        confirmLabel="Approve"
        loading={actionLoading}
      />

      <Modal open={!!rejecting} onClose={() => setRejecting(null)} title="Reject Store Request" size="sm">
        <p className="text-sm text-subtext mb-3">
          Reject &quot;{rejecting?.storeName}&quot;? Provide a reason for the seller.
        </p>
        <textarea
          className={`${inputClass} min-h-[90px] mb-4`}
          placeholder="Reason (optional)"
          value={rejectionReason}
          onChange={(e) => setRejectionReason(e.target.value)}
        />
        <div className="flex justify-end gap-2">
          <Button variant="ghost" onClick={() => setRejecting(null)} disabled={actionLoading}>
            Cancel
          </Button>
          <Button onClick={handleReject} disabled={actionLoading}>
            {actionLoading ? "Please wait..." : "Reject"}
          </Button>
        </div>
      </Modal>
    </div>
  );
}
