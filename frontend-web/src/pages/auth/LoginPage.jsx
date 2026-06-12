import { useState } from "react";
import { useNavigate, useLocation, Link } from "react-router-dom";
import { Mail, Lock, LogIn } from "lucide-react";
import AuthLayout, { FormField, inputClass } from "../../components/common/AuthLayout";
import Button from "../../components/common/Button";
import { useAuth } from "../../context/AuthContext";
import { useToast } from "../../context/ToastContext";

export default function LoginPage() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const { login } = useAuth();
  const toast = useToast();
  const navigate = useNavigate();
  const location = useLocation();

  const handleSubmit = async (e) => {
    e.preventDefault();
    setSubmitting(true);
    try {
      const data = await login(email, password);
      toast.success("Welcome back!");
      if (data?.role === "seller") {
        navigate("/store-owner", { replace: true });
        return;
      } else if (data?.role === "admin") {
        navigate("/admin", { replace: true });
        return;
      }
      const redirectTo = location.state?.from?.pathname || "/";
      navigate(redirectTo, { replace: true });
    } catch (err) {
      toast.error(err.response?.data?.message || "Login failed. Please check your details.");
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <AuthLayout
      title="Welcome back"
      subtitle="Log in to continue your skincare journey"
      footer={
        <>
          Don&apos;t have an account?{" "}
          <Link to="/register" className="text-wine font-semibold hover:underline">
            Sign up
          </Link>
        </>
      }
    >
      <form onSubmit={handleSubmit}>
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
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className={`${inputClass} pl-9`}
              placeholder="••••••••"
            />
          </div>
        </FormField>
        <Button type="submit" className="w-full mt-2" disabled={submitting}>
          <LogIn size={16} /> {submitting ? "Logging in..." : "Log in"}
        </Button>
      </form>
    </AuthLayout>
  );
}
