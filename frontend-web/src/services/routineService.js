import { api } from "./api";

export const routineService = {
  async saveAiRoutine({ userId, detectedConcerns, morning, evening }) {
    const { data } = await api.post("/routines/ai", {
      userId,
      detectedConcerns,
      morning,
      evening,
    });
    return data;
  },

  async getActiveRoutine(userId) {
    try {
      const { data } = await api.get(`/routines/active/${userId}`);
      return data;
    } catch (err) {
      if (err.response?.status === 404) return null;
      throw err;
    }
  },

  async getProgress(userId, routineId) {
    const { data } = await api.get(`/routines/progress/${userId}/${routineId}`);
    return data;
  },

  async toggleStep({ userId, routineId, stepId }) {
    const { data } = await api.post("/routines/progress/toggle", { userId, routineId, stepId });
    return data;
  },

  async addCustomStep({ userId, step, notes, reminderTime }) {
    const { data } = await api.post("/routines/custom-step", { userId, step, notes, reminderTime });
    return data;
  },

  async updateCustomStep(routineId, stepId, updates) {
    const { data } = await api.put(`/routines/custom-step/${routineId}/${stepId}`, updates);
    return data;
  },

  async deleteCustomStep(routineId, stepId) {
    const { data } = await api.delete(`/routines/custom-step/${routineId}/${stepId}`);
    return data;
  },

  async getRecommendedProducts({ productCategory, keyIngredient, searchTags, concernTarget }) {
    const { data } = await api.post("/routines/recommended-products", {
      productCategory,
      keyIngredient,
      searchTags,
      concernTarget,
    });
    return data;
  },
};
