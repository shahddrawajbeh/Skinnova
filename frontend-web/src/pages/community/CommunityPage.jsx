import { useEffect, useMemo, useState } from "react";
import { Loader2, Users, MessagesSquare } from "lucide-react";
import SectionHeader from "../../components/common/SectionHeader";
import HorizontalSlider from "../../components/common/HorizontalSlider";
import { SkeletonRow, SkeletonCard } from "../../components/common/Skeleton";
import EmptyState from "../../components/common/EmptyState";
import Button from "../../components/common/Button";
import GroupCard from "../../components/community/GroupCard";
import CommunityPostCard from "../../components/community/CommunityPostCard";
import PostComposer from "../../components/community/PostComposer";
import { useAuth } from "../../context/AuthContext";
import { useToast } from "../../context/ToastContext";
import { communityService } from "../../services/communityService";

const LIMIT = 10;

const FILTERS = [
  { value: "latest", label: "Latest" },
  { value: "trending", label: "Trending" },
  { value: "myGroups", label: "My Groups", authOnly: true },
  { value: "following", label: "Following", authOnly: true },
  { value: "tip", label: "Tips" },
  { value: "review", label: "Reviews" },
  { value: "routine", label: "Routines" },
  { value: "before_after", label: "Before & After" },
  { value: "question", label: "Questions" },
];

function applyGuestFilter(posts, filter) {
  if (["question", "tip", "review", "routine", "before_after"].includes(filter)) {
    return posts.filter((p) => p.postType === filter);
  }
  if (filter === "trending") {
    return [...posts].sort((a, b) => {
      const scoreA = (a.reactions?.length || 0) + (a.comments?.length || 0);
      const scoreB = (b.reactions?.length || 0) + (b.comments?.length || 0);
      return scoreB - scoreA;
    });
  }
  return posts;
}

