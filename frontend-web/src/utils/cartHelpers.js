import { storeService } from "../services/storeService";
import { cartService } from "../services/cartService";

// Adds a product to the cart using its cheapest in-stock store offer.
// Returns true on success, false if no offer is available.
export async function quickAddToCart({ userId, product, toast, quantity = 1 }) {
  try {
    const offers = await storeService.fetchProductOffers(product._id);
    const offer = offers.find((o) => o.isAvailable && o.stockCount > 0);
    if (!offer) {
      toast.error("This product isn't available in any store right now.");
      return false;
    }
    await cartService.addToCart({
      userId,
      productId: product._id,
      storeId: offer.storeId?._id || offer.storeId,
      quantity,
      price: offer.price,
      currency: offer.currency,
    });
    toast.success("Added to cart!");
    return true;
  } catch (err) {
    toast.error(err.response?.data?.message || "Couldn't add this product to your cart.");
    return false;
  }
}
