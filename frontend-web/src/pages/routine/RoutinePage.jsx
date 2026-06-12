import { useEffect, useState } from "react";
import {
  Sun,
  Moon,
  CheckCircle2,
  Circle,
  Plus,
  Pencil,
  Trash2,
  Flame,
  Award,
  Loader2,
  Sparkles,
  X,
} from "lucide-react";
import Card from "../../components/common/Card";
import Button from "../../components/common/Button";
import EmptyState from "../../components/common/EmptyState";
import { useAuth } from "../../context/AuthContext";
import { useToast } from "../../context/ToastContext";
import { routineService } from "../../services/routineService";

const TABS = [
  { key: "morning", label: "Morning", icon: Sun, timeOfDay: "morning" },
  { key: "evening", label: "Evening", icon: Moon, timeOfDay: "evening" },
];

function StepCard({ step, done, onToggle, onEdit, onDelete, busy }) {
  return (
    <Card className="p-4 flex items-start gap-3 animate-pop-in">
      <button
        type="button"
        onClick={() => onToggle(step)}
        disabled={busy}
        aria-label={done ? "Mark as not done" : "Mark as done"}
        className="shrink-0 mt-0.5 text-wine hover:scale-110 transition-transform disabled:opacity-50"
      >
        {done ? <CheckCircle2 size={24} className="fill-wine/10" /> : <Circle size={24} />}
      </button>
      <div className="flex-1 min-w-0">
        <p className={`font-semibold text-ink ${done ? "line-through text-subtext" : ""}`}>
          {step.stepName}
        </p>
        {step.why && <p className="text-xs text-subtext mt-0.5">{step.why}</p>}
        <div className="flex flex-wrap gap-1.5 mt-2">
          {step.productCategory && (
            <span className="text-[11px] font-medium px-2 py-0.5 rounded-full bg-soft-pink text-wine">
              {step.productCategory}
            </span>
          )}
          {step.keyIngredient && (
            <span className="text-[11px] font-medium px-2 py-0.5 rounded-full bg-cream border border-divider text-subtext">
              {step.keyIngredient}
            </span>
          )}
          {step.frequency && step.frequency !== "daily" && (
            <span className="text-[11px] font-medium px-2 py-0.5 rounded-full bg-gold/15 text-wine-dark">
              {step.frequency}
            </span>
          )}
          {step.reminderTime && (
            <span className="text-[11px] font-medium px-2 py-0.5 rounded-full bg-cream border border-divider text-subtext">
              ⏰ {step.reminderTime}
            </span>
          )}
        </div>
      </div>
      {step.source === "custom" && (
        <div className="flex flex-col gap-1.5 shrink-0">
          <button
            type="button"
            onClick={() => onEdit(step)}
            aria-label="Edit step"
            className="p-1.5 rounded-full text-subtext hover:text-wine hover:bg-soft-pink transition-all"
          >
            <Pencil size={14} />
          </button>
          <button
            type="button"
            onClick={() => onDelete(step)}
            aria-label="Delete step"
            className="p-1.5 rounded-full text-subtext hover:text-danger hover:bg-soft-pink transition-all"
          >
            <Trash2 size={14} />
          </button>
        </div>
      )}
    </Card>
  );
}

