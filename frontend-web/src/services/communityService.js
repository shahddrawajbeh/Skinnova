import { api } from "./api";

export const communityService = {
  async fetchFeed({ userId, filter = "all", page = 1, limit = 10 } = {}) {
    const { data } = await api.get("/group-posts/feed", {
      params: { userId, filter, page, limit },
    });
    return Array.isArray(data) ? data : [];
  },

  async fetchPosts() {
    const { data } = await api.get("/group-posts");
    return Array.isArray(data) ? data : [];
  },

  async fetchGroups() {
    const { data } = await api.get("/groups");
    return Array.isArray(data) ? data : data?.groups || [];
  },

  async fetchMyGroups(userId) {
    const { data } = await api.get(`/groups/my-groups/${userId}`);
    return Array.isArray(data) ? data : [];
  },

  async fetchSuggestedGroups(userId) {
    const { data } = await api.get(`/groups/suggested/${userId}`);
    return Array.isArray(data) ? data : [];
  },

  async fetchGroupBySlug(slug) {
    const { data } = await api.get(`/groups/${slug}`);
    return data;
  },

  async fetchGroupPosts(slug) {
    const { data } = await api.get(`/group-posts/group/${slug}`);
    return Array.isArray(data) ? data : data?.posts || [];
  },

  async fetchGroupProducts(slug) {
    const { data } = await api.get(`/groups/${slug}/products`);
    return Array.isArray(data) ? data : data?.products || [];
  },

  async joinGroup(slug, userId) {
    const { data } = await api.post(`/groups/${slug}/join`, { userId });
    return data;
  },

  async leaveGroup(slug, userId) {
    const { data } = await api.post(`/groups/${slug}/leave`, { userId });
    return data;
  },

  async getJoinStatus(slug, userId) {
    const { data } = await api.get(`/groups/${slug}/join-status/${userId}`);
    return data;
  },

  async toggleReaction(postId, userId, type) {
    const { data } = await api.put(`/group-posts/${postId}/reaction`, { userId, type });
    return data;
  },

  async toggleLike(postId, userId) {
    const { data } = await api.put(`/group-posts/${postId}/like`, { userId });
    return data;
  },

  async addComment(postId, payload) {
    const { data } = await api.post(`/group-posts/${postId}/comments`, payload);
    return data;
  },

  async uploadImage(file) {
    const form = new FormData();
    form.append("image", file);
    const { data } = await api.post("/group-posts/upload", form, {
      headers: { "Content-Type": "multipart/form-data" },
    });
    return data; // { url }
  },

  async addPost(payload) {
    const { data } = await api.post("/group-posts/update", payload);
    return data;
  },
};
