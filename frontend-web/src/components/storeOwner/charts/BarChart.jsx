import { useEffect, useState } from "react";

export default function BarChart({
  data,
  valueKey = "value",
  labelKey = "label",
  color = "var(--color-wine)",
  height = 200,
  formatValue,
}) {
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    const id = requestAnimationFrame(() => setMounted(true));
    return () => cancelAnimationFrame(id);
  }, []);

  const max = Math.max(...data.map((d) => Number(d[valueKey]) || 0), 1);

  if (!data.length) {
    return (
      <div className="flex items-center justify-center text-sm text-subtext" style={{ height }}>
        No data yet
      </div>
    );
  }

  return (
    <div className="flex items-end gap-2" style={{ height }}>
      {data.map((d, i) => {
        const value = Number(d[valueKey]) || 0;
        const pct = (value / max) * 100;
        return (
          <div key={i} className="flex-1 flex flex-col items-center gap-1.5 h-full justify-end">
            <span className="text-[11px] font-semibold text-ink">
              {formatValue ? formatValue(value) : value}
            </span>
            <div className="w-full flex-1 flex items-end">
              <div
                className="w-full max-w-[36px] mx-auto rounded-t-lg transition-[height] duration-700 ease-out"
                style={{
                  height: mounted ? `${pct}%` : "0%",
                  background: color,
                  transitionDelay: `${i * 50}ms`,
                }}
              />
            </div>
            <span className="text-[10px] text-subtext truncate w-full text-center">
              {d[labelKey]}
            </span>
          </div>
        );
      })}
    </div>
  );
}
