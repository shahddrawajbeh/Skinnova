import { useState } from "react";
import { Link } from "react-router-dom";
import { ThumbsUp, CheckCircle2, Heart, MessageCircle, User, Send, Loader2 } from "lucide-react";
import Card from "../common/Card";
import { resolveImageUrl } from "../../services/api";
import { timeAgo, postTypeStyle } from "../../utils/format";

const REACTIONS = [
  { type: "helpful", label: "Helpful", icon: ThumbsUp },
  { type: "useful", label: "Useful", icon: CheckCircle2 },
  { type: "loveIt", label: "Love it", icon: Heart },
];

export default function CommunityPostCard({ post, currentUserId, onReact, onAddComment }) {
  const [showComments, setShowComments] = useState(false);
  const [commentText, setCommentText] = useState("");
  const [submitting, setSubmitting] = useState(false);

  const style = postTypeStyle(post.postType);
  const reactions = post.reactions || [];
  const comments = post.comments || [];
  const myReaction = reactions.find((r) => r.userId === currentUserId)?.type;
  const image = post.images?.[0];

  const handleSubmitComment = async (e) => {
    e.preventDefault();
    if (!commentText.trim()) return;
    setSubmitting(true);
    try {
      await onAddComment(post._id, commentText.trim());
      setCommentText("");
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <Card className="p-4 sm:p-5 flex flex-col gap-3 animate-fade-slide-in">
      <div className="flex items-center gap-3">
        {post.userAvatar ? (
          <img
            src={resolveImageUrl(post.userAvatar)}
            alt={post.userName}
            className="h-10 w-10 rounded-full object-cover"
          />
        ) : (
          <div className="h-10 w-10 rounded-full bg-soft-pink flex items-center justify-center text-wine">
            <User size={18} />
          </div>
        )}
        <div className="min-w-0 flex-1">
          <p className="text-sm font-semibold text-ink truncate">{post.userName}</p>
          <p className="text-xs text-subtext">
            {timeAgo(post.createdAt)}
            {post.groupTitle && (
              <>
                {" · "}
                <Link to={`/community/group/${post.groupSlug}`} className="text-wine hover:underline">
                  {post.groupTitle}
                </Link>
              </>
            )}
          </p>
        </div>
        <span className={`shrink-0 text-[11px] font-semibold px-2.5 py-1 rounded-full ${style.bg} ${style.fg}`}>
          {style.label}
        </span>
      </div>

      {post.content && <p className="text-sm text-ink leading-relaxed whitespace-pre-line">{post.content}</p>}

      {post.productName && (
        <div className="flex items-center gap-2 rounded-xl bg-soft-pink/60 px-3 py-2 text-xs text-wine font-medium">
          {post.productImage && (
            <img src={resolveImageUrl(post.productImage)} alt="" className="h-8 w-8 rounded-lg object-cover" />
          )}
          <span className="truncate">{post.productName}</span>
        </div>
      )}

      {image && (
        <div className="rounded-xl overflow-hidden max-h-96 bg-soft-pink">
          <img src={resolveImageUrl(image)} alt="" className="w-full h-full object-cover" />
        </div>
      )}

      <div className="flex flex-wrap items-center gap-2 pt-2 border-t border-divider">
        {REACTIONS.map((r) => {
          const count = reactions.filter((x) => x.type === r.type).length;
          const active = myReaction === r.type;
          return (
            <button
              key={r.type}
              type="button"
              onClick={() => onReact(post._id, r.type)}
              className={`flex items-center gap-1.5 rounded-full px-3 py-1.5 text-xs font-semibold transition-all hover:scale-105
                ${active ? "bg-wine text-white" : "bg-soft-pink text-wine hover:bg-dusty-rose-light"}`}
            >
              <r.icon size={13} /> {r.label} {count > 0 && <span>· {count}</span>}
            </button>
          );
        })}
        <button
          type="button"
          onClick={() => setShowComments((s) => !s)}
          className="ml-auto flex items-center gap-1.5 rounded-full px-3 py-1.5 text-xs font-semibold text-subtext hover:text-wine hover:bg-soft-pink transition-all"
        >
          <MessageCircle size={13} /> {comments.length} comment{comments.length === 1 ? "" : "s"}
        </button>
      </div>

      {showComments && (
        <div className="flex flex-col gap-3 pt-2 border-t border-divider animate-fade-slide-in">
          {comments.length === 0 && <p className="text-xs text-subtext">No comments yet. Be the first to reply.</p>}
          {comments.map((c) => (
            <div key={c._id || c.createdAt} className="flex items-start gap-2.5">
              {c.userAvatar ? (
                <img src={resolveImageUrl(c.userAvatar)} alt="" className="h-8 w-8 rounded-full object-cover shrink-0" />
              ) : (
                <div className="h-8 w-8 rounded-full bg-soft-pink flex items-center justify-center text-wine shrink-0">
                  <User size={14} />
                </div>
              )}
              <div className="flex-1 min-w-0 rounded-2xl bg-cream px-3 py-2">
                <p className="text-xs font-semibold text-ink">{c.userName}</p>
                <p className="text-sm text-ink leading-snug">{c.comment}</p>
                <p className="text-[11px] text-subtext mt-0.5">{timeAgo(c.createdAt)}</p>
              </div>
            </div>
          ))}

          {currentUserId && (
            <form onSubmit={handleSubmitComment} className="flex items-center gap-2">
              <input
                value={commentText}
                onChange={(e) => setCommentText(e.target.value)}
                placeholder="Write a comment..."
                className="flex-1 rounded-full border border-divider bg-cream/50 px-4 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-wine/40 focus:border-wine transition-all"
              />
              <button
                type="submit"
                disabled={submitting || !commentText.trim()}
                className="h-9 w-9 shrink-0 flex items-center justify-center rounded-full bg-wine text-white hover:bg-wine-dark transition-all hover:scale-105 disabled:opacity-50"
                aria-label="Send comment"
              >
                {submitting ? <Loader2 size={15} className="animate-spin" /> : <Send size={15} />}
              </button>
            </form>
          )}
        </div>
      )}
    </Card>
  );
}
