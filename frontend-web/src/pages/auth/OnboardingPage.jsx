import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { Sparkles } from "lucide-react";
import AuthLayout, { FormField } from "../../components/common/AuthLayout";
import Button from "../../components/common/Button";
import { useAuth } from "../../context/AuthContext";
import { useToast } from "../../context/ToastContext";
import { authService } from "../../services/authService";

const GENDERS = ["Female", "Male"];
const AGE_RANGES = ["13–18", "18–24", "25–34", "35–44", "45–54", "55+"];
const SKIN_TYPES = ["Normal Skin", "Combination Skin", "Dry Skin", "Oily Skin", "I don't know"];
const CONCERNS = [
  "Acne & Blemishes",
  "Blackheads",
  "Dark Spots",
  "Dryness",
  "Oiliness",
  "Redness",
  "Dullness",
  "Uneven Texture",
  "Visible Pores",
  "Dark Circles",
  "Puffiness",
  "Fine Lines & Wrinkles",
  "Loss of Firmness",
  "Sensitive Skin",
  "Dehydration",
];

function ChipGroup({ options, value, onChange, multi = false }) {
  const isSelected = (opt) => (multi ? value.includes(opt) : value === opt);
  const toggle = (opt) => {
    if (multi) {
      onChange(value.includes(opt) ? value.filter((v) => v !== opt) : [...value, opt]);
    } else {
      onChange(opt);
    }
  };
  return (
    <div className="flex flex-wrap gap-2">
      {options.map((opt) => (
        <button
          type="button"
          key={opt}
          onClick={() => toggle(opt)}
          className={`px-3.5 py-1.5 rounded-full text-sm font-medium border transition-all duration-200 hover:scale-105 ${
            isSelected(opt)
              ? "bg-wine text-white border-wine shadow-md shadow-wine/20"
              : "bg-white text-ink border-divider hover:border-dusty-rose"
          }`}
        >
          {opt}
        </button>
      ))}
    </div>
  );
}

export default function OnboardingPage() {
  const { user, refreshProfile } = useAuth();
  const toast = useToast();
  const navigate = useNavigate();
  const [gender, setGender] = useState("");
  const [ageRange, setAgeRange] = useState("");
  const [skinType, setSkinType] = useState("");
  const [skinConcerns, setSkinConcerns] = useState([]);
  const [submitting, setSubmitting] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setSubmitting(true);
    try {
      await authService.saveOnboarding(user.userId, { gender, ageRange, skinType, skinConcerns });
      await refreshProfile();
      toast.success("Your skin profile is ready!");
      navigate("/", { replace: true });
    } catch {
      toast.error("Couldn't save your skin profile. You can update it later from your profile.");
      navigate("/", { replace: true });
    } finally {
      setSubmitting(false);
    }
  };

  const skip = () => navigate("/", { replace: true });

  return (
    <AuthLayout
      title="Tell us about your skin"
      subtitle="A few quick questions to personalize your routine and recommendations"
    >
      <form onSubmit={handleSubmit} className="space-y-5">
        <FormField label="Gender">
          <ChipGroup options={GENDERS} value={gender} onChange={setGender} />
        </FormField>
        <FormField label="Age range">
          <ChipGroup options={AGE_RANGES} value={ageRange} onChange={setAgeRange} />
        </FormField>
        <FormField label="Skin type">
          <ChipGroup options={SKIN_TYPES} value={skinType} onChange={setSkinType} />
        </FormField>
        <FormField label="Skin concerns (select all that apply)">
          <ChipGroup options={CONCERNS} value={skinConcerns} onChange={setSkinConcerns} multi />
        </FormField>

        <div className="flex flex-col sm:flex-row gap-3 pt-2">
          <Button type="submit" className="flex-1" disabled={submitting}>
            <Sparkles size={16} /> {submitting ? "Saving..." : "Save & continue"}
          </Button>
          <Button type="button" variant="ghost" onClick={skip}>
            Skip for now
          </Button>
        </div>
      </form>
    </AuthLayout>
  );
}
