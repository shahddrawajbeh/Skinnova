import { useState } from "react";
import { useNavigate, Link } from "react-router-dom";
import { Mail, Lock, User, UserPlus } from "lucide-react";
import AuthLayout, { FormField, inputClass } from "../../components/common/AuthLayout";
import Button from "../../components/common/Button";
import { useAuth } from "../../context/AuthContext";
import { useToast } from "../../context/ToastContext";

export default function RegisterPage() {
  const [fullName, setFullName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const { register } = useAuth();
  const toast = useToast();
  const navigate = useNavigate();

  const handleSubmit = async (e) => {
    e.preventDefault();
    setSubmitting(true);
    try {
      await register(fullName, email, password);
      toast.success("Account created! Let's set up your skin profile.");
      navigate("/onboarding", { replace: true });
    } catch (err) {
      toast.error(err.response?.data?.message || "Registration failed. Please try again.");
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <AuthLayout
      title="Create your account"
      subtitle="Join Skinova and start understanding your skin"
      footer={
        <>
          Already have an account?{" "}
          <Link to="/login" className="text-wine font-semibold hover:underline">
            Log in
          </Link>
        </>
      }
    >
      <form onSubmit={handleSubmit}>
        <FormField label="Full name">
          <div className="relative">
            <User size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-subtext" />
            <input
              type="text"
              required
              value={fullName}
              onChange={(e) => setFullName(e.target.value)}
              className={`${inputClass} pl-9`}
              placeholder="Jane Doe"
            />
          </div>
        </FormField>
        <FormField label="Email">
          <div className="relative">
            <Mail size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-subtext" />
            <input
              type="email"
              required
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className={`${inputClass} pl-9`}
              placeholder="you@example.com"
            />
          </div>
        </FormField>
        <FormField label="Password">
          <div className="relative">
            <Lock size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-subtext" />
            <input
              type="password"
              required
              minLength={6}
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className={`${inputClass} pl-9`}
              placeholder="At least 6 characters"
            />
          </div>
        </FormField>
        <Button type="submit" className="w-full mt-2" disabled={submitting}>
          <UserPlus size={16} /> {submitting ? "Creating account..." : "Sign up"}
        </Button>
      </form>
    </AuthLayout>
  );
}
