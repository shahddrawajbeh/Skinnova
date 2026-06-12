import { api } from "./api";

export const favoriteService = {
  async fetchFavorites(userId) {
    const { data } = await api.get(`/favorites/${userId}`);
    return Array.isArray(data) ? data : data?.favorites || [];
  },

  async toggleFavorite(userId, productId) {
    const { data } = await api.post("/favorites/toggle", { userId, productId });
    return data; // { isFavorite }
  },
};
