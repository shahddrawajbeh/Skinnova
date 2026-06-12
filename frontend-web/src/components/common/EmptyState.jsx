export default function EmptyState({ icon: Icon, title, message, action }) {
  return (
    <div className="flex flex-col items-center justify-center text-center py-12 px-6 animate-fade-slide-in">
      {Icon && (
        <div className="mb-4 flex h-16 w-16 items-center justify-center rounded-full bg-soft-pink text-wine">
          <Icon size={28} />
        </div>
      )}
      <h3 className="text-lg font-semibold text-ink mb-1">{title}</h3>
      {message && <p className="text-sm text-subtext max-w-sm">{message}</p>}
      {action && <div className="mt-4">{action}</div>}
    </div>
  );
}
