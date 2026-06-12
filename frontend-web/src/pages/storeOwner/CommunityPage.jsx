import { useEffect, useState } from "react";
import { Loader2, MessagesSquare } from "lucide-react";
import EmptyState from "../../components/common/EmptyState";
import CommunityPostCard from "../../components/community/CommunityPostCard";
import PostComposer from "../../components/community/PostComposer";
import { useAuth } from "../../context/AuthContext";
import { useToast } from "../../context/ToastContext";
import { communityService } from "../../services/communityService";

export default function CommunityPage() {
  const { user, profile } = useAuth();
  const toast = useToast();
  const [posts, setPosts] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    communityService
      .fetchFeed({ userId: user.userId, filter: "mine", limit: 50 })
      .then(setPosts)
      .catch(() => toast.error("Couldn't load your posts."))
      .finally(() => setLoading(false));
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const updatePost = (id, changes) => {
    setPosts((prev) => prev.map((p) => (p._id === id ? { ...p, ...changes } : p)));
  };

  const handlePostCreated = (post) => setPosts((prev) => [post, ...prev]);

  const handleReact = async (postId, type) => {
    try {
      const { reactions } = await communityService.toggleReaction(postId, user.userId, type);
      updatePost(postId, { reactions });
    } catch {
      toast.error("Couldn't update your reaction.");
    }
  };

  const handleAddComment = async (postId, text) => {
    try {
      const { comments } = await communityService.addComment(postId, {
        userId: user.userId,
        userName: profile?.fullName || "Store",
        userAvatar: profile?.profileImage || "",
        comment: text,
      });
      updatePost(postId, { comments });
    } catch {
      toast.error("Couldn't post your comment.");
    }
  };

  return (
    <div className="flex flex-col gap-5">
      <div className="animate-fade-slide-in">
        <h2 className="font-display text-2xl font-bold text-ink">Community</h2>
        <p className="text-sm text-subtext mt-1">Share updates and promotions, and engage with your customers.</p>
      </div>

      <PostComposer onPostCreated={handlePostCreated} />

      {loading ? (
        <div className="flex items-center justify-center py-24">
          <Loader2 className="animate-spin text-wine" size={32} />
        </div>
      ) : posts.length === 0 ? (
        <EmptyState
          icon={MessagesSquare}
          title="No posts yet"
          message="Posts you share with the community will show up here."
        />
      ) : (
        <div className="flex flex-col gap-4">
          {posts.map((post) => (
            <CommunityPostCard
              key={post._id}
              post={post}
              currentUserId={user.userId}
              onReact={handleReact}
              onAddComment={handleAddComment}
            />
          ))}
        </div>
      )}
    </div>
  );
}
