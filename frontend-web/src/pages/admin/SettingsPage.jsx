import { useEffect, useState } from "react";
import { Camera, Loader2, Lock, Save } from "lucide-react";
import Card from "../../components/common/Card";
import Button from "../../components/common/Button";
import Tabs from "../../components/common/Tabs";
import { inputClass, FormField } from "../../components/common/AuthLayout";
import { resolveImageUrl } from "../../services/api";
import { useAuth } from "../../context/AuthContext";
import { useToast } from "../../context/ToastContext";
import { authService } from "../../services/authService";
import { adminService } from "../../services/adminService";

const TABS = [
  { value: "account", label: "Account" },
  { value: "app", label: "App Settings" },
];

function AccountTab() {
  const { user, profile, setProfile, refreshProfile } = useAuth();
  const toast = useToast();
  const [fullName, setFullName] = useState("");
  const [saving, setSaving] = useState(false);
  const [uploadingPhoto, setUploadingPhoto] = useState(false);
  const [passwords, setPasswords] = useState({ current: "", next: "", confirm: "" });
  const [changingPassword, setChangingPassword] = useState(false);

  useEffect(() => {
    setFullName(profile?.fullName || "");
  }, [profile]);

  const handlePhotoChange = async (e) => {
    const file = e.target.files?.[0];
    if (!file) return;
    setUploadingPhoto(true);
    try {
      const data = await authService.uploadProfileImage(user.userId, file);
      setProfile((prev) => ({ ...prev, profileImage: data.profileImage }));
      toast.success("Profile photo updated.");
    } catch {
      toast.error("Couldn't upload photo.");
    } finally {
      setUploadingPhoto(false);
    }
  };

  const handleSaveName = async () => {
    setSaving(true);
    try {
      await authService.updateProfile(user.userId, { fullName });
      await refreshProfile();
      toast.success("Profile updated.");
    } catch (err) {
      toast.error(err.response?.data?.message || "Couldn't update profile.");
    } finally {
      setSaving(false);
    }
  };

  const handleChangePassword = async () => {
    if (!passwords.current || !passwords.next) {
      toast.error("Fill in your current and new password.");
      return;
    }
    if (passwords.next !== passwords.confirm) {
      toast.error("New passwords don't match.");
      return;
    }
    setChangingPassword(true);
    try {
      await authService.changePassword(user.userId, passwords.current, passwords.next);
      toast.success("Password changed.");
      setPasswords({ current: "", next: "", confirm: "" });
    } catch (err) {
      toast.error(err.response?.data?.message || "Couldn't change password.");
    } finally {
      setChangingPassword(false);
    }
  };

  return (
    <div className="flex flex-col gap-5">
      <Card className="p-5 flex flex-col sm:flex-row sm:items-end gap-4" hover={false}>
        <div className="relative h-16 w-16 rounded-full overflow-hidden bg-soft-pink shrink-0 group">
          {profile?.profileImage ? (
            <img src={resolveImageUrl(profile.profileImage)} alt="" className="h-full w-full object-cover" />
          ) : (
            <div className="h-full w-full flex items-center justify-center text-wine font-display text-xl">
              {profile?.fullName?.[0] || "A"}
            </div>
          )}
          <label className="absolute inset-0 flex items-center justify-center bg-black/30 opacity-0 group-hover:opacity-100 transition-opacity cursor-pointer">
            {uploadingPhoto ? <Loader2 size={16} className="animate-spin text-white" /> : <Camera size={16} className="text-white" />}
            <input type="file" accept="image/*" className="hidden" onChange={handlePhotoChange} disabled={uploadingPhoto} />
          </label>
        </div>
        <div className="flex-1 w-full">
          <FormField label="Full Name">
            <input type="text" value={fullName} onChange={(e) => setFullName(e.target.value)} className={inputClass} />
          </FormField>
        </div>
        <Button onClick={handleSaveName} disabled={saving}>
          {saving ? <Loader2 size={15} className="animate-spin" /> : <Save size={15} />}
          Save
        </Button>
      </Card>

      <Card className="p-5 flex flex-col gap-4" hover={false}>
        <h3 className="font-display text-lg font-bold text-ink flex items-center gap-2">
          <Lock size={18} className="text-wine" /> Change Password
        </h3>
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
          <FormField label="Current Password">
            <input
              type="password"
              value={passwords.current}
              onChange={(e) => setPasswords((p) => ({ ...p, current: e.target.value }))}
              className={inputClass}
            />
          </FormField>
          <FormField label="New Password">
            <input
              type="password"
              value={passwords.next}
              onChange={(e) => setPasswords((p) => ({ ...p, next: e.target.value }))}
              className={inputClass}
            />
          </FormField>
          <FormField label="Confirm New Password">
            <input
              type="password"
              value={passwords.confirm}
              onChange={(e) => setPasswords((p) => ({ ...p, confirm: e.target.value }))}
              className={inputClass}
            />
          </FormField>
        </div>
        <div className="flex justify-end">
          <Button onClick={handleChangePassword} disabled={changingPassword} variant="secondary">
            {changingPassword ? <Loader2 size={15} className="animate-spin" /> : "Update password"}
          </Button>
        </div>
      </Card>
    </div>
  );
}

