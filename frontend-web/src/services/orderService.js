import { api } from "./api";

export const orderService = {
  async createOrder(payload) {
    const { data } = await api.post("/orders/create", payload);
    return data;
  },

  async fetchOrders(userId) {
    const { data } = await api.get(`/orders/${userId}`);
    return data?.orders || data || [];
  },

  async fetchOrderById(orderId) {
    const { data } = await api.get(`/orders/detail/${orderId}`);
    return data?.order || data;
  },

  async confirmReceived(orderId, userId) {
    const { data } = await api.put(`/orders/confirm-received/${orderId}`, { userId });
    return data;
  },

  async rateStore(orderId, payload) {
    const { data } = await api.post(`/orders/${orderId}/rate-store`, payload);
    return data;
  },

  async fetchPurchaseHistory(userId) {
    const { data } = await api.get(`/orders/purchase-history/${userId}`);
    return data?.data || data;
  },
};
