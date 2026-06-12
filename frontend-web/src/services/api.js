import axios from "axios";

export const api = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL || "http://localhost:5000/api",
});

// Attach the logged-in user's id so the backend can enforce store-ownership
// checks for Store Owner routes. Optional header — mobile app never sends it.
api.interceptors.request.use((config) => {
  const userId = localStorage.getItem("userId");
  if (userId) {
    config.headers["x-user-id"] = userId;
  }
  if (userId && localStorage.getItem("userRole") === "admin") {
    config.headers["x-admin-id"] = userId;
  }
  return config;
});

export const aiApi = axios.create({
  baseURL: import.meta.env.VITE_AI_BASE_URL || "http://localhost:8000",
});

// Backend uploads (images) are served from the API host without the /api suffix
export const UPLOADS_BASE_URL = (
  import.meta.env.VITE_API_BASE_URL || "http://localhost:5000/api"
).replace(/\/api\/?$/, "");

// Old dev-machine LAN IPs that may still be stored in image URLs from previous
// backend hosts. On localhost these are unreachable and time out, so rewrite
// them to the current API host.
const LEGACY_LAN_HOST_REGEX = /^https?:\/\/192\.168\.\d{1,3}\.\d{1,3}:5000/i;

export function resolveImageUrl(url) {
  if (!url) return "";
  if (LEGACY_LAN_HOST_REGEX.test(url)) {
    return url.replace(LEGACY_LAN_HOST_REGEX, UPLOADS_BASE_URL);
  }
  if (/^https?:\/\//i.test(url)) return url;
  return `${UPLOADS_BASE_URL}${url.startsWith("/") ? "" : "/"}${url}`;
}
