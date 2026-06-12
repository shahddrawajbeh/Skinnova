import { api, aiApi } from "./api";

export const scanService = {
  async getWebQuota(userId) {
    const { data } = await api.get(`/skin-scan/web-quota/${userId}`);
    return data; // { allowed }
  },

  async claimWebQuota(userId) {
    const { data } = await api.post(`/skin-scan/web-quota/claim`, { userId });
    return data; // { allowed, message? }
  },

  async checkImage(file) {
    const form = new FormData();
    form.append("image", file);
    const { data } = await aiApi.post("/check-image", form, {
      headers: { "Content-Type": "multipart/form-data" },
    });
    return data; // { isValid, message }
  },

  async analyzeSkin(file) {
    const form = new FormData();
    form.append("image", file);
    const { data } = await aiApi.post("/analyze-skin", form, {
      headers: { "Content-Type": "multipart/form-data" },
    });
    return data; // { skinScore, potentialScore, mainConcern, metrics[], morningRoutine[], nightRoutine[] }
  },

  async saveScan({ userId, file, detectedConcerns, morningRoutine, eveningRoutine, overallStatus, skinScore }) {
    const form = new FormData();
    form.append("userId", userId);
    if (file) form.append("image", file);
    form.append("detectedConcerns", JSON.stringify(detectedConcerns || []));
    form.append("morningRoutine", JSON.stringify(morningRoutine || []));
    form.append("eveningRoutine", JSON.stringify(eveningRoutine || []));
    form.append("overallStatus", overallStatus || "");
    if (skinScore != null) form.append("skinScore", skinScore);
    const { data } = await api.post("/skin-scan/", form, {
      headers: { "Content-Type": "multipart/form-data" },
    });
    return data;
  },

  async getHistory(userId) {
    const { data } = await api.get(`/skin-scan/history/${userId}`);
    return data;
  },

  async deleteScan(scanId) {
    const { data } = await api.delete(`/skin-scan/${scanId}`);
    return data;
  },
};