function CustomStepForm({ timeOfDay, initial, onCancel, onSubmit, submitting }) {
  const [stepName, setStepName] = useState(initial?.stepName || "");
  const [notes, setNotes] = useState(initial?.notes || "");
  const [reminderTime, setReminderTime] = useState(initial?.reminderTime || "");
  const [frequency, setFrequency] = useState(initial?.frequency || "daily");

  const handleSubmit = (e) => {
    e.preventDefault();
    if (!stepName.trim()) return;
    onSubmit({ stepName: stepName.trim(), notes, reminderTime, frequency, timeOfDay });
  };

  return (
    <Card className="p-4 animate-fade-slide-in">
      <form onSubmit={handleSubmit} className="flex flex-col gap-3">
        <div className="flex items-center justify-between">
          <p className="font-semibold text-ink text-sm">
            {initial ? "Edit step" : `Add a custom ${timeOfDay} step`}
          </p>
          <button type="button" onClick={onCancel} aria-label="Cancel" className="text-subtext hover:text-danger">
            <X size={16} />
          </button>
        </div>
        <input
          type="text"
          required
          value={stepName}
          onChange={(e) => setStepName(e.target.value)}
          placeholder="Step name (e.g. Apply sunscreen)"
          className="w-full rounded-xl border border-divider bg-cream/50 px-4 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-wine/40 focus:border-wine transition-all"
        />
        <textarea
          value={notes}
          onChange={(e) => setNotes(e.target.value)}
          placeholder="Notes (optional)"
          rows={2}
          className="w-full rounded-xl border border-divider bg-cream/50 px-4 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-wine/40 focus:border-wine transition-all resize-none"
        />
        <div className="flex flex-col sm:flex-row gap-3">
          <select
            value={frequency}
            onChange={(e) => setFrequency(e.target.value)}
            className="flex-1 rounded-xl border border-divider bg-cream/50 px-4 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-wine/40 focus:border-wine transition-all"
          >
            <option value="daily">Daily</option>
            <option value="weekly">Weekly</option>
            <option value="2-3 times a week">2-3 times a week</option>
          </select>
          <input
            type="time"
            value={reminderTime}
            onChange={(e) => setReminderTime(e.target.value)}
            className="flex-1 rounded-xl border border-divider bg-cream/50 px-4 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-wine/40 focus:border-wine transition-all"
          />
        </div>
        <Button type="submit" disabled={submitting} size="sm" className="self-start">
          {submitting ? <Loader2 size={15} className="animate-spin" /> : <Plus size={15} />}
          {initial ? "Save changes" : "Add step"}
        </Button>
      </form>
    </Card>
  );
}

