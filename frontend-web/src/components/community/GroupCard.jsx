import { Link } from "react-router-dom";
import { Users, Sparkles } from "lucide-react";
import Card from "../common/Card";
import { resolveImageUrl } from "../../services/api";

const GROUP_TYPE_LABELS = {
  skin_types: "Skin type",
  skin_type: "Skin type",
  skin_colors: "Skin tone",
  skin_tones: "Skin tone",
  skin_concerns: "Concern",
  product_categories: "Category",
  medications: "Medication",
};

export default function GroupCard({ group }) {
  return (
    <Link to={`/community/group/${group.slug}`}>
      <Card className="w-60 sm:w-64 overflow-hidden flex flex-col group">
        <div className="relative h-20 bg-soft-pink overflow-hidden">
          {group.coverImage ? (
            <img
              src={resolveImageUrl(group.coverImage)}
              alt=""
              className="h-full w-full object-cover transition-transform duration-500 group-hover:scale-110"
            />
          ) : (
            <div className="h-full w-full gradient-banner" />
          )}
          <div className="absolute -bottom-6 left-4 h-12 w-12 rounded-2xl bg-white shadow-md border border-divider flex items-center justify-center overflow-hidden">
            {group.profileImage ? (
              <img src={resolveImageUrl(group.profileImage)} alt={group.title} className="h-full w-full object-cover" />
            ) : (
              <Sparkles size={20} className="text-wine" />
            )}
          </div>
          {group.hasNewActivity && (
            <span className="absolute top-2 right-2 h-2.5 w-2.5 rounded-full bg-gold ring-2 ring-white animate-pulse-soft" />
          )}
        </div>
        <div className="p-4 pt-8 flex flex-col gap-1.5">
          <p className="font-semibold text-ink truncate">{group.title}</p>
          <div className="flex items-center gap-3 text-xs text-subtext">
            <span className="flex items-center gap-1">
              <Users size={12} /> {group.membersCount || 0} members
            </span>
            {GROUP_TYPE_LABELS[group.groupType] && (
              <span className="px-2 py-0.5 rounded-full bg-soft-pink text-wine font-medium">
                {GROUP_TYPE_LABELS[group.groupType]}
              </span>
            )}
          </div>
        </div>
      </Card>
    </Link>
  );
}
