import { useRef, useState } from "react";
import { Megaphone, Lightbulb, ListChecks, Images, Loader2, Send, X } from "lucide-react";
import Card from "../common/Card";
import Button from "../common/Button";
import { useAuth } from "../../context/AuthContext";
import { useToast } from "../../context/ToastContext";
import { communityService } from "../../services/communityService";

const POST_TYPES = [
  { value: "update", label: "Update", icon: Megaphone },
  { value: "tip", label: "Tip", icon: Lightbulb },
  { value: "routine", label: "Routine", icon: ListChecks },
  { value: "before_after", label: "Before & After", icon: Images },
];

export default function PostComposer({ onPostCreated, groupContext }) {
  const { user, profile } = useAuth();
  const toast = useToast();
  const fileRef = useRef(null);

  const [postType, setPostType] = useState("update");
  const [content, setContent] = useState("");
  const [imageFile, setImageFile] = useState(null);
  const [imagePreview, setImagePreview] = useState(null);
  const [submitting, setSubmitting] = useState(false);

  const handleFileChange = (e) => {
    const file = e.target.files?.[0];
    if (!file) return;
    setImageFile(file);
    setImagePreview(URL.createObjectURL(file));
  };

  const removeImage = () => {
    setImageFile(null);
    setImagePreview(null);
    if (fileRef.current) fileRef.current.value = "";
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!content.trim()) {
      toast.error("Write something before posting.");
      return;
    }

    setSubmitting(true);
    try {
      let images = [];
      if (imageFile) {
        const uploaded = await communityService.uploadImage(imageFile);
        if (uploaded?.imageUrl) images = [uploaded.imageUrl];
      }

      const { post } = await communityService.addPost({
        userId: user.userId,
        userName: profile?.fullName || "Skinova user",
        userAvatar: profile?.profileImage || "",
        content: content.trim(),
        images,
        postType,
        groupId: groupContext?.groupId,
        groupTitle: groupContext?.groupTitle,
        groupSlug: groupContext?.groupSlug,
      });

      onPostCreated(post);
      setContent("");
      removeImage();
      setPostType("update");
      toast.success("Posted to the community!");
    } catch (err) {
      toast.error(err.response?.data?.message || "Couldn't share your post.");
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <Card className="p-4 sm:p-5 flex flex-col gap-3">
      <form onSubmit={handleSubmit} className="flex flex-col gap-3">
        <textarea
          value={content}
          onChange={(e) => setContent(e.target.value)}
          placeholder="Share a tip, routine, or update with the community..."
          rows={3}
          className="w-full rounded-2xl border border-divider bg-cream/50 px-4 py-3 text-sm focus:outline-none focus:ring-2 focus:ring-wine/40 focus:border-wine transition-all resize-none"
        />

        {imagePreview && (
          <div className="relative h-32 w-32 rounded-xl overflow-hidden">
            <img src={imagePreview} alt="" className="h-full w-full object-cover" />
            <button
              type="button"
              onClick={removeImage}
              className="absolute top-1 right-1 h-6 w-6 rounded-full bg-black/50 text-white flex items-center justify-center hover:bg-black/70 transition-colors"
              aria-label="Remove image"
            >
              <X size={13} />
            </button>
          </div>
        )}

        <div className="flex flex-wrap items-center gap-2">
          {POST_TYPES.map((t) => (
            <button
              key={t.value}
              type="button"
              onClick={() => setPostType(t.value)}
              className={`flex items-center gap-1.5 rounded-full px-3 py-1.5 text-xs font-semibold transition-all hover:scale-105
                ${postType === t.value ? "bg-wine text-white" : "bg-soft-pink text-wine hover:bg-dusty-rose-light"}`}
            >
              <t.icon size={13} /> {t.label}
            </button>
          ))}
        </div>

        <div className="flex items-center justify-between gap-3 pt-1">
          <label className="flex items-center gap-1.5 text-xs font-semibold text-subtext hover:text-wine cursor-pointer transition-colors">
            <Images size={15} /> Add photo
            <input ref={fileRef} type="file" accept="image/*" onChange={handleFileChange} className="hidden" />
          </label>
          <Button type="submit" disabled={submitting} size="sm">
            {submitting ? <Loader2 size={14} className="animate-spin" /> : <Send size={14} />}
            Post
          </Button>
        </div>
      </form>
    </Card>
  );
}
