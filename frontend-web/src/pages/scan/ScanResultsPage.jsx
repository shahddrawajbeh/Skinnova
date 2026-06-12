import { useEffect } from "react";
import { useLocation, useNavigate } from "react-router-dom";
import { Sun, Moon, ArrowRight, TrendingUp, Sparkles } from "lucide-react";
import Card from "../../components/common/Card";
import Button from "../../components/common/Button";
import SectionHeader from "../../components/common/SectionHeader";
import CircularScore from "../../components/scan/CircularScore";
import { AppDownloadBanner, AppDownloadMessages } from "../../components/common/AppDownloadCTA";

const STATUS_STYLES = {
  Good: { bar: "bg-success", text: "text-success", bg: "bg-success/10" },
  Medium: { bar: "bg-gold", text: "text-gold", bg: "bg-gold/10" },
  Moderate: { bar: "bg-gold", text: "text-gold", bg: "bg-gold/10" },
  "Needs care": { bar: "bg-danger", text: "text-danger", bg: "bg-danger/10" },
};

function statusStyle(status) {
  return STATUS_STYLES[status] || STATUS_STYLES.Medium;
}

function RoutineList({ icon: Icon, title, steps }) {
  return (
    <Card className="p-5 sm:p-6 flex flex-col gap-3">
      <div className="flex items-center gap-2">
        <div className="h-9 w-9 rounded-xl bg-soft-pink text-wine flex items-center justify-center">
          <Icon size={18} />
        </div>
        <h3 className="font-display text-lg font-bold text-ink">{title}</h3>
      </div>
      <ol className="flex flex-col gap-2.5">
        {(steps || []).map((step, i) => (
          <li key={i} className="flex gap-3 text-sm">
            <span className="shrink-0 h-6 w-6 rounded-full bg-wine text-white text-xs font-bold flex items-center justify-center">
              {step.step ?? i + 1}
            </span>
            <div>
              <p className="font-semibold text-ink">{step.name}</p>
              {step.why && <p className="text-subtext text-xs mt-0.5">{step.why}</p>}
            </div>
          </li>
        ))}
        {(!steps || steps.length === 0) && (
          <li className="text-sm text-subtext">No steps generated.</li>
        )}
      </ol>
    </Card>
  );
}

export default function ScanResultsPage() {
  const location = useLocation();
  const navigate = useNavigate();
  const analysis = location.state?.analysis;
  const imagePreview = location.state?.imagePreview;

  useEffect(() => {
    if (!analysis) {
      navigate("/scan", { replace: true });
    }
  }, [analysis, navigate]);

  if (!analysis) return null;

  const metrics = analysis.metrics || [];

  return (
    <div className="max-w-4xl mx-auto flex flex-col gap-10 animate-fade-slide-in">
      <section className="gradient-banner rounded-3xl p-6 sm:p-10 text-white flex flex-col sm:flex-row items-center gap-8">
        {imagePreview && (
          <img
            src={imagePreview}
            alt="Your scan"
            className="h-28 w-28 sm:h-36 sm:w-36 rounded-2xl object-cover border-4 border-white/30 shadow-lg shrink-0"
          />
        )}
        <div className="flex-1 text-center sm:text-left">
          <span className="inline-flex items-center gap-2 rounded-full bg-white/15 px-3 py-1 text-xs font-semibold uppercase tracking-wide mb-3">
            <Sparkles size={13} /> Scan complete
          </span>
          <h1 className="font-display text-2xl sm:text-3xl font-bold mb-2">
            Main concern: {analysis.mainConcern || "—"}
          </h1>
          <p className="text-white/85 text-sm max-w-md">
            Here's what we found, plus a personalized routine to help your skin improve over the
            next {analysis.improvementTime || "few months"}.
          </p>
        </div>
        <div className="flex gap-6 bg-white/10 rounded-2xl p-4">
          <CircularScore score={analysis.skinScore} label="Skin score" color="#fff" />
          <CircularScore score={analysis.potentialScore} label="Potential" color="var(--color-gold)" />
        </div>
      </section>

      <section>
        <SectionHeader title="Detected concerns" subtitle="Severity breakdown from your scan" />
        <div className="grid sm:grid-cols-2 gap-4">
          {metrics.map((m, i) => {
            const style = statusStyle(m.status);
            return (
              <Card key={i} className="p-4 flex flex-col gap-2 animate-pop-in" style={{ animationDelay: `${i * 60}ms` }}>
                <div className="flex items-center justify-between">
                  <p className="font-semibold text-ink">{m.name}</p>
                  <span className={`text-xs font-semibold px-2.5 py-1 rounded-full ${style.bg} ${style.text}`}>
                    {m.status}
                  </span>
                </div>
                <div className="h-2 rounded-full bg-divider overflow-hidden">
                  <div
                    className={`h-full rounded-full ${style.bar} transition-all duration-700`}
                    style={{ width: `${Math.min(100, m.score)}%` }}
                  />
                </div>
              </Card>
            );
          })}
        </div>
      </section>

      <section>
        <SectionHeader title="Your personalized routine" subtitle="Generated from this scan" />
        <div className="grid sm:grid-cols-2 gap-4">
          <RoutineList icon={Sun} title="Morning" steps={analysis.morningRoutine} />
          <RoutineList icon={Moon} title="Evening" steps={analysis.nightRoutine} />
        </div>
        <div className="flex justify-center mt-6">
          <Button to="/routine" size="lg">
            <TrendingUp size={18} /> View My Routine <ArrowRight size={16} />
          </Button>
        </div>
      </section>

      <section>
        <AppDownloadBanner message={AppDownloadMessages.ai} />
      </section>
    </div>
  );
}
