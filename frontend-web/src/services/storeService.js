import { api } from "./api";

export const storeService = {
  async fetchStores() {
    const { data } = await api.get("/stores");
    return Array.isArray(data) ? data : data?.stores || [];
  },

  async fetchStoreById(id) {
    const { data } = await api.get(`/stores/${id}`);
    return data;
  },

  async fetchStoreReviews(id) {
    const { data } = await api.get(`/stores/${id}/reviews`);
    return Array.isArray(data) ? data : data?.reviews || [];
  },

  async fetchStoreProducts(storeId) {
    const { data } = await api.get(`/store-products/store/${storeId}`);
    return Array.isArray(data) ? data : data?.products || [];
  },

  async fetchAllStoreProducts() {
    const { data } = await api.get("/store-products");
    return Array.isArray(data) ? data : data?.products || [];
  },

  async fetchTrendingStoreProducts() {
    const { data } = await api.get("/store-products/trending");
    return Array.isArray(data) ? data : data?.products || [];
  },

  async fetchProductOffers(productId) {
    const { data } = await api.get(`/store-products/product/${productId}`);
    return Array.isArray(data) ? data : data?.products || [];
  },
};
