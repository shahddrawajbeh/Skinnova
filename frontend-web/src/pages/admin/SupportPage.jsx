import { useEffect, useState } from "react";
import { Loader2, Inbox, Trash2, Eye, EyeOff, Check, X, Search } from "lucide-react";
import Card from "../../components/common/Card";
import Button from "../../components/common/Button";
import Modal from "../../components/common/Modal";
import ConfirmDialog from "../../components/common/ConfirmDialog";
import EmptyState from "../../components/common/EmptyState";
import Pagination from "../../components/common/Pagination";
import Tabs from "../../components/common/Tabs";
import { inputClass } from "../../components/common/AuthLayout";
import { adminService } from "../../services/adminService";
import { useToast } from "../../context/ToastContext";
import { resolveImageUrl } from "../../services/api";
import { timeAgo } from "../../utils/format";

const PAGE_SIZE = 10;

const TABS = [
  { value: "messages", label: "Messages" },
  { value: "store-reports", label: "Store Reports" },
  { value: "group-posts", label: "Group Posts" },
];

const MESSAGE_STATUS_STYLES = {
  open: { bg: "bg-soft-pink", fg: "text-wine", label: "Open" },
  in_progress: { bg: "bg-gold/20", fg: "text-wine-dark", label: "In Progress" },
  resolved: { bg: "bg-green-100", fg: "text-green-700", label: "Resolved" },
  dismissed: { bg: "bg-gray-100", fg: "text-subtext", label: "Dismissed" },
};

const REPORT_STATUS_STYLES = {
  pending: { bg: "bg-soft-pink", fg: "text-wine", label: "Pending" },
  reviewed: { bg: "bg-green-100", fg: "text-green-700", label: "Reviewed" },
  dismissed: { bg: "bg-gray-100", fg: "text-subtext", label: "Dismissed" },
};

const APPROVAL_STATUS_STYLES = {
  pending: { bg: "bg-soft-pink", fg: "text-wine", label: "Pending" },
  approved: { bg: "bg-green-100", fg: "text-green-700", label: "Approved" },
  rejected: { bg: "bg-gray-100", fg: "text-danger", label: "Rejected" },
};

function Badge({ style }) {
  return <span className={`text-xs font-semibold px-2.5 py-1 rounded-full ${style.bg} ${style.fg}`}>{style.label}</span>;
}

