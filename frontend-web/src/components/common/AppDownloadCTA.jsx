import { Smartphone, Camera, Sparkles, ArrowRight } from "lucide-react";
import Button from "./Button";

const MESSAGES = {
  ai: "Unlock unlimited scans on mobile",
  camera: "Use camera scan on the app",
  general: "Continue your skincare journey on the app",
  full: "Get full AI access on the mobile app",
};

export function AppDownloadBanner({ message = MESSAGES.general, className = "" }) {
  return (
    <div
      className={`gradient-banner rounded-3xl p-6 sm:p-8 text-white flex flex-col sm:flex-row items-center
        justify-between gap-4 shadow-lg shadow-wine/20 ${className}`}
    >
      <div className="flex items-center gap-4">
        <div className="hidden sm:flex h-12 w-12 shrink-0 items-center justify-center rounded-2xl bg-white/15">
          <Smartphone size={24} />
        </div>
        <div>
          <p className="font-display text-lg sm:text-xl font-bold mb-1">{message}</p>
          <p className="text-white/80 text-sm">
            Get camera scanning, unlimited AI scans, and the full Skinova experience.
          </p>
        </div>
      </div>
      <Button variant="gold" className="shrink-0">
        Download App <ArrowRight size={16} />
      </Button>
    </div>
  );
}

export function AppDownloadInline({ message = MESSAGES.full, icon: Icon = Sparkles, className = "" }) {
  return (
    <div
      className={`flex items-center gap-3 rounded-2xl border border-dusty-rose-light bg-soft-pink px-4 py-3
        text-wine text-sm font-medium ${className}`}
    >
      <Icon size={18} className="shrink-0" />
      <span className="flex-1">{message}</span>
    </div>
  );
}

export function CameraOnMobileNotice({ className = "" }) {
  return (
    <div
      className={`flex items-start gap-3 rounded-2xl border border-dusty-rose-light bg-soft-pink px-4 py-3
        text-sm text-wine ${className}`}
    >
      <Camera size={18} className="shrink-0 mt-0.5" />
      <p>
        Camera scanning is available only on the mobile app. On web, you can upload a photo
        instead.
      </p>
    </div>
  );
}

export const AppDownloadMessages = MESSAGES;
