import { useEffect, useState } from "react";
import { useParams, Link } from "react-router-dom";
import { Loader2, Users, Sparkles, UserPlus, UserCheck, MessagesSquare, ShoppingBag } from "lucide-react";
import Card from "../../components/common/Card";
import Button from "../../components/common/Button";
import SectionHeader from "../../components/common/SectionHeader";
import HorizontalSlider from "../../components/common/HorizontalSlider";
import { SkeletonCard } from "../../components/common/Skeleton";
import EmptyState from "../../components/common/EmptyState";
import ProductCard from "../../components/product/ProductCard";
import CommunityPostCard from "../../components/community/CommunityPostCard";
import PostComposer from "../../components/community/PostComposer";
import { resolveImageUrl } from "../../services/api";
import { useAuth } from "../../context/AuthContext";
import { useToast } from "../../context/ToastContext";
import { communityService } from "../../services/communityService";
import { favoriteService } from "../../services/favoriteService";
import { quickAddToCart } from "../../utils/cartHelpers";

const GROUP_TYPE_LABELS = {
  skin_types: "Skin type",
  skin_type: "Skin type",
  skin_colors: "Skin tone",
  skin_tones: "Skin tone",
  skin_concerns: "Concern",
  product_categories: "Category",
  medications: "Medication",
};

