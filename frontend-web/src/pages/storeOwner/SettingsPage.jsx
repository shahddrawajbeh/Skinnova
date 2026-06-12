import { useEffect, useState } from "react";
import { Camera, Loader2, Lock, Plus, Save, Trash2 } from "lucide-react";
import Card from "../../components/common/Card";
import Button from "../../components/common/Button";
import Tabs from "../../components/common/Tabs";
import { inputClass, FormField } from "../../components/common/AuthLayout";
import { resolveImageUrl } from "../../services/api";
import { useAuth } from "../../context/AuthContext";
import { useStoreOwner } from "../../context/StoreOwnerContext";
import { useToast } from "../../context/ToastContext";
import { authService } from "../../services/authService";
import { notificationService } from "../../services/notificationService";
import { storeOwnerService } from "../../services/storeOwnerService";
import { SIDEBAR_DENSITY_EVENT, SIDEBAR_DENSITY_KEY } from "../../components/storeOwner/Sidebar";

const TABS = [
  { value: "account", label: "Account" },
  { value: "notifications", label: "Notifications" },
  { value: "store", label: "Store Preferences" },
  { value: "theme", label: "Theme" },
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
              {profile?.fullName?.[0] || "S"}
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

const NOTIFICATION_ITEMS = [
  { key: "inApp", label: "In-app notifications", desc: "Show alerts inside the dashboard." },
  { key: "push", label: "Push notifications", desc: "Receive push alerts on your devices." },
  { key: "email", label: "Email notifications", desc: "Get updates via email." },
];

function NotificationsTab() {
  const { user } = useAuth();
  const toast = useToast();
  const [settings, setSettings] = useState({ inApp: true, push: true, email: true });
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    notificationService
      .getSettings(user.userId)
      .then(setSettings)
      .catch(() => toast.error("Couldn't load notification settings."))
      .finally(() => setLoading(false));
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const toggle = (key) => setSettings((s) => ({ ...s, [key]: !s[key] }));

  const handleSave = async () => {
    setSaving(true);
    try {
      const data = await notificationService.updateSettings(user.userId, settings);
      setSettings(data.settings);
      toast.success("Notification settings saved.");
    } catch {
      toast.error("Couldn't save notification settings.");
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
    <Card className="p-5 flex flex-col gap-4" hover={false}>
      {NOTIFICATION_ITEMS.map((item) => (
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
      <div className="flex justify-end">
        <Button onClick={handleSave} disabled={saving}>
          {saving ? <Loader2 size={15} className="animate-spin" /> : <Save size={15} />}
          Save
        </Button>
      </div>
    </Card>
  );
}

const DELIVERY_METHODS = [
  { key: "localCourier", label: "Local courier", desc: "Standard delivery via courier." },
  { key: "expressDelivery", label: "Express delivery", desc: "Same-day or next-day delivery." },
  { key: "storePickup", label: "Store pickup", desc: "Customers collect from your store." },
];

function StorePreferencesTab() {
  const { store, refreshStore } = useStoreOwner();
  const toast = useToast();
  const [isActive, setIsActive] = useState(true);
  const [fees, setFees] = useState({ standardFee: 0, expressFee: 0, freeDeliveryOver: 0 });
  const [areas, setAreas] = useState([]);
  const [methods, setMethods] = useState({ localCourier: true, expressDelivery: true, storePickup: true });
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    if (!store) return;
    setIsActive(store.isActive !== false);
    const d = store.deliveryInfo || {};
    setFees({
      standardFee: d.standardFee ?? 0,
      expressFee: d.expressFee ?? 0,
      freeDeliveryOver: d.freeDeliveryOver ?? 0,
    });
    setAreas(d.areas || []);
    setMethods({
      localCourier: d.methods?.localCourier !== false,
      expressDelivery: d.methods?.expressDelivery !== false,
      storePickup: d.methods?.storePickup !== false,
    });
  }, [store]);

  const updateArea = (i, key, value) =>
    setAreas((prev) => prev.map((a, idx) => (idx === i ? { ...a, [key]: value } : a)));
  const addArea = () => setAreas((prev) => [...prev, { name: "", time: "1–2 days" }]);
  const removeArea = (i) => setAreas((prev) => prev.filter((_, idx) => idx !== i));

  const handleSave = async () => {
    setSaving(true);
    try {
      await storeOwnerService.updateStore(store._id, {
        isActive,
        "deliveryInfo.standardFee": Number(fees.standardFee) || 0,
        "deliveryInfo.expressFee": Number(fees.expressFee) || 0,
        "deliveryInfo.freeDeliveryOver": Number(fees.freeDeliveryOver) || 0,
        "deliveryInfo.areas": areas,
        "deliveryInfo.methods": methods,
      });
      await refreshStore();
      toast.success("Store preferences saved.");
    } catch (err) {
      toast.error(err.response?.data?.message || "Couldn't save store preferences.");
    } finally {
      setSaving(false);
    }
  };

  if (!store) return null;

  return (
    <div className="flex flex-col gap-5">
      <Card className="p-5 flex items-center justify-between gap-4" hover={false}>
        <div>
          <p className="font-semibold text-ink">Store is {isActive ? "Open" : "Closed"}</p>
          <p className="text-xs text-subtext mt-0.5">
            {isActive ? "Customers can browse and order from your store." : "Your store is hidden from customers."}
          </p>
        </div>
        <input
          type="checkbox"
          checked={isActive}
          onChange={(e) => setIsActive(e.target.checked)}
          className="accent-wine h-5 w-5 shrink-0"
        />
      </Card>

      <Card className="p-5 flex flex-col gap-3" hover={false}>
        <h3 className="font-display text-lg font-bold text-ink">Delivery fees (₪)</h3>
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
          <FormField label="Standard delivery">
            <input
              type="number"
              min="0"
              value={fees.standardFee}
              onChange={(e) => setFees((f) => ({ ...f, standardFee: e.target.value }))}
              className={inputClass}
            />
          </FormField>
          <FormField label="Express delivery">
            <input
              type="number"
              min="0"
              value={fees.expressFee}
              onChange={(e) => setFees((f) => ({ ...f, expressFee: e.target.value }))}
              className={inputClass}
            />
          </FormField>
          <FormField label="Free delivery over">
            <input
              type="number"
              min="0"
              value={fees.freeDeliveryOver}
              onChange={(e) => setFees((f) => ({ ...f, freeDeliveryOver: e.target.value }))}
              className={inputClass}
            />
          </FormField>
        </div>
      </Card>

      <Card className="p-5 flex flex-col gap-3" hover={false}>
        <h3 className="font-display text-lg font-bold text-ink">Delivery methods</h3>
        {DELIVERY_METHODS.map((m) => (
          <label key={m.key} className="flex items-center justify-between gap-4 cursor-pointer">
            <div>
              <p className="text-sm font-semibold text-ink">{m.label}</p>
              <p className="text-xs text-subtext">{m.desc}</p>
            </div>
            <input
              type="checkbox"
              checked={methods[m.key]}
              onChange={(e) => setMethods((mm) => ({ ...mm, [m.key]: e.target.checked }))}
              className="accent-wine h-5 w-5 shrink-0"
            />
          </label>
        ))}
      </Card>

      <Card className="p-5 flex flex-col gap-3" hover={false}>
        <div className="flex items-center justify-between">
          <h3 className="font-display text-lg font-bold text-ink">Delivery areas</h3>
          <Button variant="secondary" size="sm" onClick={addArea}>
            <Plus size={14} /> Add
          </Button>
        </div>
        {areas.length === 0 && <p className="text-sm text-subtext">No delivery areas added.</p>}
        {areas.map((a, i) => (
          <div key={i} className="flex flex-wrap items-center gap-2">
            <input
              type="text"
              value={a.name}
              onChange={(e) => updateArea(i, "name", e.target.value)}
              placeholder="Area name"
              className={`${inputClass} flex-1 min-w-[140px]`}
            />
            <input
              type="text"
              value={a.time}
              onChange={(e) => updateArea(i, "time", e.target.value)}
              placeholder="Delivery time"
              className={`${inputClass} flex-1 min-w-[140px]`}
            />
            <button onClick={() => removeArea(i)} className="p-2 rounded-full text-danger hover:bg-soft-pink transition-all shrink-0">
              <Trash2 size={15} />
            </button>
          </div>
        ))}
      </Card>

      <div className="flex justify-end">
        <Button onClick={handleSave} disabled={saving}>
          {saving ? <Loader2 size={15} className="animate-spin" /> : <Save size={15} />}
          Save preferences
        </Button>
      </div>
    </div>
  );
}

function ThemeTab() {
  const [compact, setCompact] = useState(() => localStorage.getItem(SIDEBAR_DENSITY_KEY) === "compact");

  const handleChange = (value) => {
    localStorage.setItem(SIDEBAR_DENSITY_KEY, value);
    window.dispatchEvent(new Event(SIDEBAR_DENSITY_EVENT));
    setCompact(value === "compact");
  };

  return (
    <Card className="p-5 flex flex-col gap-4" hover={false}>
      <div>
        <h3 className="font-display text-lg font-bold text-ink">Sidebar density</h3>
        <p className="text-sm text-subtext mt-1">Choose how spacious the dashboard sidebar feels.</p>
      </div>
      <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
        <button
          onClick={() => handleChange("comfortable")}
          className={`rounded-xl border p-4 text-left transition-all ${
            !compact ? "border-wine bg-soft-pink" : "border-divider hover:bg-cream"
          }`}
        >
          <p className="text-sm font-semibold text-ink">Comfortable</p>
          <p className="text-xs text-subtext mt-1">More breathing room between menu items.</p>
        </button>
        <button
          onClick={() => handleChange("compact")}
          className={`rounded-xl border p-4 text-left transition-all ${
            compact ? "border-wine bg-soft-pink" : "border-divider hover:bg-cream"
          }`}
        >
          <p className="text-sm font-semibold text-ink">Compact</p>
          <p className="text-xs text-subtext mt-1">Tighter spacing to fit more on screen.</p>
        </button>
      </div>
    </Card>
  );
}

export default function SettingsPage() {
  const [tab, setTab] = useState("account");

  return (
    <div className="flex flex-col gap-5 max-w-3xl">
      <div className="animate-fade-slide-in">
        <h2 className="font-display text-2xl font-bold text-ink">Settings</h2>
        <p className="text-sm text-subtext mt-1">Manage your account, store, and dashboard preferences.</p>
      </div>

      <Tabs tabs={TABS} value={tab} onChange={setTab} />

      {tab === "account" && <AccountTab />}
      {tab === "notifications" && <NotificationsTab />}
      {tab === "store" && <StorePreferencesTab />}
      {tab === "theme" && <ThemeTab />}
    </div>
  );
}
