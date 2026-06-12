import { api } from "./api";

export const authService = {
  async login(email, password) {
    const { data } = await api.post("/auth/login", {
      email,
      password,
      platform: "web",
    });
    return data; // { message, userId, role, fullName, email }
  },

  async register(fullName, email, password) {
    const { data } = await api.post("/auth/register", {
      fullName,
      email,
      password,
    });
    return data; // { message, userId }
  },

  async getProfile(userId) {
    const { data } = await api.get(`/auth/user/${userId}`);
    return data;
  },

  async updateProfile(userId, payload) {
    const { data } = await api.put(`/auth/update-profile/${userId}`, payload);
    return data;
  },

  async saveOnboarding(userId, payload) {
    const { data } = await api.put(`/auth/onboarding/${userId}`, payload);
    return data;
  },

  async uploadProfileImage(userId, file) {
    const form = new FormData();
    form.append("image", file);
    const { data } = await api.put(`/auth/upload-profile-image/${userId}`, form, {
      headers: { "Content-Type": "multipart/form-data" },
    });
    return data;
  },

  async changePassword(userId, currentPassword, newPassword) {
    const { data } = await api.put(`/auth/change-password/${userId}`, {
      currentPassword,
      newPassword,
    });
    return data;
  },

  async followUser(targetUserId, currentUserId) {
    const { data } = await api.post(`/auth/${targetUserId}/follow`, { currentUserId });
    return data;
  },

  async unfollowUser(targetUserId, currentUserId) {
    const { data } = await api.post(`/auth/${targetUserId}/unfollow`, { currentUserId });
    return data;
  },
};
