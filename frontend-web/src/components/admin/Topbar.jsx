import { useEffect, useState } from "react";
import { useLocation, Link } from "react-router-dom";
import { Menu, Bell, ExternalLink } from "lucide-react";
import { useAuth } from "../../context/AuthContext";
import { notificationService } from "../../services/notificationService";

const TITLES = {
  "/admin": "Dashboard",
  "/admin/users": "Users",
  "/admin/stores": "Stores",
  "/admin/store-requests": "Store Requests",
  "/admin/orders": "Orders",
  "/admin/products": "Products",
  "/admin/analytics": "Analytics",
  "/admin/reports": "Reports",
  "/admin/notifications": "Notifications",
  "/admin/support": "Support",
  "/admin/settings": "Settings",
};

function resolveTitle(pathname) {
  if (TITLES[pathname]) return TITLES[pathname];
  if (pathname.startsWith("/admin/orders/")) return "Order Details";
  return "Admin";
}

export default function Topbar({ onMenuClick }) {
  const { user } = useAuth();
  const location = useLocation();
  const [unreadCount, setUnreadCount] = useState(0);

  useEffect(() => {
    if (!user?.userId) return;
    let mounted = true;
    notificationService
      .getUnreadCount(user.userId)
      .then((count) => mounted && setUnreadCount(count))
      .catch(() => {});
    return () => {
      mounted = false;
    };
  }, [user?.userId, location.pathname]);

  return (
    <header className="print:hidden sticky top-0 z-30 bg-white/90 backdrop-blur-md border-b border-divider">
      <div className="flex items-center justify-between h-16 px-4 sm:px-6">
        <div className="flex items-center gap-3">
          <button
            className="lg:hidden p-2 rounded-full hover:bg-soft-pink transition-colors"
            onClick={onMenuClick}
            aria-label="Open menu"
          >
            <Menu size={22} />
          </button>
          <h1 className="font-display text-lg sm:text-xl font-bold text-wine">
            {resolveTitle(location.pathname)}
          </h1>
        </div>

        <div className="flex items-center gap-2">
          <Link
            to="/admin/notifications"
            aria-label="Notifications"
            title="Notifications"
            className="p-2 rounded-full text-ink hover:text-wine hover:bg-soft-pink transition-all hover:scale-110"
          >
            <span className="relative inline-flex">
              <Bell size={20} />
              {unreadCount > 0 && (
                <span className="absolute -top-1 -right-1 h-2.5 w-2.5 rounded-full bg-wine ring-2 ring-white" />
              )}
            </span>
          </Link>
          <Link
            to="/"
            className="hidden sm:inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full text-sm font-medium text-wine border border-wine hover:bg-soft-pink transition-all hover:scale-105"
          >
            <ExternalLink size={14} /> View site
          </Link>
        </div>
      </div>
    </header>
  );
}
