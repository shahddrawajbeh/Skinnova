export default function Tabs({ tabs, value, onChange, className = "" }) {
  return (
    <div className={`flex flex-wrap gap-2 ${className}`}>
      {tabs.map((tab) => {
        const tabValue = typeof tab === "string" ? tab : tab.value;
        const tabLabel = typeof tab === "string" ? tab : tab.label;
        const active = value === tabValue;
        return (
          <button
            key={tabValue}
            onClick={() => onChange(tabValue)}
            className={`px-4 py-1.5 rounded-full text-sm font-medium transition-all duration-200 ${
              active
                ? "bg-wine text-white shadow-sm"
                : "bg-soft-pink text-wine hover:bg-dusty-rose-light"
            }`}
          >
            {tabLabel}
          </button>
        );
      })}
    </div>
  );
}