const TOGGLE_ITEMS = [
  { key: "maintenanceMode", label: "Maintenance Mode", desc: "Take the app offline for all non-admin users." },
  { key: "allowNewRegistrations", label: "Allow New Registrations", desc: "Let new users sign up for an account." },
  { key: "allowSkinScans", label: "Allow Skin Scans", desc: "Let users run the AI skin analysis." },
  { key: "allowProductScans", label: "Allow Product Scans", desc: "Let users scan product labels." },
  { key: "allowReviews", label: "Allow Reviews", desc: "Let users leave product reviews." },
  { key: "allowGroupPosts", label: "Allow Group Posts", desc: "Let users post in community groups." },
];

const DEFAULT_SETTINGS = {
  appName: "Skinova",
  maintenanceMode: false,
  maintenanceMessage: "",
  allowNewRegistrations: true,
  allowSkinScans: true,
  allowProductScans: true,
  allowReviews: true,
  allowGroupPosts: true,
  contactEmail: "",
  contactPhone: "",
  termsUrl: "",
  privacyUrl: "",
  currency: "ILS",
};

function AppSettingsTab() {
  const toast = useToast();
  const [settings, setSettings] = useState(DEFAULT_SETTINGS);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    adminService
      .fetchSettings()
      .then((data) => setSettings({ ...DEFAULT_SETTINGS, ...data }))
      .catch(() => toast.error("Couldn't load app settings."))
      .finally(() => setLoading(false));
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const toggle = (key) => setSettings((s) => ({ ...s, [key]: !s[key] }));
  const update = (key, value) => setSettings((s) => ({ ...s, [key]: value }));

  const handleSave = async () => {
    setSaving(true);
    try {
      const data = await adminService.updateSettings(settings);
      setSettings({ ...DEFAULT_SETTINGS, ...data });
      toast.success("Settings saved.");
    } catch {
      toast.error("Couldn't save settings.");
    } finally {
      setSaving(false);
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center py-16">
        <Loader2 className="animate-spin text-wine" size={28} />
      </div>
    );
  }

  return (
    <div className="flex flex-col gap-5">
      <Card className="p-5 flex flex-col gap-4" hover={false}>
        <h3 className="font-display text-lg font-bold text-ink">Feature Toggles</h3>
        {TOGGLE_ITEMS.map((item) => (
          <label key={item.key} className="flex items-center justify-between gap-4 cursor-pointer">
            <div>
              <p className="text-sm font-semibold text-ink">{item.label}</p>
              <p className="text-xs text-subtext">{item.desc}</p>
            </div>
            <input
              type="checkbox"
              checked={!!settings[item.key]}
              onChange={() => toggle(item.key)}
              className="accent-wine h-5 w-5 shrink-0"
            />
          </label>
        ))}
        {settings.maintenanceMode && (
          <FormField label="Maintenance Message">
            <textarea
              value={settings.maintenanceMessage}
              onChange={(e) => update("maintenanceMessage", e.target.value)}
              rows={2}
              className={inputClass}
            />
          </FormField>
        )}
      </Card>

      <Card className="p-5 flex flex-col gap-4" hover={false}>
        <h3 className="font-display text-lg font-bold text-ink">General</h3>
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <FormField label="App Name">
            <input type="text" value={settings.appName} onChange={(e) => update("appName", e.target.value)} className={inputClass} />
          </FormField>
          <FormField label="Currency">
            <input type="text" value={settings.currency} onChange={(e) => update("currency", e.target.value)} className={inputClass} />
          </FormField>
          <FormField label="Contact Email">
            <input
              type="email"
              value={settings.contactEmail}
              onChange={(e) => update("contactEmail", e.target.value)}
              className={inputClass}
            />
          </FormField>
          <FormField label="Contact Phone">
            <input
              type="text"
              value={settings.contactPhone}
              onChange={(e) => update("contactPhone", e.target.value)}
              className={inputClass}
            />
          </FormField>
          <FormField label="Terms of Service URL">
            <input type="text" value={settings.termsUrl} onChange={(e) => update("termsUrl", e.target.value)} className={inputClass} />
          </FormField>
          <FormField label="Privacy Policy URL">
            <input type="text" value={settings.privacyUrl} onChange={(e) => update("privacyUrl", e.target.value)} className={inputClass} />
          </FormField>
        </div>
      </Card>

      <div className="flex justify-end">
        <Button onClick={handleSave} disabled={saving}>
          {saving ? <Loader2 size={15} className="animate-spin" /> : <Save size={15} />}
          Save settings
        </Button>
      </div>
    </div>
  );
}

export default function SettingsPage() {
  const [tab, setTab] = useState("account");

  return (
    <div className="flex flex-col gap-5 max-w-3xl">
      <div className="animate-fade-slide-in">
        <h2 className="font-display text-2xl font-bold text-ink">Settings</h2>
        <p className="text-sm text-subtext mt-1">Manage your admin account and app-wide configuration.</p>
      </div>

      <Tabs tabs={TABS} value={tab} onChange={setTab} />

      {tab === "account" && <AccountTab />}
      {tab === "app" && <AppSettingsTab />}
    </div>
  );
}
