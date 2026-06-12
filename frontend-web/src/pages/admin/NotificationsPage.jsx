import { useEffect, useState } from "react";
import { Send } from "lucide-react";
import Card from "../../components/common/Card";
import Button from "../../components/common/Button";
import ConfirmDialog from "../../components/common/ConfirmDialog";
import Pagination from "../../components/common/Pagination";
import AdminReportTable from "../../components/admin/AdminReportTable";
import { inputClass } from "../../components/common/AuthLayout";
import { adminService } from "../../services/adminService";
import { useToast } from "../../context/ToastContext";
import { timeAgo } from "../../utils/format";

const PAGE_SIZE = 10;

const CONCERNS = [
  "Acne & Blemishes",
  "Blackheads",
  "Dark Spots",
  "Dryness",
  "Oiliness",
  "Redness",
  "Dullness",
  "Uneven Texture",
  "Visible Pores",
  "Dark Circles",
  "Puffiness",
  "Fine Lines & Wrinkles",
  "Loss of Firmness",
  "Sensitive Skin",
  "Dehydration",
];

const TARGET_OPTIONS = [
  { value: "all", label: "All Users" },
  { value: "user", label: "Specific User" },
  { value: "store", label: "Store Followers" },
  { value: "concern", label: "By Skin Concern" },
];

const TYPE_OPTIONS = [
  { value: "", label: "Default" },
  { value: "promo", label: "Promo" },
  { value: "general", label: "General" },
  { value: "admin", label: "Admin" },
  { value: "store", label: "Store" },
];

