import { useEffect, useState } from "react";

function formatDateLabel(dateStr) {
  const d = new Date(dateStr);
  if (Number.isNaN(d.getTime())) return dateStr;
  return d.toLocaleDateString(undefined, { month: "short", day: "numeric" });
}

export default function LineChart({
  data,
  valueKey = "revenue",
  labelKey = "date",
  color = "var(--color-wine)",
  height = 220,
}) {
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    const id = requestAnimationFrame(() => setMounted(true));
    return () => cancelAnimationFrame(id);
  }, []);

  if (!data.length) {
    return (
      <div className="flex items-center justify-center text-sm text-subtext" style={{ height }}>
        No data yet
      </div>
    );
  }

  const W = 100;
  const H = 40;
  const values = data.map((d) => Number(d[valueKey]) || 0);
  const max = Math.max(...values, 1);

  const points = data.map((d, i) => {
    const x = data.length === 1 ? 0 : (i / (data.length - 1)) * W;
    const y = H - ((Number(d[valueKey]) || 0) / max) * H;
    return [x, y];
  });

  const linePath = points.map((p, i) => `${i === 0 ? "M" : "L"} ${p[0]},${p[1]}`).join(" ");
  const areaPath = `${linePath} L ${points[points.length - 1][0]},${H} L ${points[0][0]},${H} Z`;

  // Show up to 5 evenly-spaced x-axis labels
  const labelStep = Math.max(1, Math.ceil(data.length / 5));

  return (
    <div style={{ height }}>
      <svg
        viewBox={`0 0 ${W} ${H}`}
        preserveAspectRatio="none"
        className="w-full"
        style={{ height: height - 24 }}
      >
        <defs>
          <linearGradient id="lineChartFill" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor={color} stopOpacity="0.25" />
            <stop offset="100%" stopColor={color} stopOpacity="0" />
          </linearGradient>
        </defs>
        <path d={areaPath} fill="url(#lineChartFill)" stroke="none" />
        <path
          d={linePath}
          fill="none"
          stroke={color}
          strokeWidth="0.6"
          strokeLinecap="round"
          strokeLinejoin="round"
          pathLength="100"
          style={{
            strokeDasharray: 100,
            strokeDashoffset: mounted ? 0 : 100,
            transition: "stroke-dashoffset 1s ease-out",
          }}
        />
        {points.map((p, i) => (
          <circle
            key={i}
            cx={p[0]}
            cy={p[1]}
            r="0.7"
            fill={color}
            style={{
              opacity: mounted ? 1 : 0,
              transition: `opacity 0.4s ease-out ${0.4 + i * 0.02}s`,
            }}
          >
            <title>
              {data[i][labelKey]}: {values[i]}
            </title>
          </circle>
        ))}
      </svg>
      <div className="flex justify-between text-[10px] text-subtext mt-1 px-1">
        {data
          .filter((_, i) => i % labelStep === 0 || i === data.length - 1)
          .map((d, i) => (
            <span key={i}>{formatDateLabel(d[labelKey])}</span>
          ))}
      </div>
    </div>
  );
}