export default function CommunityPage() {
  const { isAuthenticated, user, profile } = useAuth();
  const toast = useToast();

  const [filter, setFilter] = useState("latest");
  const [posts, setPosts] = useState([]);
  const [allGuestPosts, setAllGuestPosts] = useState([]);
  const [guestVisible, setGuestVisible] = useState(LIMIT);
  const [page, setPage] = useState(1);
  const [hasMore, setHasMore] = useState(false);
  const [loadingPosts, setLoadingPosts] = useState(true);
  const [loadingMore, setLoadingMore] = useState(false);

  const [myGroups, setMyGroups] = useState([]);
  const [discoverGroups, setDiscoverGroups] = useState([]);
  const [loadingGroups, setLoadingGroups] = useState(true);

  useEffect(() => {
    let mounted = true;
    const promise = isAuthenticated
      ? Promise.all([
          communityService.fetchMyGroups(user.userId),
          communityService.fetchSuggestedGroups(user.userId),
        ]).then(([mine, suggested]) => {
          if (!mounted) return;
          setMyGroups(mine);
          setDiscoverGroups(suggested);
        })
      : communityService.fetchGroups().then((groups) => {
          if (mounted) setDiscoverGroups(groups);
        });

    promise.catch(() => {}).finally(() => mounted && setLoadingGroups(false));
    return () => {
      mounted = false;
    };
  }, [isAuthenticated, user?.userId]);

  useEffect(() => {
    let mounted = true;
    setLoadingPosts(true);

    if (isAuthenticated) {
      communityService
        .fetchFeed({ userId: user.userId, filter, page: 1, limit: LIMIT })
        .then((data) => {
          if (!mounted) return;
          setPosts(data);
          setPage(1);
          setHasMore(data.length === LIMIT);
        })
        .catch(() => mounted && setPosts([]))
        .finally(() => mounted && setLoadingPosts(false));
    } else {
      communityService
        .fetchPosts()
        .then((data) => {
          if (!mounted) return;
          setAllGuestPosts(data);
          setGuestVisible(LIMIT);
        })
        .catch(() => mounted && setAllGuestPosts([]))
        .finally(() => mounted && setLoadingPosts(false));
    }

    return () => {
      mounted = false;
    };
  }, [filter, isAuthenticated, user?.userId]);

  const guestFiltered = useMemo(() => applyGuestFilter(allGuestPosts, filter), [allGuestPosts, filter]);
  const displayPosts = isAuthenticated ? posts : guestFiltered.slice(0, guestVisible);
  const showLoadMore = isAuthenticated ? hasMore : guestFiltered.length > guestVisible;

  const updatePost = (postId, patch) => {
    const updater = (list) => list.map((p) => (p._id === postId ? { ...p, ...patch } : p));
    if (isAuthenticated) setPosts(updater);
    else setAllGuestPosts(updater);
  };

  const handlePostCreated = (post) => {
    if (isAuthenticated) setPosts((prev) => [post, ...prev]);
    else setAllGuestPosts((prev) => [post, ...prev]);
  };

  const handleLoadMore = async () => {
    if (!isAuthenticated) {
      setGuestVisible((v) => v + LIMIT);
      return;
    }
    setLoadingMore(true);
    try {
      const nextPage = page + 1;
      const data = await communityService.fetchFeed({ userId: user.userId, filter, page: nextPage, limit: LIMIT });
      setPosts((prev) => [...prev, ...data]);
      setPage(nextPage);
      setHasMore(data.length === LIMIT);
    } catch {
      toast.error("Couldn't load more posts.");
    } finally {
      setLoadingMore(false);
    }
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

  const visibleFilters = FILTERS.filter((f) => !f.authOnly || isAuthenticated);

  return (
    <div className="flex flex-col gap-10 animate-fade-slide-in">
      <div className="gradient-banner rounded-3xl px-6 py-10 sm:px-10 sm:py-14 text-white relative overflow-hidden">
        <div className="absolute -top-12 -right-12 h-48 w-48 rounded-full bg-white/10 blur-3xl" />
        <div className="relative">
          <h1 className="font-display text-3xl sm:text-4xl font-bold mb-2">Community</h1>
          <p className="text-white/85 text-sm sm:text-base max-w-xl">
            Tips, reviews, routines, and before/after stories shared by people on their skincare journey.
          </p>
        </div>
      </div>

      {isAuthenticated && myGroups.length > 0 && (
        <section>
          <SectionHeader title="My Groups" subtitle="Communities you're part of" />
          <HorizontalSlider>
            {myGroups.map((g) => (
              <GroupCard key={g._id} group={g} />
            ))}
          </HorizontalSlider>
        </section>
      )}

      <section>
        <SectionHeader title="Discover Groups" subtitle="Find your people" />
        {loadingGroups ? (
          <SkeletonRow count={4} itemClassName="w-60 h-32" />
        ) : discoverGroups.length > 0 ? (
          <HorizontalSlider>
            {discoverGroups.map((g) => (
              <GroupCard key={g._id} group={g} />
            ))}
          </HorizontalSlider>
        ) : (
          <EmptyState icon={Users} title="No groups yet" message="Check back soon for new communities." />
        )}
      </section>

      {isAuthenticated && <PostComposer onPostCreated={handlePostCreated} />}

      <section className="flex flex-col gap-4">
        <div className="flex flex-wrap gap-2">
          {visibleFilters.map((f) => (
            <button
              key={f.value}
              type="button"
              onClick={() => setFilter(f.value)}
              className={`rounded-full px-4 py-2 text-sm font-semibold transition-all hover:scale-105
                ${filter === f.value ? "bg-wine text-white shadow-md shadow-wine/20" : "bg-soft-pink text-wine hover:bg-dusty-rose-light"}`}
            >
              {f.label}
            </button>
          ))}
        </div>

        {loadingPosts ? (
          <div className="flex flex-col gap-4">
            {Array.from({ length: 3 }).map((_, i) => (
              <SkeletonCard key={i} className="h-40 w-full" />
            ))}
          </div>
        ) : displayPosts.length > 0 ? (
          <div className="flex flex-col gap-4">
            {displayPosts.map((post) => (
              <CommunityPostCard
                key={post._id}
                post={post}
                currentUserId={user?.userId}
                onReact={handleReact}
                onAddComment={handleAddComment}
              />
            ))}
            {showLoadMore && (
              <Button onClick={handleLoadMore} disabled={loadingMore} variant="secondary" className="self-center">
                {loadingMore ? <Loader2 size={15} className="animate-spin" /> : null}
                Load more
              </Button>
            )}
          </div>
        ) : (
          <EmptyState
            icon={MessagesSquare}
            title="No posts yet"
            message="Be the first to share a tip, routine, or update with the community."
          />
        )}
      </section>
    </div>
  );
}