function MessagesTab() {
  const toast = useToast();
  const [messages, setMessages] = useState([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [loading, setLoading] = useState(true);
  const [type, setType] = useState("");
  const [status, setStatus] = useState("");
  const [selected, setSelected] = useState(null);
  const [statusValue, setStatusValue] = useState("");
  const [adminNote, setAdminNote] = useState("");
  const [saving, setSaving] = useState(false);
  const [deleting, setDeleting] = useState(null);

  const load = () => {
    setLoading(true);
    const params = { page, limit: PAGE_SIZE };
    if (type) params.type = type;
    if (status) params.status = status;
    adminService
      .fetchSupportMessages(params)
      .then((data) => {
        setMessages(data.messages || []);
        setTotal(data.total || 0);
      })
      .catch(() => toast.error("Couldn't load support messages."))
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    load();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [type, status, page]);

  const openMessage = (msg) => {
    setSelected(msg);
    setStatusValue(msg.status);
    setAdminNote(msg.adminNote || "");
  };

  const handleSave = async () => {
    if (!selected) return;
    setSaving(true);
    try {
      const updated = await adminService.updateSupportMessageStatus(selected._id, statusValue, adminNote);
      setMessages((list) => list.map((m) => (m._id === updated._id ? updated : m)));
      toast.success("Message updated.");
      setSelected(null);
    } catch {
      toast.error("Couldn't update message.");
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async () => {
    if (!deleting) return;
    setSaving(true);
    try {
      await adminService.deleteSupportMessage(deleting._id);
      setMessages((list) => list.filter((m) => m._id !== deleting._id));
      setTotal((t) => Math.max(0, t - 1));
      toast.success("Message deleted.");
      setDeleting(null);
      setSelected(null);
    } catch {
      toast.error("Couldn't delete message.");
    } finally {
      setSaving(false);
    }
  };

  const totalPages = Math.max(1, Math.ceil(total / PAGE_SIZE));

  return (
    <div className="flex flex-col gap-4">
      <div className="flex flex-wrap gap-3">
        <select
          value={type}
          onChange={(e) => {
            setType(e.target.value);
            setPage(1);
          }}
          className={`${inputClass} sm:max-w-[160px]`}
        >
          <option value="">All types</option>
          <option value="contact">Contact</option>
          <option value="bug">Bug Report</option>
        </select>
        <select
          value={status}
          onChange={(e) => {
            setStatus(e.target.value);
            setPage(1);
          }}
          className={`${inputClass} sm:max-w-[180px]`}
        >
          <option value="">All statuses</option>
          {Object.entries(MESSAGE_STATUS_STYLES).map(([value, s]) => (
            <option key={value} value={value}>
              {s.label}
            </option>
          ))}
        </select>
      </div>

      {loading ? (
        <div className="flex items-center justify-center py-16">
          <Loader2 className="animate-spin text-wine" size={28} />
        </div>
      ) : messages.length === 0 ? (
        <EmptyState icon={Inbox} title="No messages found" message="User contact and bug report messages will appear here." />
      ) : (
        <div className="flex flex-col gap-2">
          {messages.map((m) => (
            <Card key={m._id} className="p-4 flex items-start gap-3 cursor-pointer" onClick={() => openMessage(m)}>
              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-2 flex-wrap">
                  <p className="font-semibold text-ink">{m.subject}</p>
                  <Badge style={MESSAGE_STATUS_STYLES[m.status] || MESSAGE_STATUS_STYLES.open} />
                  <span className="text-xs text-subtext uppercase">{m.type}</span>
                </div>
                <p className="text-sm text-subtext line-clamp-2 mt-1">{m.message}</p>
                <p className="text-xs text-subtext mt-1">
                  {m.userName || m.email || "Anonymous"} · {timeAgo(m.createdAt)}
                </p>
              </div>
            </Card>
          ))}
        </div>
      )}

      <Pagination page={page} totalPages={totalPages} onChange={setPage} />

      <Modal open={!!selected} onClose={() => setSelected(null)} title={selected?.subject} size="md">
        {selected && (
          <div className="flex flex-col gap-4">
            <div>
              <p className="text-xs text-subtext mb-1">
                From {selected.userName || "Anonymous"} {selected.email && `(${selected.email})`}
              </p>
              <p className="text-sm text-ink whitespace-pre-wrap">{selected.message}</p>
            </div>
            <div>
              <label className="block text-xs text-subtext mb-1">Status</label>
              <select value={statusValue} onChange={(e) => setStatusValue(e.target.value)} className={inputClass}>
                {Object.entries(MESSAGE_STATUS_STYLES).map(([value, s]) => (
                  <option key={value} value={value}>
                    {s.label}
                  </option>
                ))}
              </select>
            </div>
            <div>
              <label className="block text-xs text-subtext mb-1">Admin note (optional)</label>
              <textarea
                value={adminNote}
                onChange={(e) => setAdminNote(e.target.value)}
                rows={3}
                className={inputClass}
              />
            </div>
            <div className="flex justify-between gap-2">
              <Button variant="outline" className="!border-danger !text-danger hover:!bg-danger hover:!text-white" onClick={() => setDeleting(selected)}>
                <Trash2 size={14} /> Delete
              </Button>
              <Button onClick={handleSave} disabled={saving}>
                {saving ? "Saving..." : "Save"}
              </Button>
            </div>
          </div>
        )}
      </Modal>

      <ConfirmDialog
        open={!!deleting}
        onClose={() => setDeleting(null)}
        onConfirm={handleDelete}
        title="Delete Message"
        message="This message will be permanently deleted. Continue?"
        confirmLabel="Delete"
        variant="primary"
        loading={saving}
      />
    </div>
  );
}

function StoreReportsTab() {
  const toast = useToast();
  const [reports, setReports] = useState([]);
  const [loading, setLoading] = useState(true);
  const [status, setStatus] = useState("pending");
  const [action, setAction] = useState(null);
  const [adminNote, setAdminNote] = useState("");
  const [saving, setSaving] = useState(false);

  const load = () => {
    setLoading(true);
    const params = {};
    if (status) params.status = status;
    adminService
      .fetchStoreReports(params)
      .then(setReports)
      .catch(() => toast.error("Couldn't load store reports."))
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    load();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [status]);

  const handleAction = async () => {
    if (!action) return;
    setSaving(true);
    try {
      if (action.type === "reviewed") {
        await adminService.markStoreReportReviewed(action.report._id, adminNote);
      } else {
        await adminService.markStoreReportDismissed(action.report._id, adminNote);
      }
      toast.success(action.type === "reviewed" ? "Report marked as reviewed." : "Report dismissed.");
      setReports((list) => list.filter((r) => r._id !== action.report._id));
      setAction(null);
      setAdminNote("");
    } catch {
      toast.error("Couldn't update report.");
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="flex flex-col gap-4">
      <div className="flex flex-wrap gap-3">
        <select value={status} onChange={(e) => setStatus(e.target.value)} className={`${inputClass} sm:max-w-[180px]`}>
          <option value="">All statuses</option>
          {Object.entries(REPORT_STATUS_STYLES).map(([value, s]) => (
            <option key={value} value={value}>
              {s.label}
            </option>
          ))}
        </select>
      </div>

      {loading ? (
        <div className="flex items-center justify-center py-16">
          <Loader2 className="animate-spin text-wine" size={28} />
        </div>
      ) : reports.length === 0 ? (
        <EmptyState icon={Inbox} title="No store reports found" message="Reports submitted by users about stores will appear here." />
      ) : (
        <div className="flex flex-col gap-2">
          {reports.map((r) => (
            <Card key={r._id} className="p-4 flex flex-col gap-2" hover={false}>
              <div className="flex items-center gap-2 flex-wrap">
                <p className="font-semibold text-ink">{r.storeName || "Unknown store"}</p>
                <Badge style={REPORT_STATUS_STYLES[r.status] || REPORT_STATUS_STYLES.pending} />
              </div>
              <p className="text-sm text-ink">
                <span className="font-medium">Reason:</span> {r.reason}
              </p>
              {r.details && <p className="text-sm text-subtext">{r.details}</p>}
              {r.adminNote && (
                <p className="text-xs text-subtext italic">Admin note: {r.adminNote}</p>
              )}
              <p className="text-xs text-subtext">
                Reported by {r.userName || "a user"} · {timeAgo(r.createdAt)}
              </p>
              {r.status === "pending" && (
                <div className="flex gap-2 mt-1">
                  <Button size="sm" onClick={() => setAction({ type: "reviewed", report: r })}>
                    <Check size={14} /> Mark Reviewed
                  </Button>
                  <Button variant="secondary" size="sm" onClick={() => setAction({ type: "dismissed", report: r })}>
                    <X size={14} /> Dismiss
                  </Button>
                </div>
              )}
            </Card>
          ))}
        </div>
      )}

      <Modal
        open={!!action}
        onClose={() => {
          setAction(null);
          setAdminNote("");
        }}
        title={action?.type === "reviewed" ? "Mark Report as Reviewed" : "Dismiss Report"}
        size="sm"
      >
        <p className="text-sm text-subtext mb-3">
          {action?.type === "reviewed"
            ? `Mark the report on "${action?.report?.storeName}" as reviewed?`
            : `Dismiss the report on "${action?.report?.storeName}"?`}
        </p>
        <textarea
          className={`${inputClass} min-h-[90px] mb-4`}
          placeholder="Admin note (optional)"
          value={adminNote}
          onChange={(e) => setAdminNote(e.target.value)}
        />
        <div className="flex justify-end gap-2">
          <Button variant="ghost" onClick={() => setAction(null)} disabled={saving}>
            Cancel
          </Button>
          <Button onClick={handleAction} disabled={saving}>
            {saving ? "Please wait..." : "Confirm"}
          </Button>
        </div>
      </Modal>
    </div>
  );
}

function GroupPostsTab() {
  const toast = useToast();
  const [posts, setPosts] = useState([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [loading, setLoading] = useState(true);
  const [approvalStatus, setApprovalStatus] = useState("pending");
  const [search, setSearch] = useState("");
  const [actionLoading, setActionLoading] = useState(null);

  const load = () => {
    setLoading(true);
    const params = { page, limit: PAGE_SIZE };
    if (approvalStatus) params.approvalStatus = approvalStatus;
    if (search) params.search = search;
    adminService
      .fetchGroupPosts(params)
      .then((data) => {
        setPosts(data.posts || []);
        setTotal(data.total || 0);
      })
      .catch(() => toast.error("Couldn't load group posts."))
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    const t = setTimeout(load, 300);
    return () => clearTimeout(t);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [approvalStatus, search, page]);

  const handleToggleHidden = async (post) => {
    setActionLoading(post._id);
    try {
      const { isHidden } = await adminService.toggleGroupPostHidden(post._id);
      setPosts((list) => list.map((p) => (p._id === post._id ? { ...p, isHidden } : p)));
      toast.success(isHidden ? "Post hidden." : "Post unhidden.");
    } catch {
      toast.error("Couldn't update post.");
    } finally {
      setActionLoading(null);
    }
  };

  const handleApproval = async (post, status) => {
    setActionLoading(post._id);
    try {
      await adminService.setGroupPostApprovalStatus(post._id, status);
      if (approvalStatus && approvalStatus !== "" ) {
        setPosts((list) => list.filter((p) => p._id !== post._id));
        setTotal((t) => Math.max(0, t - 1));
      } else {
        setPosts((list) => list.map((p) => (p._id === post._id ? { ...p, approvalStatus: status } : p)));
      }
      toast.success(status === "approved" ? "Post approved." : "Post rejected.");
    } catch {
      toast.error("Couldn't update post.");
    } finally {
      setActionLoading(null);
    }
  };

  const totalPages = Math.max(1, Math.ceil(total / PAGE_SIZE));

  return (
    <div className="flex flex-col gap-4">
      <div className="flex flex-wrap gap-3">
        <select
          value={approvalStatus}
          onChange={(e) => {
            setApprovalStatus(e.target.value);
            setPage(1);
          }}
          className={`${inputClass} sm:max-w-[180px]`}
        >
          <option value="">All</option>
          {Object.entries(APPROVAL_STATUS_STYLES).map(([value, s]) => (
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
            placeholder="Search posts..."
            className={`${inputClass} pl-9`}
          />
        </div>
      </div>

      {loading ? (
        <div className="flex items-center justify-center py-16">
          <Loader2 className="animate-spin text-wine" size={28} />
        </div>
      ) : posts.length === 0 ? (
        <EmptyState icon={Inbox} title="No group posts found" message="Posts awaiting moderation will appear here." />
      ) : (
        <div className="flex flex-col gap-2">
          {posts.map((p) => (
            <Card key={p._id} className="p-4 flex items-start gap-3" hover={false}>
              {p.images?.[0] && (
                <img src={resolveImageUrl(p.images[0])} alt="" className="h-16 w-16 rounded-xl object-cover shrink-0" />
              )}
              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-2 flex-wrap">
                  <p className="font-semibold text-ink">{p.userName}</p>
                  <span className="text-xs text-subtext uppercase">{p.postType}</span>
                  <Badge style={APPROVAL_STATUS_STYLES[p.approvalStatus] || APPROVAL_STATUS_STYLES.pending} />
                  {p.isHidden && <Badge style={{ bg: "bg-gray-100", fg: "text-subtext", label: "Hidden" }} />}
                </div>
                <p className="text-sm text-subtext line-clamp-2 mt-1">{p.content}</p>
                <p className="text-xs text-subtext mt-1">
                  {p.groupTitle && `${p.groupTitle} · `}
                  {timeAgo(p.createdAt)}
                </p>
                <div className="flex gap-2 mt-2">
                  {p.approvalStatus === "pending" && (
                    <>
                      <Button size="sm" onClick={() => handleApproval(p, "approved")} disabled={actionLoading === p._id}>
                        <Check size={14} /> Approve
                      </Button>
                      <Button variant="secondary" size="sm" onClick={() => handleApproval(p, "rejected")} disabled={actionLoading === p._id}>
                        <X size={14} /> Reject
                      </Button>
                    </>
                  )}
                  <Button variant="outline" size="sm" onClick={() => handleToggleHidden(p)} disabled={actionLoading === p._id}>
                    {p.isHidden ? <Eye size={14} /> : <EyeOff size={14} />}
                    {p.isHidden ? "Unhide" : "Hide"}
                  </Button>
                </div>
              </div>
            </Card>
          ))}
        </div>
      )}

      <Pagination page={page} totalPages={totalPages} onChange={setPage} />
    </div>
  );
}

export default function SupportPage() {
  const [tab, setTab] = useState("messages");

  return (
    <div className="flex flex-col gap-5">
      <div className="animate-fade-slide-in">
        <h2 className="font-display text-2xl font-bold text-ink">Support</h2>
        <p className="text-sm text-subtext mt-1">Manage user messages, store reports, and community moderation.</p>
      </div>

      <Tabs tabs={TABS} value={tab} onChange={setTab} />

      {tab === "messages" && <MessagesTab />}
      {tab === "store-reports" && <StoreReportsTab />}
      {tab === "group-posts" && <GroupPostsTab />}
    </div>
  );
}
