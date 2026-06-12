import { Link } from "react-router-dom";

export default function AuthLayout({ title, subtitle, children, footer }) {
  return (
    <div className="min-h-[calc(100vh-4rem)] flex items-center justify-center py-10 px-4">
      <div className="w-full max-w-md animate-fade-slide-in">
        <div className="text-center mb-6">
          <Link to="/" className="inline-flex items-center gap-2 mb-4">
            <img src="/logo.png" alt="Skinova" className="h-12 w-12 rounded-2xl object-cover" />
          </Link>
          <h1 className="font-display text-2xl sm:text-3xl font-bold text-wine">{title}</h1>
          {subtitle && <p className="text-subtext text-sm mt-2">{subtitle}</p>}
        </div>
        <div className="bg-white rounded-3xl shadow-xl shadow-wine/10 border border-divider p-6 sm:p-8">
          {children}
        </div>
        {footer && <div className="text-center mt-5 text-sm text-subtext">{footer}</div>}
      </div>
    </div>
  );
}

export function FormField({ label, error, children }) {
  return (
    <div className="mb-4">
      <label className="block text-sm font-medium text-ink mb-1.5">{label}</label>
      {children}
      {error && <p className="text-xs text-danger mt-1">{error}</p>}
    </div>
  );
}

export const inputClass =
  "w-full rounded-xl border border-divider bg-cream/50 px-4 py-2.5 text-sm text-ink placeholder:text-subtext/70 focus:outline-none focus:ring-2 focus:ring-wine/40 focus:border-wine transition-all";
