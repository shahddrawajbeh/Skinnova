import { api } from "./api";

export const productService = {
  async fetchProducts() {
    const { data } = await api.get("/products");
    return Array.isArray(data) ? data : data?.products || [];
  },

  async fetchProductById(id) {
    const { data } = await api.get(`/products/${id}`);
    return data;
  },

  async fetchByBrand(brand) {
    const { data } = await api.get(`/products/brand/${encodeURIComponent(brand)}`);
    return Array.isArray(data) ? data : data?.products || [];
  },

  async fetchByConcern(concern) {
    const { data } = await api.get(`/products/concern/${encodeURIComponent(concern)}`);
    return Array.isArray(data) ? data : data?.products || [];
  },

  async addReview(productId, payload) {
    const { data } = await api.post(`/products/${productId}/reviews`, payload);
    return data;
  },
};
