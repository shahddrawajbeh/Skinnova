import { useEffect, useMemo, useState } from "react";
import { Loader2, Star, User, Send, Store } from "lucide-react";
import Card from "../../components/common/Card";
import Button from "../../components/common/Button";
import EmptyState from "../../components/common/EmptyState";
import Tabs from "../../components/common/Tabs";
import { resolveImageUrl } from "../../services/api";
import { useStoreOwner } from "../../context/StoreOwnerContext";
import { useToast } from "../../context/ToastContext";
import { storeOwnerService } from "../../services/storeOwnerService";
import { timeAgo } from "../../utils/format";

const FILTERS = [
  { value: "all", label: "All" },
  { value: "5", label: "5 stars" },
  { value: "4", label: "4 stars" },
  { value: "3", label: "3 stars" },
  { value: "2", label: "2 stars" },
  { value: "1", label: "1 star" },
];

function Stars({ rating }) {
  return (
    <div className="flex items-center gap-0.5">
      {[1, 2, 3, 4, 5].map((n) => (
        <Star key={n} size={14} className={n <= rating ? "text-gold fill-gold" : "text-divider"} />
      ))}
    </div>
  );
}

function ReviewCard({ review, storeId, onReplied, delayMs }) {
  const toast = useToast();
  const [reply, setReply] = useState(review.sellerReply?.comment || "");
  const [submitting, setSubmitting] = useState(false);

  const handleReply = async () => {
    if (!reply.trim()) {
      toast.error("Write a reply first.");
      return;
    }
    setSubmitting(true);
    try {
      await storeOwnerService.replyToReview(storeId, review._id, reply.trim());
      toast.success("Reply sent.");
      onReplied(review._id, { comment: reply.trim(), repliedAt: new Date().toISOString() });
    } catch (err) {
      toast.error(err.response?.data?.message || "Couldn't send reply.");
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <Card className="p-4 sm:p-5 flex flex-col gap-3 animate-pop-in" style={{ animationDelay: `${delayMs}ms` }}>
      <div className="flex items-center gap-3">
        {review.userId?.profileImage ? (
          <img src={resolveImageUrl(review.userId.profileImage)} alt="" className="h-10 w-10 rounded-full object-cover" />
        ) : (
          <div className="h-10 w-10 rounded-full bg-soft-pink flex items-center justify-center text-wine">
            <User size={18} />
          </div>
        )}
        <div className="min-w-0 flex-1">
          <p className="text-sm font-semibold text-ink truncate">{review.userName}</p>
          <p className="text-xs text-subtext">{timeAgo(review.createdAt)}</p>
        </div>
        <Stars rating={review.rating} />
      </div>

      {review.comment && <p className="text-sm text-ink leading-relaxed">{review.comment}</p>}

      {review.sellerReply?.comment && (
        <div className="rounded-xl bg-soft-pink/60 px-3 py-2 flex items-start gap-2">
          <Store size={14} className="text-wine mt-0.5 shrink-0" />
          <div>
            <p className="text-xs font-semibold text-wine">Your reply</p>
            <p className="text-sm text-ink">{review.sellerReply.comment}</p>
            <p className="text-[11px] text-subtext mt-0.5">{timeAgo(review.sellerReply.repliedAt)}</p>
          </div>
        </div>
      )}

      <div className="flex items-center gap-2">
        <input
          value={reply}
          onChange={(e) => setReply(e.target.value)}
          placeholder="Write a reply to this review..."
          className="flex-1 rounded-full border border-divider bg-cream/50 px-4 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-wine/40 focus:border-wine transition-all"
        />
        <Button onClick={handleReply} disabled={submitting} size="sm">
          {submitting ? <Loader2 size={14} className="animate-spin" /> : <Send size={14} />}
          {review.sellerReply?.comment ? "Update" : "Reply"}
        </Button>
      </div>
    </Card>
  );
}

export default function ReviewsPage() {
  const { store } = useStoreOwner();
  const toast = useToast();
  const [reviews, setReviews] = useState([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState("all");

  useEffect(() => {
    if (!store?._id) return;
    storeOwnerService
      .fetchReviews(store._id)
      .then(setReviews)
      .catch(() => toast.error("Couldn't load reviews."))
      .finally(() => setLoading(false));
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [store?._id]);

  const filtered = useMemo(() => {
    if (filter === "all") return reviews;
    return reviews.filter((r) => String(r.rating) === filter);
  }, [reviews, filter]);

  const handleReplied = (reviewId, sellerReply) => {
    setReviews((prev) => prev.map((r) => (r._id === reviewId ? { ...r, sellerReply } : r)));
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center py-24">
        <Loader2 className="animate-spin text-wine" size={32} />
      </div>
    );
  }

  return (
    <div className="flex flex-col gap-5">
      <div className="animate-fade-slide-in">
        <h2 className="font-display text-2xl font-bold text-ink">Reviews</h2>
        <p className="text-sm text-subtext mt-1">See what customers are saying and reply to their feedback.</p>
      </div>

      <Tabs tabs={FILTERS} value={filter} onChange={setFilter} />

      {filtered.length === 0 ? (
        <EmptyState icon={Star} title="No reviews yet" message="Reviews matching this filter will show up here." />
      ) : (
        <div className="flex flex-col gap-4">
          {filtered.map((review, i) => (
            <ReviewCard
              key={review._id}
              review={review}
              storeId={store._id}
              onReplied={handleReplied}
              delayMs={Math.min(i, 7) * 40}
            />
          ))}
        </div>
      )}
    </div>
  );
}
