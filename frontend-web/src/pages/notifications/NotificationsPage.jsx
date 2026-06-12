import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import {
  Loader2,
  Bell,
  Package,
  Heart,
  MessageCircle,
  UserPlus,
  ShoppingBag,
  Megaphone,
  Star,
  ScanFace,
  Sun,
  CheckCheck,
} from "lucide-react";
import Card from "../../components/common/Card";
import Button from "../../components/common/Button";
import EmptyState from "../../components/common/EmptyState";
import { useAuth } from "../../context/AuthContext";
import { useToast } from "../../context/ToastContext";
import { notificationService } from "../../services/notificationService";
import { timeAgo } from "../../utils/format";

const TYPE_ICONS = {
  new_order: Package,
  order_status_changed: Package,
  order_confirmed_received: Package,
  review_submitted: Star,
  review_pending: Star,
  post_like: Heart,
  post_comment: MessageCircle,
  new_follower: UserPlus,
  store_new_follower: UserPlus,
  new_product: ShoppingBag,
  restock: ShoppingBag,
  followed_store_new_product: ShoppingBag,
  promo: Megaphone,
  new_ad_request: Megaphone,
  ad_approved: Megaphone,
  ad_rejected: Megaphone,
  skin_scan_reminder: ScanFace,
  product_usage_reminder: ScanFace,
  routine_step_reminder: Sun,
  skincare_tip: Sun,
};

const TYPE_LINKS = {
  new_order: "/orders",
  order_status_changed: "/orders",
  order_confirmed_received: "/orders",
  post_like: "/community",
  post_comment: "/community",
  new_product: "/shop",
  restock: "/shop",
  followed_store_new_product: "/shop",
  promo: "/shop",
  skin_scan_reminder: "/scan",
  product_usage_reminder: "/scan",
  routine_step_reminder: "/routine",
  skincare_tip: "/routine",
};

export default function NotificationsPage() {
  const { user } = useAuth();
  const toast = useToast();
  const navigate = useNavigate();

  const [notifications, setNotifications] = useState([]);
  const [loading, setLoading] = useState(true);
  const [markingAll, setMarkingAll] = useState(false);

  useEffect(() => {
    notificationService
      .fetchNotifications(user.userId)
      .then((data) => setNotifications(data))
      .catch(() => toast.error("Couldn't load your notifications."))
      .finally(() => setLoading(false));
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [user.userId]);

  const handleMarkAllRead = async () => {
    setMarkingAll(true);
    try {
      await notificationService.markAllRead(user.userId);
      setNotifications((prev) => prev.map((n) => ({ ...n, isRead: true })));
    } catch {
      toast.error("Couldn't mark notifications as read.");
    } finally {
      setMarkingAll(false);
    }
  };

  const handleClick = async (notification) => {
    if (!notification.isRead) {
      setNotifications((prev) => prev.map((n) => (n._id === notification._id ? { ...n, isRead: true } : n)));
      notificationService.markRead(notification._id).catch(() => {});
    }
    const link = TYPE_LINKS[notification.type];
    if (link) navigate(link);
  };

  const unreadCount = notifications.filter((n) => !n.isRead).length;

  if (loading) {
    return (
      <div className="flex items-center justify-center py-24">
        <Loader2 className="animate-spin text-wine" size={32} />
      </div>
    );
  }

  return (
    <div className="max-w-2xl mx-auto flex flex-col gap-6 animate-fade-slide-in">
      <div className="flex items-center justify-between">
        <h1 className="font-display text-3xl sm:text-4xl font-bold text-ink">Notifications</h1>
        {unreadCount > 0 && (
          <Button variant="secondary" size="sm" onClick={handleMarkAllRead} disabled={markingAll}>
            {markingAll ? <Loader2 size={14} className="animate-spin" /> : <CheckCheck size={14} />}
            Mark all read
          </Button>
        )}
      </div>

      {notifications.length === 0 ? (
        <EmptyState icon={Bell} title="No notifications yet" message="We'll let you know when something happens." />
      ) : (
        <div className="flex flex-col gap-2">
          {notifications.map((n) => {
            const Icon = TYPE_ICONS[n.type] || Bell;
            return (
              <Card
                key={n._id}
                onClick={() => handleClick(n)}
                className={`p-4 flex items-start gap-3 cursor-pointer ${!n.isRead ? "bg-soft-pink/40" : ""}`}
              >
                <div className="h-10 w-10 rounded-full bg-soft-pink text-wine flex items-center justify-center shrink-0">
                  <Icon size={18} />
                </div>
                <div className="flex-1 min-w-0">
                  <p className={`text-sm ${!n.isRead ? "font-bold text-ink" : "font-semibold text-ink"}`}>{n.title}</p>
                  <p className="text-sm text-subtext mt-0.5">{n.body}</p>
                  <p className="text-xs text-subtext mt-1">{timeAgo(n.createdAt)}</p>
                </div>
                {!n.isRead && <span className="h-2.5 w-2.5 rounded-full bg-wine shrink-0 mt-1.5" />}
              </Card>
            );
          })}
        </div>
      )}
    </div>
  );
}
