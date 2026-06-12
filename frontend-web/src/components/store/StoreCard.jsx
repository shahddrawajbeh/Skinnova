import { Link } from "react-router-dom";
import { Star, Store as StoreIcon, MapPin } from "lucide-react";
import Card from "../common/Card";
import { resolveImageUrl } from "../../services/api";

export default function StoreCard({ store }) {
  return (
    <Link to={`/shop/store/${store._id}`}>
      <Card className="w-60 sm:w-64 overflow-hidden flex flex-col group">
        <div className="relative h-24 bg-soft-pink overflow-hidden">
          {store.coverImageUrl ? (
            <img
              src={resolveImageUrl(store.coverImageUrl)}
              alt=""
              className="h-full w-full object-cover transition-transform duration-500 group-hover:scale-110"
            />
          ) : (
            <div className="h-full w-full gradient-banner" />
          )}
          <div className="absolute -bottom-6 left-4 h-12 w-12 rounded-2xl bg-white shadow-md border border-divider flex items-center justify-center overflow-hidden">
            {store.logoUrl ? (
              <img src={resolveImageUrl(store.logoUrl)} alt={store.storeName} className="h-full w-full object-cover" />
            ) : (
              <StoreIcon size={20} className="text-wine" />
            )}
          </div>
        </div>
        <div className="p-4 pt-8 flex flex-col gap-1.5">
          <p className="font-semibold text-ink truncate">{store.storeName}</p>
          <div className="flex items-center gap-3 text-xs text-subtext">
            {store.rating != null && (
              <span className="flex items-center gap-1">
                <Star size={12} className="text-gold fill-gold" /> {Number(store.rating).toFixed(1)}
              </span>
            )}
            {store.city && (
              <span className="flex items-center gap-1 truncate">
                <MapPin size={12} /> {store.city}
              </span>
            )}
          </div>
        </div>
      </Card>
    </Link>
  );
}
