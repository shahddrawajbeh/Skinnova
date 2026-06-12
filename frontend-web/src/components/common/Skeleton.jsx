export function Skeleton({ className = "" }) {
  return <div className={`gradient-shimmer rounded-xl ${className}`} />;
}

export function SkeletonCard({ className = "" }) {
  return (
    <div className={`rounded-2xl border border-divider bg-white p-3 ${className}`}>
      <Skeleton className="h-32 w-full mb-3" />
      <Skeleton className="h-4 w-3/4 mb-2" />
      <Skeleton className="h-4 w-1/2" />
    </div>
  );
}

export function SkeletonRow({ count = 4, itemClassName = "w-44 h-56" }) {
  return (
    <div className="flex gap-4 overflow-hidden">
      {Array.from({ length: count }).map((_, i) => (
        <SkeletonCard key={i} className={`shrink-0 ${itemClassName}`} />
      ))}
    </div>
  );
}
