import { api } from "./api";

export const notificationService = {
  async fetchNotifications(userId) {
    const { data } = await api.get(`/notifications/${userId}`);
    return Array.isArray(data) ? data : data?.notifications || [];
  },

  async getUnreadCount(userId) {
    const { data } = await api.get(`/notifications/${userId}/unread-count`);
    return data?.count ?? 0;
  },

  async markRead(notificationId) {
    const { data } = await api.put(`/notifications/${notificationId}/read`);
    return data;
  },

  async markAllRead(userId) {
    const { data } = await api.put(`/notifications/${userId}/mark-all-read`);
    return data;
  },

  async getSettings(userId) {
    const { data } = await api.get(`/notifications/settings/${userId}`);
    return data;
  },

  async updateSettings(userId, payload) {
    const { data } = await api.put(`/notifications/settings/${userId}`, payload);
    return data;
  },
};