export default function NotificationsPage() {
  const toast = useToast();

  const [title, setTitle] = useState("");
  const [body, setBody] = useState("");
  const [imageUrl, setImageUrl] = useState("");
  const [targetLink, setTargetLink] = useState("");
  const [type, setType] = useState("");
  const [target, setTarget] = useState("all");
  const [userId, setUserId] = useState("");
  const [storeId, setStoreId] = useState("");
  const [concern, setConcern] = useState(CONCERNS[0]);
  const [confirmOpen, setConfirmOpen] = useState(false);
  const [sending, setSending] = useState(false);

  const [history, setHistory] = useState([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [loadingHistory, setLoadingHistory] = useState(true);

  const loadHistory = () => {
    setLoadingHistory(true);
    adminService
      .fetchSentNotifications({ page, limit: PAGE_SIZE })
      .then((data) => {
        setHistory(data.notifications || []);
        setTotal(data.total || 0);
      })
      .catch(() => toast.error("Couldn't load notification history."))
      .finally(() => setLoadingHistory(false));
  };

  useEffect(() => {
    loadHistory();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [page]);

  const totalPages = Math.max(1, Math.ceil(total / PAGE_SIZE));

  const isValid = () => {
    if (!title.trim() || !body.trim()) return false;
    if (target === "user" && !userId.trim()) return false;
    if (target === "store" && !storeId.trim()) return false;
    return true;
  };

  const confirmMessage = () => {
    switch (target) {
      case "all":
        return "This will send a push notification to ALL users on the platform. Are you sure?";
      case "user":
        return "Send this notification to the specified user?";
      case "store":
        return "Send this notification to all followers of the specified store?";
      case "concern":
        return `Send this notification to all users with the "${concern}" skin concern?`;
      default:
        return "Send this notification?";
    }
  };

  const handleSend = async () => {
    setSending(true);
    try {
      const payload = { title: title.trim(), body: body.trim() };
      if (imageUrl.trim()) payload.imageUrl = imageUrl.trim();
      if (targetLink.trim()) payload.targetLink = targetLink.trim();
      if (type) payload.type = type;

      let result;
      switch (target) {
        case "all":
          result = await adminService.sendToAllUsers(payload);
          break;
        case "user":
          result = await adminService.sendToUser(userId.trim(), payload);
          break;
        case "store":
          result = await adminService.sendToStoreFollowers(storeId.trim(), payload);
          break;
        case "concern":
          result = await adminService.sendBySkinConcern({ ...payload, concern });
          break;
        default:
          return;
      }
      toast.success(result?.message || "Notification sent.");
      setConfirmOpen(false);
      setTitle("");
      setBody("");
      setImageUrl("");
      setTargetLink("");
      setPage(1);
      loadHistory();
    } catch {
      toast.error("Couldn't send notification.");
    } finally {
      setSending(false);
    }
  };

  return (
    <div className="flex flex-col gap-6">
      <div className="animate-fade-slide-in">
        <h2 className="font-display text-2xl font-bold text-ink">Notifications</h2>
        <p className="text-sm text-subtext mt-1">Send push notifications to users.</p>
      </div>

      <Card className="p-5 flex flex-col gap-4 animate-fade-slide-in" hover={false}>
        <h3 className="font-semibold text-ink">Compose</h3>

        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <div>
            <label className="block text-xs text-subtext mb-1">Audience</label>
            <select value={target} onChange={(e) => setTarget(e.target.value)} className={inputClass}>
              {TARGET_OPTIONS.map((opt) => (
                <option key={opt.value} value={opt.value}>
                  {opt.label}
                </option>
              ))}
            </select>
          </div>
          <div>
            <label className="block text-xs text-subtext mb-1">Type (optional)</label>
            <select value={type} onChange={(e) => setType(e.target.value)} className={inputClass}>
              {TYPE_OPTIONS.map((opt) => (
                <option key={opt.value} value={opt.value}>
                  {opt.label}
                </option>
              ))}
            </select>
          </div>

          {target === "user" && (
            <div className="sm:col-span-2">
              <label className="block text-xs text-subtext mb-1">User ID</label>
              <input
                type="text"
                value={userId}
                onChange={(e) => setUserId(e.target.value)}
                placeholder="User's MongoDB ID"
                className={inputClass}
              />
            </div>
          )}
          {target === "store" && (
            <div className="sm:col-span-2">
              <label className="block text-xs text-subtext mb-1">Store ID</label>
              <input
                type="text"
                value={storeId}
                onChange={(e) => setStoreId(e.target.value)}
                placeholder="Store's MongoDB ID"
                className={inputClass}
              />
            </div>
          )}
          {target === "concern" && (
            <div className="sm:col-span-2">
              <label className="block text-xs text-subtext mb-1">Skin Concern</label>
              <select value={concern} onChange={(e) => setConcern(e.target.value)} className={inputClass}>
                {CONCERNS.map((c) => (
                  <option key={c} value={c}>
                    {c}
                  </option>
                ))}
              </select>
            </div>
          )}
        </div>

        <div>
          <label className="block text-xs text-subtext mb-1">Title</label>
          <input
            type="text"
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            placeholder="Notification title"
            className={inputClass}
          />
        </div>
        <div>
          <label className="block text-xs text-subtext mb-1">Message</label>
          <textarea
            value={body}
            onChange={(e) => setBody(e.target.value)}
            placeholder="Notification body"
            rows={3}
            className={inputClass}
          />
        </div>
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <div>
            <label className="block text-xs text-subtext mb-1">Image URL (optional)</label>
            <input
              type="text"
              value={imageUrl}
              onChange={(e) => setImageUrl(e.target.value)}
              placeholder="https://..."
              className={inputClass}
            />
          </div>
          <div>
            <label className="block text-xs text-subtext mb-1">Target Link (optional)</label>
            <input
              type="text"
              value={targetLink}
              onChange={(e) => setTargetLink(e.target.value)}
              placeholder="/shop/..."
              className={inputClass}
            />
          </div>
        </div>

        <div className="flex justify-end">
          <Button onClick={() => setConfirmOpen(true)} disabled={!isValid()}>
            <Send size={16} /> Send Notification
          </Button>
        </div>
      </Card>

      <div className="flex flex-col gap-3 animate-fade-slide-in">
        <h3 className="font-semibold text-ink">History</h3>
        <AdminReportTable
          columns={[
            { key: "title", label: "Title" },
            {
              key: "body",
              label: "Message",
              render: (r) => (r.body?.length > 60 ? `${r.body.slice(0, 60)}…` : r.body),
            },
            { key: "recipient", label: "Recipient", render: (r) => r.userId?.fullName || r.userId?.email || "—" },
            { key: "type", label: "Type" },
            { key: "createdAt", label: "Sent", render: (r) => timeAgo(r.createdAt) },
          ]}
          rows={history}
          loading={loadingHistory}
          emptyMessage="Notifications you send will appear here."
        />
        {totalPages > 1 && <Pagination page={page} totalPages={totalPages} onChange={setPage} />}
      </div>

      <ConfirmDialog
        open={confirmOpen}
        onClose={() => setConfirmOpen(false)}
        onConfirm={handleSend}
        title="Send Notification"
        message={confirmMessage()}
        confirmLabel="Send"
        loading={sending}
      />
    </div>
  );
}
