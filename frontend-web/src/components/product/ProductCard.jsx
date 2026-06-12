import { Link } from "react-router-dom";
import { Heart, Star, ShoppingCart } from "lucide-react";
import Card from "../common/Card";
import { resolveImageUrl } from "../../services/api";

export default function ProductCard({ product, isFavorite, onToggleFavorite, onAddToCart, className = "" }) {
  const price = product.price ?? 0;
  const discount = product.discountPercent || 0;
  const finalPrice = discount > 0 ? price * (1 - discount / 100) : price;

  return (
    <Card className={`${className || "w-44 sm:w-52"} overflow-hidden flex flex-col group`}>
      <Link to={`/shop/product/${product._id}`} className="relative block aspect-square overflow-hidden bg-soft-pink">
        {product.imageUrl ? (
          <img
            src={resolveImageUrl(product.imageUrl)}
            alt={product.name}
            className="h-full w-full object-cover transition-transform duration-500 group-hover:scale-110"
          />
        ) : (
          <div className="h-full w-full flex items-center justify-center text-wine/30 font-display text-3xl">
            S
          </div>
        )}
        {discount > 0 && (
          <span className="absolute top-2 left-2 bg-wine text-white text-[11px] font-bold px-2 py-0.5 rounded-full">
            -{discount}%
          </span>
        )}
        {onToggleFavorite && (
          <button
            onClick={(e) => {
              e.preventDefault();
              onToggleFavorite(product);
            }}
            aria-label="Toggle favorite"
            className="absolute top-2 right-2 h-8 w-8 rounded-full bg-white/90 flex items-center justify-center
              text-wine hover:scale-110 transition-transform shadow-sm"
          >
            <Heart size={15} fill={isFavorite ? "currentColor" : "none"} />
          </button>
        )}
      </Link>
      <div className="p-3 flex flex-col gap-1 flex-1">
        <p className="text-[11px] uppercase tracking-wide text-subtext truncate">{product.brand}</p>
        <Link to={`/shop/product/${product._id}`}>
          <p className="text-sm font-semibold text-ink line-clamp-2 leading-snug min-h-[2.5em] hover:text-wine transition-colors">
            {product.name}
          </p>
        </Link>
        {product.rating != null && (
          <div className="flex items-center gap-1 text-xs text-subtext">
            <Star size={12} className="text-gold fill-gold" />
            {Number(product.rating).toFixed(1)}
          </div>
        )}
        <div className="mt-auto flex items-center justify-between pt-2">
          <div>
            {discount > 0 && (
              <span className="text-xs text-subtext line-through mr-1">
                {price} {product.currency || ""}
              </span>
            )}
            <span className="text-sm font-bold text-wine">
              {finalPrice.toFixed(2)} {product.currency || ""}
            </span>
          </div>
          {onAddToCart && (
            <button
              onClick={() => onAddToCart(product)}
              aria-label="Add to cart"
              className="h-8 w-8 rounded-full bg-soft-pink text-wine flex items-center justify-center
                hover:bg-wine hover:text-white transition-all hover:scale-110"
            >
              <ShoppingCart size={14} />
            </button>
          )}
        </div>
      </div>
    </Card>
  );
}
