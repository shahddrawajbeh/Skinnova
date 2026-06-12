import { Link } from "react-router-dom";
import { Heart, MessageCircle, ThumbsUp, User } from "lucide-react";
import Card from "../common/Card";
import { resolveImageUrl } from "../../services/api";
import { timeAgo, postTypeStyle } from "../../utils/format";

export default function PostCard({ post, className = "" }) {
  const style = postTypeStyle(post.postType);
  const reactionCount = post.reactions?.length ?? post.likes?.length ?? 0;
  const commentCount = post.comments?.length ?? 0;
  const image = post.images?.[0];

  return (
    <Card className={`p-4 flex flex-col gap-3 ${className}`}>
      <div className="flex items-center gap-3">
        {post.userAvatar ? (
          <img
            src={resolveImageUrl(post.userAvatar)}
            alt={post.userName}
            className="h-9 w-9 rounded-full object-cover"
          />
        ) : (
          <div className="h-9 w-9 rounded-full bg-soft-pink flex items-center justify-center text-wine">
            <User size={16} />
          </div>
        )}
        <div className="min-w-0 flex-1">
          <p className="text-sm font-semibold text-ink truncate">{post.userName}</p>
          <p className="text-xs text-subtext">
            {timeAgo(post.createdAt)}
            {post.groupTitle ? ` · ${post.groupTitle}` : ""}
          </p>
        </div>
        <span className={`shrink-0 text-[11px] font-semibold px-2.5 py-1 rounded-full ${style.bg} ${style.fg}`}>
          {style.label}
        </span>
      </div>

      {post.content && <p className="text-sm text-ink line-clamp-3 leading-relaxed">{post.content}</p>}

      {image && (
        <div className="rounded-xl overflow-hidden aspect-video bg-soft-pink">
          <img src={resolveImageUrl(image)} alt="" className="h-full w-full object-cover" />
        </div>
      )}

      <div className="flex items-center gap-4 text-subtext text-xs pt-1 border-t border-divider mt-1">
        <span className="flex items-center gap-1.5">
          <ThumbsUp size={14} /> {reactionCount}
        </span>
        <span className="flex items-center gap-1.5">
          <MessageCircle size={14} /> {commentCount}
        </span>
        {post.groupSlug && (
          <Link
            to={`/community/group/${post.groupSlug}`}
            className="ml-auto flex items-center gap-1 text-wine font-semibold hover:gap-1.5 transition-all"
          >
            <Heart size={13} /> View group
          </Link>
        )}
      </div>
    </Card>
  );
}
