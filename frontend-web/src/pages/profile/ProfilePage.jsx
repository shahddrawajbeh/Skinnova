import { useEffect, useRef, useState } from "react";
import { useNavigate } from "react-router-dom";
import {
  Loader2,
  User,
  Camera,
  Pencil,
  Save,
  X,
  Lock,
  LogOut,
  Users,
  UserCheck,
  ScanFace,
  Trash2,
  Sparkles,
} from "lucide-react";
import Card from "../../components/common/Card";
import Button from "../../components/common/Button";
import EmptyState from "../../components/common/EmptyState";
import { AppDownloadInline } from "../../components/common/AppDownloadCTA";
import { resolveImageUrl } from "../../services/api";
import { useAuth } from "../../context/AuthContext";
import { useToast } from "../../context/ToastContext";
import { authService } from "../../services/authService";
import { scanService } from "../../services/scanService";
import { timeAgo } from "../../utils/format";

const ONBOARDING_FIELDS = [
  { key: "gender", label: "Gender" },
  { key: "ageRange", label: "Age range" },
  { key: "skinType", label: "Skin type" },
  { key: "skinSensitivity", label: "Sensitivity" },
  { key: "skinPhototype", label: "Phototype" },
  { key: "skincareExperience", label: "Experience" },
];

export default function ProfilePage() {
  const { user, profile, setProfile, logout } = useAuth();
  const toast = useToast();
  const navigate = useNavigate();
  const fileRef = useRef(null);

  const [editing, setEditing] = useState(false);
  const [saving, setSaving] = useState(false);
  const [uploading, setUploading] = useState(false);
  const [form, setForm] = useState({ fullName: "", email: "", bio: "", city: "" });

  const [showPasswordForm, setShowPasswordForm] = useState(false);
  const [passwordForm, setPasswordForm] = useState({ currentPassword: "", newPassword: "", confirmPassword: "" });
  const [changingPassword, setChangingPassword] = useState(false);

  const [scans, setScans] = useState([]);
  const [loadingScans, setLoadingScans] = useState(true);
  const [deletingId, setDeletingId] = useState(null);

  useEffect(() => {
    if (profile) {
      setForm({
        fullName: profile.fullName || "",
        email: profile.email || "",
        bio: profile.bio || "",
        city: profile.city || "",
      });
    }
  }, [profile]);

  useEffect(() => {
    let mounted = true;
    scanService
      .getHistory(user.userId)
      .then((data) => mounted && setScans(Array.isArray(data) ? data : []))
      .catch(() => mounted && setScans([]))
      .finally(() => mounted && setLoadingScans(false));
    return () => {
      mounted = false;
    };
  }, [user.userId]);

  const handleAvatarChange = async (e) => {
    const file = e.target.files?.[0];
    if (!file) return;
    setUploading(true);
    try {
      const data = await authService.uploadProfileImage(user.userId, file);
      setProfile((prev) => ({ ...prev, profileImage: data.profileImage }));
      toast.success("Profile photo updated!");
    } catch (err) {
      toast.error(err.response?.data?.message || "Couldn't upload your photo.");
    } finally {
      setUploading(false);
      if (fileRef.current) fileRef.current.value = "";
    }
  };

  const handleSaveProfile = async (e) => {
    e.preventDefault();
    setSaving(true);
    try {
      const data = await authService.updateProfile(user.userId, {
        fullName: form.fullName.trim(),
        email: form.email.trim(),
        bio: form.bio.trim(),
        city: form.city.trim(),
      });
      setProfile(data.user);
      setEditing(false);
      toast.success("Profile updated!");
    } catch (err) {
      toast.error(err.response?.data?.message || "Couldn't update your profile.");
    } finally {
      setSaving(false);
    }
  };

  const handleChangePassword = async (e) => {
    e.preventDefault();
    if (passwordForm.newPassword.length < 6) {
      toast.error("New password must be at least 6 characters.");
      return;
    }
    if (passwordForm.newPassword !== passwordForm.confirmPassword) {
      toast.error("New passwords don't match.");
      return;
    }
    setChangingPassword(true);
    try {
      await authService.changePassword(user.userId, passwordForm.currentPassword, passwordForm.newPassword);
      toast.success("Password changed successfully!");
      setPasswordForm({ currentPassword: "", newPassword: "", confirmPassword: "" });
      setShowPasswordForm(false);
    } catch (err) {
      toast.error(err.response?.data?.message || "Couldn't change your password.");
    } finally {
      setChangingPassword(false);
    }
  };

  const handleDeleteScan = async (scanId) => {
    setDeletingId(scanId);
    try {
      await scanService.deleteScan(scanId);
      setScans((prev) => prev.filter((s) => s._id !== scanId));
      toast.success("Scan removed from your history.");
    } catch {
      toast.error("Couldn't delete this scan.");
    } finally {
      setDeletingId(null);
    }
  };

  const handleLogout = () => {
    logout();
    navigate("/");
  };

  if (!profile) {
    return (
      <div className="flex items-center justify-center py-24">
        <Loader2 className="animate-spin text-wine" size={32} />
      </div>
    );
  }

  const onboarding = profile.onboarding || {};

  return (
    <div className="max-w-3xl mx-auto flex flex-col gap-8 animate-fade-slide-in">
      <Card className="p-6 sm:p-8 flex flex-col sm:flex-row sm:items-center gap-6">
        <div className="relative shrink-0 mx-auto sm:mx-0">
          <div className="h-24 w-24 rounded-full bg-soft-pink overflow-hidden flex items-center justify-center">
            {profile.profileImage ? (
              <img src={resolveImageUrl(profile.profileImage)} alt="" className="h-full w-full object-cover" />
            ) : (
              <User size={36} className="text-wine" />
            )}
          </div>
          <label className="absolute bottom-0 right-0 h-8 w-8 rounded-full bg-wine text-white flex items-center justify-center cursor-pointer hover:bg-wine-dark transition-all hover:scale-110 shadow-md">
            {uploading ? <Loader2 size={14} className="animate-spin" /> : <Camera size={14} />}
            <input ref={fileRef} type="file" accept="image/*" onChange={handleAvatarChange} className="hidden" />
          </label>
        </div>

        <div className="flex-1 min-w-0 text-center sm:text-left">
          <h1 className="font-display text-2xl sm:text-3xl font-bold text-ink truncate">{profile.fullName}</h1>
          <p className="text-sm text-subtext truncate">{profile.email}</p>
          {profile.bio && <p className="text-sm text-ink mt-2">{profile.bio}</p>}
          <div className="flex items-center justify-center sm:justify-start gap-4 mt-3 text-sm text-subtext">
            <span className="flex items-center gap-1.5">
              <Users size={14} /> {profile.followers?.length || 0} followers
            </span>
            <span className="flex items-center gap-1.5">
              <UserCheck size={14} /> {profile.following?.length || 0} following
            </span>
          </div>
        </div>

        <Button variant="secondary" onClick={() => setEditing((e) => !e)} className="sm:self-start shrink-0">
          {editing ? <X size={15} /> : <Pencil size={15} />}
          {editing ? "Cancel" : "Edit profile"}
        </Button>
      </Card>

      {editing && (
        <Card className="p-6 flex flex-col gap-4 animate-fade-slide-in">
          <h2 className="font-display text-lg font-bold text-ink">Edit profile</h2>
          <form onSubmit={handleSaveProfile} className="flex flex-col gap-4">
            <div className="grid sm:grid-cols-2 gap-4">
              <input
                value={form.fullName}
                onChange={(e) => setForm((f) => ({ ...f, fullName: e.target.value }))}
                placeholder="Full name"
                required
                className="w-full rounded-xl border border-divider bg-cream/50 px-4 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-wine/40 focus:border-wine transition-all"
              />
              <input
                value={form.email}
                onChange={(e) => setForm((f) => ({ ...f, email: e.target.value }))}
                placeholder="Email"
                type="email"
                required
                className="w-full rounded-xl border border-divider bg-cream/50 px-4 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-wine/40 focus:border-wine transition-all"
              />
              <input
                value={form.city}
                onChange={(e) => setForm((f) => ({ ...f, city: e.target.value }))}
                placeholder="City"
                className="w-full rounded-xl border border-divider bg-cream/50 px-4 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-wine/40 focus:border-wine transition-all"
              />
            </div>
            <textarea
              value={form.bio}
              onChange={(e) => setForm((f) => ({ ...f, bio: e.target.value }))}
              placeholder="A short bio about your skincare journey..."
              rows={2}
              className="w-full rounded-xl border border-divider bg-cream/50 px-4 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-wine/40 focus:border-wine transition-all resize-none"
            />
            <Button type="submit" disabled={saving} className="self-start">
              {saving ? <Loader2 size={15} className="animate-spin" /> : <Save size={15} />}
              Save changes
            </Button>
          </form>
        </Card>
      )}

      {(ONBOARDING_FIELDS.some((f) => onboarding[f.key]) ||
        onboarding.skinConcerns?.length > 0 ||
        onboarding.goals?.length > 0) && (
        <Card className="p-6 flex flex-col gap-3">
          <h2 className="font-display text-lg font-bold text-ink">Skin Profile</h2>
          <div className="flex flex-wrap gap-2">
            {ONBOARDING_FIELDS.map(
              (f) =>
                onboarding[f.key] && (
                  <span key={f.key} className="px-3 py-1.5 rounded-full bg-soft-pink text-wine text-xs font-semibold">
                    {f.label}: {onboarding[f.key]}
                  </span>
                )
            )}
            {(onboarding.skinConcerns || []).map((c) => (
              <span key={c} className="px-3 py-1.5 rounded-full bg-cream border border-divider text-ink text-xs font-medium">
                {c}
              </span>
            ))}
            {(onboarding.goals || []).map((g) => (
              <span key={g} className="px-3 py-1.5 rounded-full bg-cream border border-divider text-ink text-xs font-medium">
                {g}
              </span>
            ))}
          </div>
        </Card>
      )}

      <Card className="p-6 flex flex-col gap-4">
        <div className="flex items-center justify-between">
          <h2 className="font-display text-lg font-bold text-ink">Security</h2>
          <button
            type="button"
            onClick={() => setShowPasswordForm((s) => !s)}
            className="flex items-center gap-1.5 text-sm font-semibold text-wine hover:underline"
          >
            <Lock size={14} /> {showPasswordForm ? "Cancel" : "Change password"}
          </button>
        </div>
        {showPasswordForm && (
          <form onSubmit={handleChangePassword} className="flex flex-col gap-3 animate-fade-slide-in">
            <input
              type="password"
              value={passwordForm.currentPassword}
              onChange={(e) => setPasswordForm((f) => ({ ...f, currentPassword: e.target.value }))}
              placeholder="Current password"
              required
              className="w-full rounded-xl border border-divider bg-cream/50 px-4 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-wine/40 focus:border-wine transition-all"
            />
            <div className="grid sm:grid-cols-2 gap-3">
              <input
                type="password"
                value={passwordForm.newPassword}
                onChange={(e) => setPasswordForm((f) => ({ ...f, newPassword: e.target.value }))}
                placeholder="New password"
                required
                className="w-full rounded-xl border border-divider bg-cream/50 px-4 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-wine/40 focus:border-wine transition-all"
              />
              <input
                type="password"
                value={passwordForm.confirmPassword}
                onChange={(e) => setPasswordForm((f) => ({ ...f, confirmPassword: e.target.value }))}
                placeholder="Confirm new password"
                required
                className="w-full rounded-xl border border-divider bg-cream/50 px-4 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-wine/40 focus:border-wine transition-all"
              />
            </div>
            <Button type="submit" disabled={changingPassword} className="self-start">
              {changingPassword ? <Loader2 size={15} className="animate-spin" /> : <Lock size={15} />}
              Update password
            </Button>
          </form>
        )}
      </Card>

      <section className="flex flex-col gap-4">
        <h2 className="font-display text-lg font-bold text-ink">Scan History</h2>
        {loadingScans ? (
          <div className="flex items-center justify-center py-8">
            <Loader2 className="animate-spin text-wine" size={24} />
          </div>
        ) : scans.length > 0 ? (
          <div className="flex flex-col gap-3">
            {scans.map((scan) => (
              <Card key={scan._id} className="p-4 flex items-center gap-4">
                <div className="h-14 w-14 rounded-xl overflow-hidden bg-soft-pink shrink-0">
                  {scan.imageUrl ? (
                    <img src={resolveImageUrl(scan.imageUrl)} alt="" className="h-full w-full object-cover" />
                  ) : (
                    <div className="h-full w-full flex items-center justify-center text-wine/30">
                      <ScanFace size={20} />
                    </div>
                  )}
                </div>
                <div className="flex-1 min-w-0">
                  <p className="font-semibold text-ink text-sm">
                    {scan.overallStatus || "Skin scan"} {scan.skinScore != null && `· Score ${scan.skinScore}`}
                  </p>
                  <p className="text-xs text-subtext mt-0.5">
                    {(scan.detectedConcerns || []).length} concern{(scan.detectedConcerns || []).length === 1 ? "" : "s"} ·{" "}
                    {timeAgo(scan.createdAt)}
                  </p>
                </div>
                <button
                  onClick={() => handleDeleteScan(scan._id)}
                  disabled={deletingId === scan._id}
                  className="p-2 rounded-full text-subtext hover:text-danger hover:bg-soft-pink transition-all hover:scale-110"
                  aria-label="Delete scan"
                >
                  {deletingId === scan._id ? <Loader2 size={16} className="animate-spin" /> : <Trash2 size={16} />}
                </button>
              </Card>
            ))}
          </div>
        ) : (
          <EmptyState
            icon={ScanFace}
            title="No scans yet"
            message="Your AI skin scan history will appear here."
            action={
              <Button to="/scan" size="md">
                Try AI Skin Scan
              </Button>
            }
          />
        )}
      </section>

      <AppDownloadInline message="Download the app for your full skincare journey" icon={Sparkles} />

      <Button variant="ghost" onClick={handleLogout} className="self-center text-danger hover:bg-red-50">
        <LogOut size={15} /> Log out
      </Button>
    </div>
  );
}
