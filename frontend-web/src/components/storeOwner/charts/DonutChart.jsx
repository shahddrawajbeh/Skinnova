import { useEffect, useState } from "react";

const RADIUS = 15.9155; // circumference ≈ 100, so stroke-dasharray works in percent
const CIRCUMFERENCE = 2 * Math.PI * RADIUS;

export default function DonutChart({ data, centerLabel, centerValue, size = 200 }) {
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    const id = requestAnimationFrame(() => setMounted(true));
    return () => cancelAnimationFrame(id);
  }, []);

  const total = data.reduce((sum, d) => sum + (Number(d.value) || 0), 0);

  if (!total) {
    return (
      <div className="flex items-center justify-center text-sm text-subtext" style={{ height: size }}>
        No data yet
      </div>
    );
  }

  let cumulative = 0;

  return (
    <div className="flex flex-col items-center gap-4">
      <div className="relative" style={{ width: size, height: size }}>
        <svg viewBox="0 0 36 36" className="w-full h-full">
          <circle cx="18" cy="18" r={RADIUS} fill="none" stroke="var(--color-soft-pink)" strokeWidth="3.5" />
          <g
            style={{
              transform: mounted ? "rotate(-90deg) scale(1)" : "rotate(-90deg) scale(0)",
              transformOrigin: "18px 18px",
              transition: "transform 0.7s cubic-bezier(0.34, 1.56, 0.64, 1)",
            }}
          >
            {data.map((d, i) => {
              const value = Number(d.value) || 0;
              if (!value) return null;
              const pct = (value / total) * 100;
              const dasharray = `${(pct / 100) * CIRCUMFERENCE} ${CIRCUMFERENCE}`;
              const dashoffset = -((cumulative / 100) * CIRCUMFERENCE);
              cumulative += pct;
              return (
                <circle
                  key={i}
                  cx="18"
                  cy="18"
                  r={RADIUS}
                  fill="none"
                  stroke={d.color}
                  strokeWidth="3.5"
                  strokeDasharray={dasharray}
                  strokeDashoffset={dashoffset}
                >
                  <title>
                    {d.label}: {value}
                  </title>
                </circle>
              );
            })}
          </g>
        </svg>
        {(centerLabel || centerValue !== undefined) && (
          <div className="absolute inset-0 flex flex-col items-center justify-center">
            <span className="text-xl font-bold text-ink">{centerValue ?? total}</span>
            {centerLabel && <span className="text-xs text-subtext">{centerLabel}</span>}
          </div>
        )}
      </div>
      <div className="flex flex-wrap justify-center gap-3 text-xs">
        {data.map((d, i) => (
          <span key={i} className="flex items-center gap-1.5">
            <span className="h-2.5 w-2.5 rounded-full" style={{ background: d.color }} />
            <span className="text-subtext">{d.label}</span>
            <span className="font-semibold text-ink">{d.value}</span>
          </span>
        ))}
      </div>
    </div>
  );
}
