import { useEffect } from "react";
import { X } from "lucide-react";
import Card from "./Card";

export default function Modal({ open, onClose, title, children, size = "md" }) {
  useEffect(() => {
    if (!open) return;
    const onKeyDown = (e) => {
      if (e.key === "Escape") onClose?.();
    };
    document.addEventListener("keydown", onKeyDown);
    document.body.style.overflow = "hidden";
    return () => {
      document.removeEventListener("keydown", onKeyDown);
      document.body.style.overflow = "";
    };
  }, [open, onClose]);

  if (!open) return null;

  const sizes = {
    sm: "max-w-sm",
    md: "max-w-lg",
    lg: "max-w-2xl",
    xl: "max-w-4xl",
  };

  return (
    <div className="fixed inset-0 z-[100] flex items-center justify-center p-4 bg-black/40 animate-fade-slide-in">
      <Card
        className={`w-full ${sizes[size] || sizes.md} max-h-[90vh] overflow-y-auto p-6 animate-pop-in`}
        hover={false}
      >
        <div className="flex items-center justify-between mb-4">
          {title && <h3 className="font-display text-lg font-bold text-ink">{title}</h3>}
          <button
            onClick={onClose}
            className="ml-auto p-1.5 rounded-full text-subtext hover:text-wine hover:bg-soft-pink transition-all"
            aria-label="Close"
          >
            <X size={18} />
          </button>
        </div>
        {children}
      </Card>
    </div>
  );
}