export default function RoutinePage() {
  const { user } = useAuth();
  const toast = useToast();

  const [loading, setLoading] = useState(true);
  const [routine, setRoutine] = useState(null);
  const [progress, setProgress] = useState({ completedStepIds: [], totalPoints: 0, streak: 0 });
  const [activeTab, setActiveTab] = useState("morning");
  const [togglingId, setTogglingId] = useState(null);
  const [showAddForm, setShowAddForm] = useState(false);
  const [editingStep, setEditingStep] = useState(null);
  const [submitting, setSubmitting] = useState(false);

  const load = async () => {
    setLoading(true);
    try {
      const r = await routineService.getActiveRoutine(user.userId);
      setRoutine(r);
      if (r?._id) {
        const p = await routineService.getProgress(user.userId, r._id);
        setProgress(p);
      }
    } catch {
      toast.error("Couldn't load your routine.");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    load();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [user.userId]);

  const handleToggle = async (step) => {
    if (!routine?._id) return;
    setTogglingId(step._id);
    const wasDone = progress.completedStepIds.includes(step._id);
    setProgress((p) => ({
      ...p,
      completedStepIds: wasDone
        ? p.completedStepIds.filter((id) => id !== step._id)
        : [...p.completedStepIds, step._id],
    }));
    try {
      const updated = await routineService.toggleStep({
        userId: user.userId,
        routineId: routine._id,
        stepId: step._id,
      });
      setProgress(updated);
      if (!wasDone) toast.success("Nice! Step marked as done.");
    } catch {
      toast.error("Couldn't update progress.");
      setProgress((p) => ({
        ...p,
        completedStepIds: wasDone
          ? [...p.completedStepIds, step._id]
          : p.completedStepIds.filter((id) => id !== step._id),
      }));
    } finally {
      setTogglingId(null);
    }
  };

  const handleAddOrEdit = async (values) => {
    setSubmitting(true);
    try {
      if (editingStep) {
        const updated = await routineService.updateCustomStep(routine._id, editingStep._id, values);
        setRoutine(updated);
        toast.success("Step updated.");
      } else {
        const updated = await routineService.addCustomStep({ userId: user.userId, step: values });
        setRoutine(updated);
        toast.success("Custom step added.");
      }
      setShowAddForm(false);
      setEditingStep(null);
    } catch {
      toast.error("Couldn't save this step.");
    } finally {
      setSubmitting(false);
    }
  };

  const handleDelete = async (step) => {
    if (!routine?._id) return;
    try {
      await routineService.deleteCustomStep(routine._id, step._id);
      setRoutine((r) => ({
        ...r,
        morning: r.morning.filter((s) => s._id !== step._id),
        evening: r.evening.filter((s) => s._id !== step._id),
      }));
      toast.success("Step removed.");
    } catch {
      toast.error("Couldn't remove this step.");
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center py-24">
        <Loader2 className="animate-spin text-wine" size={32} />
      </div>
    );
  }

  if (!routine) {
    return (
      <EmptyState
        icon={Sparkles}
        title="No routine yet"
        message="Do an AI skin scan to get a personalized morning and evening routine."
        action={
          <Button to="/scan" size="md">
            Start AI Skin Scan
          </Button>
        }
      />
    );
  }

  const activeSteps = (routine[activeTab] || []).slice().sort((a, b) => {
    if (a.source === b.source) return 0;
    return a.source === "custom" ? 1 : -1;
  });

  return (
    <div className="max-w-3xl mx-auto flex flex-col gap-6 animate-fade-slide-in">
      <div className="flex flex-col sm:flex-row sm:items-end sm:justify-between gap-4">
        <div>
          <h1 className="font-display text-3xl sm:text-4xl font-bold text-ink mb-1">
            {routine.routineName || "My Skin Routine"}
          </h1>
          {routine.detectedConcerns?.length > 0 && (
            <p className="text-subtext text-sm">
              Targeting: {routine.detectedConcerns.join(", ")}
            </p>
          )}
        </div>
        <div className="flex gap-3">
          <div className="flex items-center gap-2 rounded-2xl bg-soft-pink px-4 py-2 text-wine">
            <Award size={18} />
            <span className="font-bold">{progress.totalPoints || 0}</span>
            <span className="text-xs">pts</span>
          </div>
          <div className="flex items-center gap-2 rounded-2xl bg-gold/15 px-4 py-2 text-wine-dark">
            <Flame size={18} />
            <span className="font-bold">{progress.streak || 0}</span>
            <span className="text-xs">day streak</span>
          </div>
        </div>
      </div>

      <div className="flex gap-2 bg-soft-pink/60 rounded-full p-1 self-start">
        {TABS.map((tab) => (
          <button
            key={tab.key}
            onClick={() => setActiveTab(tab.key)}
            className={`flex items-center gap-2 px-5 py-2 rounded-full text-sm font-semibold transition-all ${
              activeTab === tab.key ? "bg-wine text-white shadow-md" : "text-wine hover:bg-white/60"
            }`}
          >
            <tab.icon size={15} /> {tab.label}
          </button>
        ))}
      </div>

      <div className="flex flex-col gap-3">
        {activeSteps.length === 0 && !showAddForm && (
          <p className="text-sm text-subtext text-center py-6">No steps in this routine yet.</p>
        )}
        {activeSteps.map((step) =>
          editingStep?._id === step._id ? (
            <CustomStepForm
              key={step._id}
              timeOfDay={activeTab}
              initial={editingStep}
              submitting={submitting}
              onCancel={() => setEditingStep(null)}
              onSubmit={handleAddOrEdit}
            />
          ) : (
            <StepCard
              key={step._id}
              step={step}
              done={progress.completedStepIds.includes(step._id)}
              busy={togglingId === step._id}
              onToggle={handleToggle}
              onEdit={setEditingStep}
              onDelete={handleDelete}
            />
          )
        )}

        {showAddForm ? (
          <CustomStepForm
            timeOfDay={activeTab}
            submitting={submitting}
            onCancel={() => setShowAddForm(false)}
            onSubmit={handleAddOrEdit}
          />
        ) : (
          <Button variant="secondary" onClick={() => setShowAddForm(true)} className="self-start">
            <Plus size={16} /> Add custom step
          </Button>
        )}
      </div>
    </div>
  );
}
