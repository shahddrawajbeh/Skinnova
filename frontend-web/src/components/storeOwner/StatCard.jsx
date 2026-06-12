import Card from "../common/Card";

export default function StatCard({ icon: Icon, label, value, trend, delay = 0, accent = "wine" }) {
  return (
    <Card
      className="p-4 sm:p-5 flex items-center gap-4 animate-pop-in"
      style={{ animationDelay: `${delay}ms` }}
    >
      {Icon && (
        <div
          className={`flex h-11 w-11 shrink-0 items-center justify-center rounded-xl bg-soft-pink text-${accent}`}
        >
          <Icon size={20} />
        </div>
      )}
      <div className="min-w-0">
        <p className="text-xs text-subtext truncate">{label}</p>
        <p className="text-xl font-bold text-ink truncate">{value}</p>
        {trend && <p className="text-xs text-success mt-0.5">{trend}</p>}
      </div>
    </Card>
  );
}
