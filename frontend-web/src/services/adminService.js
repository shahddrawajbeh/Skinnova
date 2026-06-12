import { api } from "./api";

export const adminService = {
  // Dashboard
  fetchStats: async () => (await api.get("/admin/stats")).data,
  fetchReportsStats: async () => (await api.get("/admin/reports/stats")).data,

  // Users
  fetchUsers: async (params) => (await api.get("/admin/users", { params })).data,
  fetchUser: async (id) => (await api.get(`/admin/users/${id}`)).data,
  updateUser: async (id, payload) => (await api.put(`/admin/users/${id}`, payload)).data,
  toggleUserActive: async (id) => (await api.patch(`/admin/users/${id}/toggle-active`)).data,
  updateUserRole: async (id, role) => (await api.patch(`/admin/users/${id}/role`, { role })).data,
  deleteUser: async (id) => (await api.delete(`/admin/users/${id}`)).data,

  // Stores
  fetchStores: async (params) => (await api.get("/admin/stores", { params })).data,
  fetchPendingStores: async () => (await api.get("/admin/stores/pending-approval")).data,
  fetchStore: async (id) => (await api.get(`/admin/stores/${id}`)).data,
  updateStore: async (id, payload) => (await api.put(`/admin/stores/${id}`, payload)).data,
  toggleStoreActive: async (id) => (await api.patch(`/admin/stores/${id}/toggle-active`)).data,
  approveStore: async (id) => (await api.patch(`/admin/stores/${id}/approve`)).data,
  rejectStore: async (id, rejectionReason) =>
    (await api.patch(`/admin/stores/${id}/reject`, { rejectionReason })).data,
  setStoreBadge: async (id, payload) => (await api.patch(`/admin/stores/${id}/badge`, payload)).data,
  deleteStore: async (id) => (await api.delete(`/admin/stores/${id}`)).data,

  // Products
  fetchProducts: async (params) => (await api.get("/admin/products", { params })).data,
  fetchProduct: async (id) => (await api.get(`/admin/products/${id}`)).data,
  toggleProductHidden: async (id) => (await api.patch(`/admin/products/${id}/toggle-hidden`)).data,
  deleteProduct: async (id) => (await api.delete(`/admin/products/${id}`)).data,

  // Orders
  fetchOrders: async (params) => (await api.get("/admin/orders", { params })).data,
  fetchOrder: async (id) => (await api.get(`/admin/orders/${id}`)).data,
  updateOrderStatus: async (id, status) =>
    (await api.patch(`/admin/orders/${id}/status`, { status })).data,

  // Analytics
  fetchAnalyticsCharts: async () => (await api.get("/admin/analytics/charts")).data,

  // Reports
  fetchReport: async (type, params) => (await api.get(`/admin/reports/${type}`, { params })).data,
  exportReportCsv: async (type, params) =>
    (await api.get(`/admin/reports/${type}`, { params: { ...params, export: "csv" }, responseType: "blob" })).data,

  // Notifications
  fetchSentNotifications: async (params) => (await api.get("/admin/notifications", { params })).data,
  sendToAllUsers: async (payload) => (await api.post("/admin/notifications/all-users", payload)).data,
  sendToUser: async (userId, payload) =>
    (await api.post(`/admin/notifications/user/${userId}`, payload)).data,
  sendToStoreFollowers: async (storeId, payload) =>
    (await api.post(`/admin/notifications/store-followers/${storeId}`, payload)).data,
  sendBySkinConcern: async (payload) => (await api.post("/admin/notifications/skin-concern", payload)).data,

  // Settings
  fetchSettings: async () => (await api.get("/admin/settings")).data,
  updateSettings: async (payload) => (await api.put("/admin/settings", payload)).data,

  // Support
  fetchSupportMessages: async (params) => (await api.get("/support/user-messages", { params })).data,
  updateSupportMessageStatus: async (id, status, adminNote) =>
    (await api.put(`/support/user-messages/${id}/status`, { status, adminNote })).data,
  deleteSupportMessage: async (id) => (await api.delete(`/support/user-messages/${id}`)).data,

  fetchStoreReports: async (params) => (await api.get("/store-reports", { params })).data,
  markStoreReportReviewed: async (id, adminNote) =>
    (await api.put(`/store-reports/${id}/reviewed`, { adminNote })).data,
  markStoreReportDismissed: async (id, adminNote) =>
    (await api.put(`/store-reports/${id}/dismissed`, { adminNote })).data,

  // Group post moderation
  fetchGroupPosts: async (params) => (await api.get("/admin/group-posts", { params })).data,
  toggleGroupPostHidden: async (id) => (await api.patch(`/admin/group-posts/${id}/toggle-hidden`)).data,
  setGroupPostApprovalStatus: async (id, approvalStatus) =>
    (await api.patch(`/admin/group-posts/${id}/approval-status`, { approvalStatus })).data,
};
