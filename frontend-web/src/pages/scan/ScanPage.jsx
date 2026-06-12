import { useEffect, useRef, useState } from "react";
import { useNavigate } from "react-router-dom";
import {
  UploadCloud,
  Image as ImageIcon,
  Loader2,
  AlertTriangle,
  Sparkles,
  X,
} from "lucide-react";
import Card from "../../components/common/Card";
import Button from "../../components/common/Button";
import { CameraOnMobileNotice, AppDownloadBanner, AppDownloadMessages } from "../../components/common/AppDownloadCTA";
import { useAuth } from "../../context/AuthContext";
import { useToast } from "../../context/ToastContext";
import { scanService } from "../../services/scanService";
import { routineService } from "../../services/routineService";

const STAGE_LABELS = {
  checking: "Checking your photo...",
  claiming: "Reserving your daily AI scan...",
  analyzing: "Analyzing your skin...",
  saving: "Saving your results...",
};

function mapRoutineSteps(steps = [], concernTarget = "") {
  return steps.map((s) => ({
    stepName: s.name,
    why: s.why || "",
    productCategory: s.category || "",
    keyIngredient: s.ingredient || "",
    searchTags: [],
    concernTarget,
    frequency: "daily",
    notes: "",
    reminderTime: "",
  }));
}

