import { api } from "./api";

export const storeOwnerService = {
  async fetchMyStore(sellerId) {
    const { data } = await api.get(`/stores/seller/${sellerId}`);
    return data;
  },

  async updateStore(storeId, payload) {
    const { data } = await api.put(`/stores/${storeId}`, payload);
    return data;
  },

  async uploadLogo(storeId, file) {
    const form = new FormData();
    form.append("image", file);
    const { data } = await api.put(`/stores/${storeId}/upload-logo`, form, {
      headers: { "Content-Type": "multipart/form-data" },
    });
    return data;
  },

  async uploadCover(storeId, file) {
    const form = new FormData();
    form.append("image", file);
    const { data } = await api.put(`/stores/${storeId}/upload-cover`, form, {
      headers: { "Content-Type": "multipart/form-data" },
    });
    return data;
  },

  async addGalleryImage(storeId, file) {
    const form = new FormData();
    form.append("image", file);
    const { data } = await api.post(`/stores/${storeId}/gallery`, form, {
      headers: { "Content-Type": "multipart/form-data" },
    });
    return data;
  },

  async removeGalleryImage(storeId, url) {
    const { data } = await api.delete(`/stores/${storeId}/gallery`, { data: { url } });
    return data;
  },

  async fetchAnalytics(storeId) {
    const { data } = await api.get(`/stores/${storeId}/analytics`);
    return data;
  },

  async fetchTimeseries(storeId, days = 30) {
    const { data } = await api.get(`/stores/${storeId}/analytics/timeseries`, {
      params: { days },
    });
    return Array.isArray(data) ? data : [];
  },

  async fetchReviews(storeId) {
    const { data } = await api.get(`/stores/${storeId}/reviews`);
    return Array.isArray(data) ? data : data?.reviews || [];
  },

  async replyToReview(storeId, reviewId, comment) {
    const { data } = await api.put(`/stores/${storeId}/reviews/${reviewId}/reply`, { comment });
    return data;
  },

  async fetchStoreProducts(storeId, all = true) {
    const { data } = await api.get(`/store-products/store/${storeId}`, {
      params: all ? { all: "true" } : {},
    });
    return Array.isArray(data) ? data : data?.products || [];
  },

  async addStoreProduct(payload) {
    const { data } = await api.post("/store-products", payload);
    return data;
  },

  async updateStoreProduct(id, payload) {
    const { data } = await api.put(`/store-products/${id}`, payload);
    return data;
  },

  async deleteStoreProduct(id) {
    const { data } = await api.delete(`/store-products/${id}`);
    return data;
  },

  async createProduct(payload) {
    const { data } = await api.post("/products", payload);
    return data;
  },

  async updateProduct(id, payload) {
    const { data } = await api.put(`/products/${id}`, payload);
    return data;
  },

  async uploadProductImage(file) {
    const form = new FormData();
    form.append("image", file);
    const { data } = await api.post("/products/upload-image", form, {
      headers: { "Content-Type": "multipart/form-data" },
    });
    return data; // { imageUrl }
  },

  async fetchOrders(storeId) {
    const { data } = await api.get(`/orders/store/${storeId}`);
    return data?.orders || [];
  },

  async fetchOrderDetail(orderId) {
    const { data } = await api.get(`/orders/detail/${orderId}`);
    return data?.order || data;
  },

  async updateOrderStatus(orderId, status) {
    const { data } = await api.put(`/orders/${orderId}/status`, { status });
    return data;
  },
};
