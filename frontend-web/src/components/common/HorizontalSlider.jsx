import { useRef } from "react";
import { ChevronLeft, ChevronRight } from "lucide-react";

export default function HorizontalSlider({ children, className = "", itemClassName = "" }) {
  const scrollerRef = useRef(null);
  const dragState = useRef({ down: false, startX: 0, startScroll: 0 });

  const scrollByAmount = (dir) => {
    const el = scrollerRef.current;
    if (!el) return;
    el.scrollBy({ left: dir * el.clientWidth * 0.8, behavior: "smooth" });
  };

  const onPointerDown = (e) => {
    const el = scrollerRef.current;
    if (!el) return;
    dragState.current = {
      down: true,
      startX: e.clientX,
      startScroll: el.scrollLeft,
    };
    el.classList.add("cursor-grabbing");
  };

  const onPointerMove = (e) => {
    const el = scrollerRef.current;
    if (!el || !dragState.current.down) return;
    const dx = e.clientX - dragState.current.startX;
    el.scrollLeft = dragState.current.startScroll - dx;
  };

  const endDrag = () => {
    const el = scrollerRef.current;
    dragState.current.down = false;
    el?.classList.remove("cursor-grabbing");
  };

  return (
    <div className={`relative group ${className}`}>
      <button
        type="button"
        onClick={() => scrollByAmount(-1)}
        aria-label="Scroll left"
        className="hidden md:flex absolute -left-4 top-1/2 -translate-y-1/2 z-10 h-10 w-10 items-center
          justify-center rounded-full bg-white shadow-lg border border-divider text-wine
          opacity-0 group-hover:opacity-100 transition-all hover:scale-110 hover:bg-soft-pink"
      >
        <ChevronLeft size={20} />
      </button>

      <div
        ref={scrollerRef}
        onPointerDown={onPointerDown}
        onPointerMove={onPointerMove}
        onPointerUp={endDrag}
        onPointerLeave={endDrag}
        className="no-scrollbar snap-row flex gap-4 overflow-x-auto cursor-grab pb-2 -mx-1 px-1"
      >
        {Array.isArray(children)
          ? children.map((child, i) => (
              <div key={i} className={`snap-item shrink-0 ${itemClassName}`}>
                {child}
              </div>
            ))
          : children}
      </div>

      <button
        type="button"
        onClick={() => scrollByAmount(1)}
        aria-label="Scroll right"
        className="hidden md:flex absolute -right-4 top-1/2 -translate-y-1/2 z-10 h-10 w-10 items-center
          justify-center rounded-full bg-white shadow-lg border border-divider text-wine
          opacity-0 group-hover:opacity-100 transition-all hover:scale-110 hover:bg-soft-pink"
      >
        <ChevronRight size={20} />
      </button>
    </div>
  );
}