export default function GroupPage() {
  const { slug } = useParams();
  const { isAuthenticated, user, profile } = useAuth();
  const toast = useToast();

  const [group, setGroup] = useState(null);
  const [notFound, setNotFound] = useState(false);
  const [loading, setLoading] = useState(true);

  const [posts, setPosts] = useState([]);
  const [loadingPosts, setLoadingPosts] = useState(true);

  const [products, setProducts] = useState([]);
  const [favoriteIds, setFavoriteIds] = useState(new Set());

  const [isJoined, setIsJoined] = useState(false);
  const [joining, setJoining] = useState(false);
  const [membersCount, setMembersCount] = useState(0);

  useEffect(() => {
    let mounted = true;
    setLoading(true);
    setNotFound(false);

    communityService
      .fetchGroupBySlug(slug)
      .then((data) => {
        if (!mounted) return;
        setGroup(data);
        setMembersCount(data.membersCount || 0);
      })
      .catch(() => mounted && setNotFound(true))
      .finally(() => mounted && setLoading(false));

    setLoadingPosts(true);
    communityService
      .fetchGroupPosts(slug)
      .then((data) => mounted && setPosts(data))
      .catch(() => mounted && setPosts([]))
      .finally(() => mounted && setLoadingPosts(false));

    communityService
      .fetchGroupProducts(slug)
      .then((data) => mounted && setProducts(data))
      .catch(() => {});

    if (isAuthenticated) {
      communityService
        .getJoinStatus(slug, user.userId)
        .then((data) => mounted && setIsJoined(!!data.isJoined))
        .catch(() => {});
      favoriteService
        .fetchFavorites(user.userId)
        .then((favs) => mounted && setFavoriteIds(new Set(favs.map((f) => f._id))))
        .catch(() => {});
    }

    return () => {
      mounted = false;
    };
  }, [slug, isAuthenticated, user?.userId]);

  const handleJoinToggle = async () => {
    if (!isAuthenticated) {
      toast.info("Log in to join this group.");
      return;
    }
    setJoining(true);
    try {
      if (isJoined) {
        const data = await communityService.leaveGroup(slug, user.userId);
        setIsJoined(false);
        if (data.membersCount != null) setMembersCount(data.membersCount);
        toast.success("You left the group.");
      } else {
        const data = await communityService.joinGroup(slug, user.userId);
        setIsJoined(true);
        if (data.membersCount != null) setMembersCount(data.membersCount);
        toast.success("You joined the group!");
      }
    } catch {
      toast.error("Couldn't update your membership.");
    } finally {
      setJoining(false);
    }
  };

  const updatePost = (postId, patch) => {
    setPosts((prev) => prev.map((p) => (p._id === postId ? { ...p, ...patch } : p)));
  };

  const handlePostCreated = (post) => {
    setPosts((prev) => [post, ...prev]);
  };

  const handleReact = async (postId, type) => {
    if (!isAuthenticated) {
      toast.info("Log in to react to posts.");
      return;
    }
    try {
      const { reactions } = await communityService.toggleReaction(postId, user.userId, type);
      updatePost(postId, { reactions });
    } catch {
      toast.error("Couldn't update your reaction.");
    }
  };

  const handleAddComment = async (postId, text) => {
    if (!isAuthenticated) {
      toast.info("Log in to join the conversation.");
      return;
    }
    try {
      const { comments } = await communityService.addComment(postId, {
        userId: user.userId,
        userName: profile?.fullName || "Skinova user",
        userAvatar: profile?.profileImage || "",
        comment: text,
      });
      updatePost(postId, { comments });
    } catch {
      toast.error("Couldn't post your comment.");
    }
  };

  const handleToggleFavorite = async (product) => {
    if (!isAuthenticated) {
      toast.info("Log in to save favorites.");
      return;
    }
    const wasFavorite = favoriteIds.has(product._id);
    setFavoriteIds((prev) => {
      const next = new Set(prev);
      wasFavorite ? next.delete(product._id) : next.add(product._id);
      return next;
    });
    try {
      await favoriteService.toggleFavorite(user.userId, product._id);
    } catch {
      toast.error("Couldn't update favorites.");
      setFavoriteIds((prev) => {
        const next = new Set(prev);
        wasFavorite ? next.add(product._id) : next.delete(product._id);
        return next;
      });
    }
  };

  const handleAddToCart = async (product) => {
    if (!isAuthenticated) {
      toast.info("Log in to add items to your cart.");
      return;
    }
    await quickAddToCart({ userId: user.userId, product, toast });
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center py-24">
        <Loader2 className="animate-spin text-wine" size={32} />
      </div>
    );
  }

  if (notFound || !group) {
    return (
      <EmptyState
        icon={Users}
        title="Group not found"
        action={
          <Button to="/community" variant="secondary">
            Back to community
          </Button>
        }
      />
    );
  }

  return (
    <div className="flex flex-col gap-10 animate-fade-slide-in">
      <Card className="overflow-hidden">
        <div className="relative h-32 sm:h-44 bg-soft-pink">
          {group.coverImage ? (
            <img src={resolveImageUrl(group.coverImage)} alt="" className="h-full w-full object-cover" />
          ) : (
            <div className="h-full w-full gradient-banner" />
          )}
          <div className="absolute -bottom-8 left-6 h-16 w-16 rounded-2xl bg-white shadow-md border border-divider flex items-center justify-center overflow-hidden">
            {group.profileImage ? (
              <img src={resolveImageUrl(group.profileImage)} alt={group.title} className="h-full w-full object-cover" />
            ) : (
              <Sparkles size={26} className="text-wine" />
            )}
          </div>
        </div>
        <div className="p-6 pt-12 flex flex-col sm:flex-row sm:items-end gap-4 justify-between">
          <div>
            <Link to="/community" className="text-sm text-wine hover:underline">
              ← Back to community
            </Link>
            <h1 className="font-display text-2xl sm:text-3xl font-bold text-ink mt-1">{group.title}</h1>
            <div className="flex items-center gap-3 mt-2 text-sm text-subtext">
              <span className="flex items-center gap-1.5">
                <Users size={14} /> {membersCount} member{membersCount === 1 ? "" : "s"}
              </span>
              {GROUP_TYPE_LABELS[group.groupType] && (
                <span className="px-2.5 py-1 rounded-full bg-soft-pink text-wine text-xs font-semibold">
                  {GROUP_TYPE_LABELS[group.groupType]}
                </span>
              )}
            </div>
            {group.description && <p className="text-sm text-subtext mt-3 max-w-xl">{group.description}</p>}
          </div>
          <Button onClick={handleJoinToggle} disabled={joining} variant={isJoined ? "secondary" : "primary"}>
            {joining ? (
              <Loader2 size={15} className="animate-spin" />
            ) : isJoined ? (
              <UserCheck size={15} />
            ) : (
              <UserPlus size={15} />
            )}
            {isJoined ? "Joined" : "Join group"}
          </Button>
        </div>
      </Card>

      {products.length > 0 && (
        <section>
          <SectionHeader title="Recommended Products" subtitle="Popular picks for this group" />
          <HorizontalSlider>
            {products.map((p) => (
              <ProductCard
                key={p._id}
                product={p}
                isFavorite={favoriteIds.has(p._id)}
                onToggleFavorite={handleToggleFavorite}
                onAddToCart={handleAddToCart}
              />
            ))}
          </HorizontalSlider>
        </section>
      )}

      {isAuthenticated && (
        <PostComposer
          onPostCreated={handlePostCreated}
          groupContext={{ groupId: group._id, groupTitle: group.title, groupSlug: group.slug }}
        />
      )}

      <section className="flex flex-col gap-4">
        <h2 className="font-display text-2xl font-bold text-ink">Posts</h2>
        {loadingPosts ? (
          <div className="flex flex-col gap-4">
            {Array.from({ length: 2 }).map((_, i) => (
              <SkeletonCard key={i} className="h-40 w-full" />
            ))}
          </div>
        ) : posts.length > 0 ? (
          posts.map((post) => (
            <CommunityPostCard
              key={post._id}
              post={post}
              currentUserId={user?.userId}
              onReact={handleReact}
              onAddComment={handleAddComment}
            />
          ))
        ) : (
          <EmptyState
            icon={MessagesSquare}
            title="No posts yet"
            message="Be the first to share something with this group."
          />
        )}
      </section>

      {products.length === 0 && (
        <div className="text-center text-sm text-subtext flex items-center justify-center gap-2">
          <ShoppingBag size={15} /> No related products yet for this group.
        </div>
      )}
    </div>
  );
}
