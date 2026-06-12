import { useState } from "react";
import { resolveImageUrl } from "../../services/api";

// Drop-in replacement for `{src ? <img src={resolveImageUrl(src)} /> : fallback}`
// that also falls back to `fallback` if the resolved image fails to load.
export default function Avatar({ src, alt = "", className = "", fallback }) {
  const [failed, setFailed] = useState(false);
  const resolved = src ? resolveImageUrl(src) : "";

  if (!resolved || failed) {
    return fallback ?? null;
  }

  return <img src={resolved} alt={alt} className={className} onError={() => setFailed(true)} />;
}
