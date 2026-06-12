export function timeAgo(dateString) {
  if (!dateString) return "";
  const date = new Date(dateString);
  const seconds = Math.floor((Date.now() - date.getTime()) / 1000);
  if (seconds < 60) return "just now";
  const minutes = Math.floor(seconds / 60);
  if (minutes < 60) return `${minutes}m ago`;
  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `${hours}h ago`;
  const days = Math.floor(hours / 24);
  if (days < 7) return `${days}d ago`;
  const weeks = Math.floor(days / 7);
  if (weeks < 5) return `${weeks}w ago`;
  return date.toLocaleDateString();
}

export const POST_TYPE_STYLES = {
  question: { bg: "bg-blue-50", fg: "text-blue-600", label: "Question" },
  review: { bg: "bg-amber-50", fg: "text-amber-600", label: "Review" },
  update: { bg: "bg-soft-pink", fg: "text-wine", label: "Update" },
  tip: { bg: "bg-emerald-50", fg: "text-emerald-600", label: "Tip" },
  routine: { bg: "bg-violet-50", fg: "text-violet-600", label: "Routine" },
  before_after: { bg: "bg-rose-50", fg: "text-rose-600", label: "Before & After" },
};

export function postTypeStyle(type) {
  return POST_TYPE_STYLES[type] || POST_TYPE_STYLES.update;
}

export function formatPrice(price, currency = "") {
  const n = Number(price || 0);
  return `${n.toFixed(2)}${currency ? ` ${currency}` : ""}`;
}

export const ORDER_STATUS_STYLES = {
  pending: { bg: "bg-amber-50", fg: "text-amber-600", label: "Pending" },
  confirmed: { bg: "bg-blue-50", fg: "text-blue-600", label: "Confirmed" },
  processing: { bg: "bg-violet-50", fg: "text-violet-600", label: "Processing" },
  out_for_delivery: { bg: "bg-cyan-50", fg: "text-cyan-600", label: "Out for delivery" },
  delivered: { bg: "bg-emerald-50", fg: "text-emerald-600", label: "Delivered" },
  cancelled: { bg: "bg-red-50", fg: "text-red-600", label: "Cancelled" },
};

export function orderStatusStyle(status) {
  return ORDER_STATUS_STYLES[status] || ORDER_STATUS_STYLES.pending;
}
