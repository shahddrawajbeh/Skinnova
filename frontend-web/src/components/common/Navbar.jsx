import { useEffect, useState } from "react";
import { Link, NavLink, useNavigate } from "react-router-dom";
import {
  Menu,
  X,
  ShoppingCart,
  Bell,
  User,
  Sparkles,
  LogOut,
  Heart,
} from "lucide-react";
import { useAuth } from "../../context/AuthContext";
import { notificationService } from "../../services/notificationService";

const navLinks = [
  { to: "/", label: "Home" },
  { to: "/scan", label: "AI Skin Scan" },
  { to: "/routine", label: "My Routine" },
  { to: "/shop", label: "Shop" },
  { to: "/community", label: "Community" },
];

export default function Navbar() {
  const [open, setOpen] = useState(false);
  const [unreadCount, setUnreadCount] = useState(0);
  const { isAuthenticated, user, profile, logout } = useAuth();
  const navigate = useNavigate();

  useEffect(() => {
    if (!isAuthenticated || !user?.userId) {
      setUnreadCount(0);
      return;
    }
    let mounted = true;
    notificationService
      .getUnreadCount(user.userId)
      .then((count) => mounted && setUnreadCount(count))
      .catch(() => {});
    return () => {
      mounted = false;
    };
  }, [isAuthenticated, user?.userId]);

  const linkClasses = ({ isActive }) =>
    `px-3 py-2 rounded-full text-sm font-medium transition-all duration-200 hover:scale-105 ${
      isActive ? "bg-soft-pink text-wine" : "text-ink hover:bg-soft-pink/60 hover:text-wine"
    }`;

  const handleLogout = () => {
    logout();
    setOpen(false);
    navigate("/");
  };

  return (
    <header className="sticky top-0 z-50 bg-white/85 backdrop-blur-md border-b border-divider">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between h-16">
          <Link to="/" className="flex items-center gap-2 shrink-0 group">
            <img
              src="/logo.png"
              alt="Skinova"
              className="h-9 w-9 rounded-xl object-cover transition-transform group-hover:scale-110"
            />
            <span className="font-display text-xl font-bold text-wine">Skinova</span>
          </Link>

          <nav className="hidden lg:flex items-center gap-1">
            {navLinks.map((link) => (
              <NavLink key={link.to} to={link.to} className={linkClasses} end={link.to === "/"}>
                {link.label}
              </NavLink>
            ))}
          </nav>

          <div className="hidden lg:flex items-center gap-2">
            {isAuthenticated ? (
              <>
                <IconLink to="/favorites" label="Favorites">
                  <Heart size={20} />
                </IconLink>
                <IconLink to="/cart" label="Cart">
                  <ShoppingCart size={20} />
                </IconLink>
                <IconLink to="/notifications" label="Notifications">
                  <span className="relative inline-flex">
                    <Bell size={20} />
                    {unreadCount > 0 && (
                      <span className="absolute -top-1 -right-1 h-2.5 w-2.5 rounded-full bg-wine ring-2 ring-white" />
                    )}
                  </span>
                </IconLink>
                <Link
                  to="/profile"
                  className="flex items-center gap-2 ml-1 px-3 py-1.5 rounded-full bg-soft-pink hover:bg-dusty-rose-light transition-all hover:scale-105"
                >
                  {profile?.profileImage ? (
                    <img
                      src={profile.profileImage}
                      alt=""
                      className="h-7 w-7 rounded-full object-cover"
                    />
                  ) : (
                    <User size={18} className="text-wine" />
                  )}
                  <span className="text-sm font-medium text-wine max-w-[100px] truncate">
                    {profile?.fullName || "Profile"}
                  </span>
                </Link>
                <button
                  onClick={handleLogout}
                  className="p-2 rounded-full text-subtext hover:text-danger hover:bg-soft-pink transition-all hover:scale-110"
                  aria-label="Logout"
                  title="Logout"
                >
                  <LogOut size={18} />
                </button>
              </>
            ) : (
              <>
                <Link
                  to="/login"
                  className="px-4 py-2 text-sm font-semibold text-wine hover:scale-105 transition-transform"
                >
                  Log in
                </Link>
                <Link
                  to="/register"
                  className="px-5 py-2 text-sm font-semibold rounded-full bg-wine text-white hover:bg-wine-dark transition-all hover:scale-105 shadow-md shadow-wine/20"
                >
                  Sign up
                </Link>
              </>
            )}
          </div>

          <button
            className="lg:hidden p-2 rounded-full hover:bg-soft-pink transition-colors"
            onClick={() => setOpen((o) => !o)}
            aria-label="Toggle menu"
          >
            {open ? <X size={22} /> : <Menu size={22} />}
          </button>
        </div>
      </div>

      {open && (
        <div className="lg:hidden border-t border-divider bg-white animate-fade-slide-in">
          <div className="px-4 py-3 flex flex-col gap-1">
            {navLinks.map((link) => (
              <NavLink
                key={link.to}
                to={link.to}
                className={linkClasses}
                end={link.to === "/"}
                onClick={() => setOpen(false)}
              >
                {link.label}
              </NavLink>
            ))}
            <div className="h-px bg-divider my-2" />
            {isAuthenticated ? (
              <>
                <NavLink to="/favorites" className={linkClasses} onClick={() => setOpen(false)}>
                  Favorites
                </NavLink>
                <NavLink to="/cart" className={linkClasses} onClick={() => setOpen(false)}>
                  Cart
                </NavLink>
                <NavLink to="/orders" className={linkClasses} onClick={() => setOpen(false)}>
                  Orders
                </NavLink>
                <NavLink to="/notifications" className={linkClasses} onClick={() => setOpen(false)}>
                  Notifications
                </NavLink>
                <NavLink to="/profile" className={linkClasses} onClick={() => setOpen(false)}>
                  Profile
                </NavLink>
                <button
                  onClick={handleLogout}
                  className="px-3 py-2 rounded-full text-sm font-medium text-left text-danger hover:bg-soft-pink transition-colors flex items-center gap-2"
                >
                  <LogOut size={16} /> Logout
                </button>
              </>
            ) : (
              <div className="flex gap-2 pt-1">
                <Link
                  to="/login"
                  className="flex-1 text-center px-4 py-2 text-sm font-semibold text-wine border border-wine rounded-full"
                  onClick={() => setOpen(false)}
                >
                  Log in
                </Link>
                <Link
                  to="/register"
                  className="flex-1 text-center px-4 py-2 text-sm font-semibold rounded-full bg-wine text-white"
                  onClick={() => setOpen(false)}
                >
                  Sign up
                </Link>
              </div>
            )}
          </div>
        </div>
      )}

      <div className="hidden md:block bg-wine text-white text-xs text-center py-1.5 px-4">
        <span className="inline-flex items-center gap-1.5">
          <Sparkles size={12} /> Get the full experience — download the Skinova mobile app for
          camera scanning &amp; unlimited AI scans.
        </span>
      </div>
    </header>
  );
}

function IconLink({ to, label, children }) {
  return (
    <Link
      to={to}
      aria-label={label}
      title={label}
      className="p-2 rounded-full text-ink hover:text-wine hover:bg-soft-pink transition-all hover:scale-110"
    >
      {children}
    </Link>
  );
}
