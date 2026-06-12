import { api } from "./api";

export const cartService = {
  async fetchCart(userId) {
    const { data } = await api.get(`/cart/${userId}`);
    return data?.items || data || [];
  },

  async addToCart({ userId, productId, storeId, quantity, price, currency }) {
    const { data } = await api.post("/cart/add", {
      userId,
      productId,
      storeId,
      quantity,
      price,
      currency,
    });
    return data;
  },

  async updateQuantity({ userId, productId, storeId, quantity }) {
    const { data } = await api.put("/cart/update", { userId, productId, storeId, quantity });
    return data;
  },

  async removeFromCart({ userId, productId, storeId }) {
    const { data } = await api.delete("/cart/remove", { data: { userId, productId, storeId } });
    return data;
  },
};
