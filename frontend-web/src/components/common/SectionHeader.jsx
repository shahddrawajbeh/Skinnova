import { Link } from "react-router-dom";
import { ArrowRight } from "lucide-react";

export default function SectionHeader({ title, subtitle, to, linkLabel = "View all" }) {
  return (
    <div className="flex items-end justify-between mb-4">
      <div>
        <h2 className="font-display text-2xl sm:text-3xl font-bold text-ink">{title}</h2>
        {subtitle && <p className="text-subtext text-sm mt-1">{subtitle}</p>}
      </div>
      {to && (
        <Link
          to={to}
          className="hidden sm:inline-flex items-center gap-1 text-sm font-semibold text-wine hover:gap-2 transition-all"
        >
          {linkLabel} <ArrowRight size={15} />
        </Link>
      )}
    </div>
  );
}
