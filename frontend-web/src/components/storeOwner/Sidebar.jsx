import { useEffect, useState } from "react";
import { NavLink, useNavigate } from "react-router-dom";
import {
  LayoutDashboard,
  Package,
  ShoppingBag,
  BarChart3,
  Star,
  Users,
  Store,
  Bell,
  Settings,
  LogOut,
  X,
} from "lucide-react";
import { useAuth } from "../../context/AuthContext";

export const SIDEBAR_DENSITY_KEY = "storeOwnerSidebarDensity";
export const SIDEBAR_DENSITY_EVENT = "storeowner-density-change";

const links = [
  { to: "/store-owner", label: "Dashboard", icon: LayoutDashboard, end: true },
  { to: "/store-owner/products", label: "Products", icon: Package },
  { to: "/store-owner/orders", label: "Orders", icon: ShoppingBag },
  { to: "/store-owner/analytics", label: "Analytics", icon: BarChart3 },
  { to: "/store-owner/reviews", label: "Reviews", icon: Star },
  { to: "/store-owner/community", label: "Community", icon: Users },
  { to: "/store-owner/store-profile", label: "Store Profile", icon: Store },
  { to: "/store-owner/notifications", label: "Notifications", icon: Bell },
  { to: "/store-owner/settings", label: "Settings", icon: Settings },
];

export default function Sidebar({ open, onClose }) {
  const { logout } = useAuth();
  const navigate = useNavigate();
  const [compact, setCompact] = useState(() => localStorage.getItem(SIDEBAR_DENSITY_KEY) === "compact");

  useEffect(() => {
    const handleChange = () => setCompact(localStorage.getItem(SIDEBAR_DENSITY_KEY) === "compact");
    window.addEventListener(SIDEBAR_DENSITY_EVENT, handleChange);
    return () => window.removeEventListener(SIDEBAR_DENSITY_EVENT, handleChange);
  }, []);

  const handleLogout = () => {
    logout();
    navigate("/");
  };

  const linkClasses = ({ isActive }) =>
    `flex items-center gap-3 px-4 ${compact ? "py-1.5" : "py-2.5"} rounded-xl text-sm font-medium transition-all duration-200 ${
      isActive
        ? "bg-soft-pink text-wine shadow-sm"
        : "text-cream/80 hover:bg-wine-dark hover:text-white"
    }`;

  return (
    <>
      {open && (
        <div
          className="fixed inset-0 z-40 bg-black/40 lg:hidden"
          onClick={onClose}
          aria-hidden="true"
        />
      )}
      <aside
        className={`print:hidden fixed lg:sticky top-0 left-0 z-50 h-screen w-64 shrink-0 bg-wine text-white flex flex-col transition-transform duration-300 ease-out
          ${open ? "translate-x-0" : "-translate-x-full"} lg:translate-x-0`}
      >
        <div className="flex items-center justify-between px-5 py-5 border-b border-white/10">
          <div className="flex items-center gap-2">
            <img src="/logo.png" alt="Skinova" className="h-9 w-9 rounded-xl object-cover" />
            <div>
              <p className="font-display text-lg font-bold leading-none">Skinova</p>
              <p className="text-xs text-dusty-rose-light leading-none mt-1">Store Owner</p>
            </div>
          </div>
          <button
            className="lg:hidden p-1.5 rounded-full hover:bg-wine-dark transition-colors"
            onClick={onClose}
            aria-label="Close menu"
          >
            <X size={20} />
          </button>
        </div>

        <nav className="flex-1 overflow-y-auto px-3 py-4 flex flex-col gap-1">
          {links.map((link) => (
            <NavLink
              key={link.to}
              to={link.to}
              end={link.end}
              className={linkClasses}
              onClick={onClose}
            >
              <link.icon size={18} />
              {link.label}
            </NavLink>
          ))}
        </nav>

        <div className="px-3 py-4 border-t border-white/10">
          <button
            onClick={handleLogout}
            className="flex items-center gap-3 w-full px-4 py-2.5 rounded-xl text-sm font-medium text-dusty-rose-light hover:bg-wine-dark hover:text-white transition-all duration-200"
          >
            <LogOut size={18} />
            Logout
          </button>
        </div>
      </aside>
    </>
  );
}
