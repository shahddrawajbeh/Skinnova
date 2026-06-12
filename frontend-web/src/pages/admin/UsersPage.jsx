import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { Search, Loader2, User as UserIcon, Trash2 } from "lucide-react";
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
import { timeAgo } from "../../utils/format";

const PAGE_SIZE = 10;

const ROLE_OPTIONS = [
  { value: "", label: "All roles" },
  { value: "user", label: "User" },
  { value: "seller", label: "Seller" },
  { value: "admin", label: "Admin" },
];

const ROLE_STYLES = {
  user: "bg-soft-pink text-wine",
  seller: "bg-blue-50 text-blue-600",
  admin: "bg-gold/20 text-wine-dark",
};

export default function UsersPage() {
  const toast = useToast();
  const [users, setUsers] = useState([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [role, setRole] = useState("");
  const [page, setPage] = useState(1);

  const [selected, setSelected] = useState(null);
  const [detail, setDetail] = useState(null);
  const [detailLoading, setDetailLoading] = useState(false);
  const [pendingAction, setPendingAction] = useState(null);
  const [actionLoading, setActionLoading] = useState(false);

  const load = () => {
    setLoading(true);
    adminService
      .fetchUsers({ search: search || undefined, role: role || undefined, page, limit: PAGE_SIZE })
      .then((data) => {
        setUsers(data.users || []);
        setTotal(data.total || 0);
      })
      .catch(() => toast.error("Couldn't load users."))
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    const t = setTimeout(load, 300);
    return () => clearTimeout(t);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [search, role, page]);

  const openDetail = (user) => {
    setSelected(user);
    setDetail(null);
    setDetailLoading(true);
    adminService
      .fetchUser(user._id)
      .then(setDetail)
      .catch(() => toast.error("Couldn't load user details."))
      .finally(() => setDetailLoading(false));
  };

  const closeDetail = () => {
    setSelected(null);
    setDetail(null);
  };

  const handleToggleActive = async () => {
    if (!selected) return;
    setActionLoading(true);
    try {
      const res = await adminService.toggleUserActive(selected._id);
      toast.success(res.isActive ? "User activated." : "User deactivated.");
      setDetail((d) => (d ? { ...d, isActive: res.isActive } : d));
      setPendingAction(null);
      load();
    } catch {
      toast.error("Couldn't update user status.");
    } finally {
      setActionLoading(false);
    }
  };

  const handleRoleChange = async (newRole) => {
    if (!selected) return;
    setActionLoading(true);
    try {
      const updated = await adminService.updateUserRole(selected._id, newRole);
      toast.success("Role updated.");
      setDetail(updated);
      setPendingAction(null);
      load();
    } catch {
      toast.error("Couldn't update role.");
    } finally {
      setActionLoading(false);
    }
  };

  const handleDelete = async () => {
    if (!selected) return;
    setActionLoading(true);
    try {
      await adminService.deleteUser(selected._id);
      toast.success("User deleted.");
      setPendingAction(null);
      closeDetail();
      load();
    } catch {
      toast.error("Couldn't delete user.");
    } finally {
      setActionLoading(false);
    }
  };

  const totalPages = Math.max(1, Math.ceil(total / PAGE_SIZE));

  return (
    <div className="flex flex-col gap-5">
      <div className="flex flex-wrap items-center justify-between gap-3 animate-fade-slide-in">
        <div>
          <h2 className="font-display text-2xl font-bold text-ink">Users</h2>
          <p className="text-sm text-subtext mt-1">Manage user accounts, roles, and access.</p>
        </div>
        <Link to="/admin/reports?tab=users" className="text-sm font-semibold text-wine hover:underline">
          View detailed user report →
        </Link>
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
            placeholder="Search by name, email, phone..."
            className={`${inputClass} pl-9`}
          />
        </div>
        <select
          value={role}
          onChange={(e) => {
            setRole(e.target.value);
            setPage(1);
          }}
          className={`${inputClass} sm:max-w-[160px]`}
        >
          {ROLE_OPTIONS.map((opt) => (
            <option key={opt.value} value={opt.value}>
              {opt.label}
            </option>
          ))}
        </select>
      </div>

      {loading ? (
        <div className="flex items-center justify-center py-24">
          <Loader2 className="animate-spin text-wine" size={32} />
        </div>
      ) : users.length === 0 ? (
        <EmptyState icon={UserIcon} title="No users found" message="Try adjusting your search or filters." />
      ) : (
        <>
          <Card className="overflow-x-auto animate-fade-slide-in" hover={false}>
            <table className="w-full text-sm">
              <thead>
                <tr className="text-left text-xs text-subtext uppercase border-b border-divider">
                  <th className="px-4 py-3">User</th>
                  <th className="px-4 py-3">Role</th>
                  <th className="px-4 py-3">Status</th>
                  <th className="px-4 py-3">Joined</th>
                </tr>
              </thead>
              <tbody>
                {users.map((u) => (
                  <tr
                    key={u._id}
                    onClick={() => openDetail(u)}
                    className="border-b border-divider last:border-0 cursor-pointer hover:bg-soft-pink/40 transition-colors"
                  >
                    <td className="px-4 py-3">
                      <div className="flex items-center gap-3">
                        {u.profileImage || u.storeLogo ? (
                          <img
                            src={resolveImageUrl(u.profileImage || u.storeLogo)}
                            alt=""
                            className="h-9 w-9 rounded-full object-cover shrink-0"
                          />
                        ) : (
                          <div className="h-9 w-9 rounded-full bg-soft-pink flex items-center justify-center text-wine font-semibold shrink-0">
                            {u.fullName?.[0]?.toUpperCase() || "?"}
                          </div>
                        )}
                        <div className="min-w-0">
                          <p className="font-medium text-ink truncate">{u.fullName || "—"}</p>
                          <p className="text-xs text-subtext truncate">{u.email}</p>
                        </div>
                      </div>
                    </td>
                    <td className="px-4 py-3">
                      <span className={`inline-block text-xs font-semibold px-2.5 py-1 rounded-full ${ROLE_STYLES[u.role] || ROLE_STYLES.user}`}>
                        {u.role}
                      </span>
                    </td>
                    <td className="px-4 py-3">
                      <span className={`inline-block text-xs font-semibold px-2.5 py-1 rounded-full ${u.isActive === false ? "bg-red-50 text-red-600" : "bg-emerald-50 text-emerald-600"}`}>
                        {u.isActive === false ? "Inactive" : "Active"}
                      </span>
                    </td>
                    <td className="px-4 py-3 text-subtext">{timeAgo(u.createdAt)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </Card>
          <Pagination page={page} totalPages={totalPages} onChange={setPage} />
        </>
      )}

      <Modal open={!!selected} onClose={closeDetail} title="User Details" size="lg">
        {detailLoading || !detail ? (
          <div className="flex items-center justify-center py-12">
            <Loader2 className="animate-spin text-wine" size={28} />
          </div>
        ) : (
          <div className="flex flex-col gap-4">
            <div className="flex items-center gap-4">
              {detail.profileImage ? (
                <img src={resolveImageUrl(detail.profileImage)} alt="" className="h-16 w-16 rounded-full object-cover" />
              ) : (
                <div className="h-16 w-16 rounded-full bg-soft-pink flex items-center justify-center text-wine font-bold text-xl">
                  {detail.fullName?.[0]?.toUpperCase() || "?"}
                </div>
              )}
              <div className="min-w-0">
                <p className="font-display text-lg font-bold text-ink truncate">{detail.fullName || "—"}</p>
                <p className="text-sm text-subtext truncate">{detail.email}</p>
              </div>
            </div>

            <div className="grid grid-cols-2 gap-3 text-sm">
              <div>
                <p className="text-xs text-subtext mb-1">Role</p>
                <select
                  value={detail.role}
                  onChange={(e) => {
                    const value = e.target.value;
                    if (value === "admin") {
                      setPendingAction({ type: "role", value });
                    } else {
                      handleRoleChange(value);
                    }
                  }}
                  disabled={actionLoading}
                  className={inputClass}
                >
                  <option value="user">User</option>
                  <option value="seller">Seller</option>
                  <option value="admin">Admin</option>
                </select>
              </div>
              <div>
                <p className="text-xs text-subtext mb-1">City</p>
                <p className="text-ink">{detail.city || "—"}</p>
              </div>
              <div>
                <p className="text-xs text-subtext mb-1">Status</p>
                <span className={`inline-block text-xs font-semibold px-2.5 py-1 rounded-full ${detail.isActive === false ? "bg-red-50 text-red-600" : "bg-emerald-50 text-emerald-600"}`}>
                  {detail.isActive === false ? "Inactive" : "Active"}
                </span>
              </div>
              <div>
                <p className="text-xs text-subtext mb-1">Joined</p>
                <p className="text-ink">{detail.createdAt ? new Date(detail.createdAt).toLocaleDateString() : "—"}</p>
              </div>
            </div>

            {detail.bio && (
              <div>
                <p className="text-xs text-subtext mb-1">Bio</p>
                <p className="text-sm text-ink">{detail.bio}</p>
              </div>
            )}

            {detail.role === "seller" && (detail.storeName || detail.storeLogo) && (
              <div className="flex items-center gap-3 rounded-xl bg-soft-pink/50 px-3 py-2.5">
                {detail.storeLogo && (
                  <img src={resolveImageUrl(detail.storeLogo)} alt="" className="h-9 w-9 rounded-lg object-cover" />
                )}
                <p className="text-sm font-medium text-ink">{detail.storeName}</p>
              </div>
            )}

            <div className="flex flex-wrap items-center justify-between gap-2 pt-2 border-t border-divider">
              <Button
                variant="secondary"
                size="sm"
                onClick={() => setPendingAction({ type: "toggle-active" })}
                disabled={actionLoading}
              >
                {detail.isActive === false ? "Activate" : "Deactivate"}
              </Button>
              <Button
                variant="outline"
                size="sm"
                className="!border-danger !text-danger hover:!bg-danger hover:!text-white"
                onClick={() => setPendingAction({ type: "delete" })}
                disabled={actionLoading}
              >
                <Trash2 size={14} /> Delete User
              </Button>
            </div>
          </div>
        )}
      </Modal>

      <ConfirmDialog
        open={pendingAction?.type === "toggle-active"}
        onClose={() => setPendingAction(null)}
        onConfirm={handleToggleActive}
        title={detail?.isActive === false ? "Activate User" : "Deactivate User"}
        message={
          detail?.isActive === false
            ? `Reactivate ${detail?.fullName || "this user"}'s account?`
            : `Deactivate ${detail?.fullName || "this user"}'s account? They won't be able to log in.`
        }
        confirmLabel={detail?.isActive === false ? "Activate" : "Deactivate"}
        loading={actionLoading}
      />

      <ConfirmDialog
        open={pendingAction?.type === "role"}
        onClose={() => setPendingAction(null)}
        onConfirm={() => handleRoleChange(pendingAction?.value)}
        title="Promote to Admin"
        message={`Grant admin privileges to ${detail?.fullName || "this user"}? Admins have full access to the dashboard.`}
        confirmLabel="Promote"
        loading={actionLoading}
      />

      <ConfirmDialog
        open={pendingAction?.type === "delete"}
        onClose={() => setPendingAction(null)}
        onConfirm={handleDelete}
        title="Delete User"
        message={`Permanently delete ${detail?.fullName || "this user"}'s account? This cannot be undone.`}
        confirmLabel="Delete"
        loading={actionLoading}
      />
    </div>
  );
}