export default function ScanPage() {
  const { user } = useAuth();
  const toast = useToast();
  const navigate = useNavigate();
  const fileInputRef = useRef(null);

  const [quotaLoading, setQuotaLoading] = useState(true);
  const [allowed, setAllowed] = useState(true);
  const [limitMessage, setLimitMessage] = useState("");
  const [file, setFile] = useState(null);
  const [previewUrl, setPreviewUrl] = useState(null);
  const [stage, setStage] = useState("idle");
  const [error, setError] = useState("");
  const [dragActive, setDragActive] = useState(false);

  useEffect(() => {
    let mounted = true;
    scanService
      .getWebQuota(user.userId)
      .then((data) => mounted && setAllowed(!!data.allowed))
      .catch(() => mounted && setAllowed(true))
      .finally(() => mounted && setQuotaLoading(false));
    return () => {
      mounted = false;
      if (previewUrl) URL.revokeObjectURL(previewUrl);
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [user.userId]);

  const pickFile = (selected) => {
    if (!selected || !selected.type?.startsWith("image/")) {
      toast.error("Please choose an image file.");
      return;
    }
    setError("");
    setFile(selected);
    setPreviewUrl((prev) => {
      if (prev) URL.revokeObjectURL(prev);
      return URL.createObjectURL(selected);
    });
  };

  const handleDrop = (e) => {
    e.preventDefault();
    setDragActive(false);
    pickFile(e.dataTransfer.files?.[0]);
  };

  const reset = () => {
    setFile(null);
    setPreviewUrl((prev) => {
      if (prev) URL.revokeObjectURL(prev);
      return null;
    });
    setError("");
    if (fileInputRef.current) fileInputRef.current.value = "";
  };

  const handleAnalyze = async () => {
    if (!file) return;
    setError("");
    try {
      setStage("checking");
      const check = await scanService.checkImage(file);
      if (!check.isValid) {
        setError(check.message || "This photo doesn't look quite right. Please try another.");
        setStage("idle");
        return;
      }

      setStage("claiming");
      try {
        await scanService.claimWebQuota(user.userId);
      } catch (err) {
        const message =
          err.response?.data?.message ||
          "You have used your free AI scan for today on web. Download the mobile app for full AI access and camera scanning.";
        setLimitMessage(message);
        setAllowed(false);
        setStage("idle");
        return;
      }

      setStage("analyzing");
      const analysis = await scanService.analyzeSkin(file);

      setStage("saving");
      const detectedConcerns = (analysis.metrics || []).map((m) => m.name);
      const morning = mapRoutineSteps(analysis.morningRoutine, analysis.mainConcern);
      const evening = mapRoutineSteps(analysis.nightRoutine, analysis.mainConcern);

      await Promise.allSettled([
        scanService.saveScan({
          userId: user.userId,
          file,
          detectedConcerns,
          morningRoutine: analysis.morningRoutine,
          eveningRoutine: analysis.nightRoutine,
          overallStatus: analysis.mainConcern,
          skinScore: analysis.skinScore,
        }),
        routineService.saveAiRoutine({
          userId: user.userId,
          detectedConcerns,
          morning,
          evening,
        }),
      ]);

      navigate("/scan/results", { state: { analysis, imagePreview: previewUrl } });
    } catch {
      toast.error("Something went wrong analyzing your photo. Please try again.");
      setStage("idle");
    }
  };

  const busy = stage !== "idle";

  return (
    <div className="max-w-3xl mx-auto flex flex-col gap-6 animate-fade-slide-in">
      <div>
        <h1 className="font-display text-3xl sm:text-4xl font-bold text-ink mb-2">AI Skin Scan</h1>
        <p className="text-subtext">
          Upload a clear, well-lit photo of your face and let our AI detect skin concerns and
          build you a personalized routine.
        </p>
      </div>

      <CameraOnMobileNotice />

      {quotaLoading ? (
        <Card className="p-8 flex items-center justify-center">
          <Loader2 className="animate-spin text-wine" size={28} />
        </Card>
      ) : !allowed ? (
        <div className="flex flex-col gap-4">
          <Card className="p-6 sm:p-8 flex flex-col items-center text-center gap-3">
            <div className="h-14 w-14 rounded-full bg-soft-pink text-wine flex items-center justify-center">
              <Sparkles size={26} />
            </div>
            <h2 className="font-display text-xl font-bold text-ink">
              You've used today's free AI scan
            </h2>
            <p className="text-subtext text-sm max-w-md">
              {limitMessage ||
                "You have used your free AI scan for today on web. Download the mobile app for full AI access and camera scanning."}
            </p>
          </Card>
          <AppDownloadBanner message={AppDownloadMessages.ai} />
        </div>
      ) : (
        <Card className="p-6 sm:p-8 flex flex-col gap-5">
          <div
            onDragOver={(e) => {
              e.preventDefault();
              setDragActive(true);
            }}
            onDragLeave={() => setDragActive(false)}
            onDrop={handleDrop}
            className={`relative rounded-2xl border-2 border-dashed transition-all duration-200 flex flex-col items-center justify-center text-center p-8 sm:p-12 cursor-pointer
              ${dragActive ? "border-wine bg-soft-pink scale-[1.01]" : "border-divider bg-cream/60 hover:border-dusty-rose"}`}
            onClick={() => !previewUrl && fileInputRef.current?.click()}
          >
            <input
              ref={fileInputRef}
              type="file"
              accept="image/*"
              className="hidden"
              onChange={(e) => pickFile(e.target.files?.[0])}
            />
            {previewUrl ? (
              <div className="relative">
                <img
                  src={previewUrl}
                  alt="Selected preview"
                  className="max-h-72 rounded-xl object-contain shadow-md"
                />
                {!busy && (
                  <button
                    type="button"
                    onClick={(e) => {
                      e.stopPropagation();
                      reset();
                    }}
                    aria-label="Remove image"
                    className="absolute -top-2 -right-2 h-8 w-8 rounded-full bg-white shadow-md text-wine flex items-center justify-center hover:scale-110 transition-transform"
                  >
                    <X size={16} />
                  </button>
                )}
              </div>
            ) : (
              <>
                <div className="h-16 w-16 rounded-full bg-soft-pink text-wine flex items-center justify-center mb-4">
                  <UploadCloud size={28} />
                </div>
                <p className="font-semibold text-ink mb-1">Drag & drop your photo here</p>
                <p className="text-sm text-subtext mb-4">or click to browse — JPG, PNG up to ~10MB</p>
                <Button type="button" variant="secondary" size="sm">
                  <ImageIcon size={15} /> Choose photo
                </Button>
              </>
            )}
          </div>

          {error && (
            <div className="flex items-start gap-2 rounded-2xl border border-danger/20 bg-danger/5 px-4 py-3 text-sm text-danger">
              <AlertTriangle size={16} className="shrink-0 mt-0.5" />
              <span>{error}</span>
            </div>
          )}

          <Button onClick={handleAnalyze} disabled={!file || busy} size="lg" className="self-stretch sm:self-start">
            {busy ? (
              <>
                <Loader2 size={18} className="animate-spin" /> {STAGE_LABELS[stage]}
              </>
            ) : (
              <>
                <Sparkles size={18} /> Analyze my skin
              </>
            )}
          </Button>
        </Card>
      )}
    </div>
  );
}
