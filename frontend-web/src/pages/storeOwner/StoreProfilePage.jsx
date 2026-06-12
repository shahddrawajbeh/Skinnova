import { useEffect, useState } from "react";
import { Camera, Image as ImageIcon, Loader2, Plus, Trash2, Save } from "lucide-react";
import Card from "../../components/common/Card";
import Button from "../../components/common/Button";
import { inputClass, FormField } from "../../components/common/AuthLayout";
import { resolveImageUrl } from "../../services/api";
import { useStoreOwner } from "../../context/StoreOwnerContext";
import { useToast } from "../../context/ToastContext";
import { storeOwnerService } from "../../services/storeOwnerService";

const EMPTY_FORM = {
  storeName: "",
  description: "",
  city: "",
  address: "",
  phone: "",
  returnPolicy: "",
};

export default function StoreProfilePage() {
  const { store, refreshStore } = useStoreOwner();
  const toast = useToast();
  const [form, setForm] = useState(EMPTY_FORM);
  const [workingHours, setWorkingHours] = useState([]);
  const [saving, setSaving] = useState(false);
  const [uploadingLogo, setUploadingLogo] = useState(false);
  const [uploadingCover, setUploadingCover] = useState(false);
  const [uploadingGallery, setUploadingGallery] = useState(false);

  useEffect(() => {
    if (!store) return;
    setForm({
      storeName: store.storeName || "",
      description: store.description || "",
      city: store.city || "",
      address: store.address || "",
      phone: store.phone || "",
      returnPolicy: store.returnPolicy || "",
    });
    setWorkingHours(store.deliveryInfo?.workingHours || []);
  }, [store]);

  const handleField = (key) => (e) => setForm((f) => ({ ...f, [key]: e.target.value }));

  const handleLogoChange = async (e) => {
    const file = e.target.files?.[0];
    if (!file) return;
    setUploadingLogo(true);
    try {
      await storeOwnerService.uploadLogo(store._id, file);
      await refreshStore();
      toast.success("Logo updated.");
    } catch {
      toast.error("Couldn't upload logo.");
    } finally {
      setUploadingLogo(false);
    }
  };

  const handleCoverChange = async (e) => {
    const file = e.target.files?.[0];
    if (!file) return;
    setUploadingCover(true);
    try {
      await storeOwnerService.uploadCover(store._id, file);
      await refreshStore();
      toast.success("Cover image updated.");
    } catch {
      toast.error("Couldn't upload cover image.");
    } finally {
      setUploadingCover(false);
    }
  };

  const handleGalleryAdd = async (e) => {
    const file = e.target.files?.[0];
    if (!file) return;
    setUploadingGallery(true);
    try {
      await storeOwnerService.addGalleryImage(store._id, file);
      await refreshStore();
      toast.success("Image added to gallery.");
    } catch {
      toast.error("Couldn't add gallery image.");
    } finally {
      setUploadingGallery(false);
    }
  };

  const handleGalleryRemove = async (url) => {
    try {
      await storeOwnerService.removeGalleryImage(store._id, url);
      await refreshStore();
    } catch {
      toast.error("Couldn't remove gallery image.");
    }
  };

  const updateHour = (i, key, value) => {
    setWorkingHours((prev) => prev.map((h, idx) => (idx === i ? { ...h, [key]: value } : h)));
  };

  const addHourRow = () => {
    setWorkingHours((prev) => [...prev, { day: "", hours: "", isOpen: true }]);
  };

  const removeHourRow = (i) => {
    setWorkingHours((prev) => prev.filter((_, idx) => idx !== i));
  };

  const handleSave = async () => {
    setSaving(true);
    try {
      await storeOwnerService.updateStore(store._id, {
        ...form,
        "deliveryInfo.workingHours": workingHours,
      });
      await refreshStore();
      toast.success("Store profile saved.");
    } catch (err) {
      toast.error(err.response?.data?.message || "Couldn't save store profile.");
    } finally {
      setSaving(false);
    }
  };

  if (!store) return null;

  return (
    <div className="flex flex-col gap-5 max-w-3xl">
      <div className="animate-fade-slide-in">
        <h2 className="font-display text-2xl font-bold text-ink">Store Profile</h2>
        <p className="text-sm text-subtext mt-1">Update how your store appears to customers.</p>
      </div>

      <Card className="overflow-hidden" hover={false}>
        <div className="relative h-40 bg-soft-pink">
          {store.coverImageUrl && (
            <img src={resolveImageUrl(store.coverImageUrl)} alt="" className="h-full w-full object-cover" />
          )}
          <label className="absolute bottom-3 right-3 cursor-pointer inline-flex items-center gap-2 px-3 py-1.5 rounded-full text-xs font-semibold bg-white/90 text-wine hover:bg-white transition-all">
            {uploadingCover ? <Loader2 size={14} className="animate-spin" /> : <Camera size={14} />}
            Change cover
            <input type="file" accept="image/*" className="hidden" onChange={handleCoverChange} disabled={uploadingCover} />
          </label>
        </div>
        <div className="p-5 flex items-center gap-4 -mt-10">
          <div className="relative h-20 w-20 rounded-2xl overflow-hidden bg-white border-4 border-white shadow-md shrink-0">
            {store.logoUrl ? (
              <img src={resolveImageUrl(store.logoUrl)} alt="" className="h-full w-full object-cover" />
            ) : (
              <div className="h-full w-full flex items-center justify-center bg-soft-pink text-wine font-display text-2xl">
                {store.storeName?.[0] || "S"}
              </div>
            )}
            <label className="absolute inset-0 flex items-center justify-center bg-black/30 opacity-0 hover:opacity-100 transition-opacity cursor-pointer">
              {uploadingLogo ? (
                <Loader2 size={16} className="animate-spin text-white" />
              ) : (
                <Camera size={16} className="text-white" />
              )}
              <input type="file" accept="image/*" className="hidden" onChange={handleLogoChange} disabled={uploadingLogo} />
            </label>
          </div>
          <div className="pt-10">
            <p className="font-display text-lg font-bold text-ink">{store.storeName}</p>
            <p className="text-xs text-subtext">{store.city}</p>
          </div>
        </div>
      </Card>

      <Card className="p-5 flex flex-col gap-4" hover={false}>
        <h3 className="font-display text-lg font-bold text-ink">Store details</h3>
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <FormField label="Store Name">
            <input type="text" value={form.storeName} onChange={handleField("storeName")} className={inputClass} />
          </FormField>
          <FormField label="Phone">
            <input type="text" value={form.phone} onChange={handleField("phone")} className={inputClass} />
          </FormField>
          <FormField label="City">
            <input type="text" value={form.city} onChange={handleField("city")} className={inputClass} />
          </FormField>
          <FormField label="Address">
            <input type="text" value={form.address} onChange={handleField("address")} className={inputClass} />
          </FormField>
        </div>
        <FormField label="Description">
          <textarea value={form.description} onChange={handleField("description")} rows={3} className={inputClass} />
        </FormField>
        <FormField label="Return Policy">
          <textarea
            value={form.returnPolicy}
            onChange={handleField("returnPolicy")}
            rows={3}
            className={inputClass}
            placeholder="Describe your return and refund policy..."
          />
        </FormField>
      </Card>

      <Card className="p-5 flex flex-col gap-3" hover={false}>
        <div className="flex items-center justify-between">
          <h3 className="font-display text-lg font-bold text-ink">Working hours</h3>
          <Button variant="secondary" size="sm" onClick={addHourRow}>
            <Plus size={14} /> Add
          </Button>
        </div>
        {workingHours.length === 0 && <p className="text-sm text-subtext">No working hours added.</p>}
        {workingHours.map((h, i) => (
          <div key={i} className="flex flex-wrap items-center gap-2">
            <input
              type="text"
              value={h.day}
              onChange={(e) => updateHour(i, "day", e.target.value)}
              placeholder="Day (e.g. Sunday – Thursday)"
              className={`${inputClass} flex-1 min-w-[160px]`}
            />
            <input
              type="text"
              value={h.hours}
              onChange={(e) => updateHour(i, "hours", e.target.value)}
              placeholder="Hours (e.g. 10:00 AM – 8:00 PM)"
              className={`${inputClass} flex-1 min-w-[160px]`}
              disabled={!h.isOpen}
            />
            <label className="flex items-center gap-1.5 text-xs font-medium text-subtext shrink-0">
              <input
                type="checkbox"
                checked={h.isOpen}
                onChange={(e) => updateHour(i, "isOpen", e.target.checked)}
                className="accent-wine"
              />
              Open
            </label>
            <button onClick={() => removeHourRow(i)} className="p-2 rounded-full text-danger hover:bg-soft-pink transition-all shrink-0">
              <Trash2 size={15} />
            </button>
          </div>
        ))}
      </Card>

      <Card className="p-5 flex flex-col gap-3" hover={false}>
        <div className="flex items-center justify-between">
          <h3 className="font-display text-lg font-bold text-ink">Gallery</h3>
          <label className="cursor-pointer">
            <span className="inline-flex items-center gap-2 px-3 py-1.5 rounded-full text-xs font-semibold bg-soft-pink text-wine hover:bg-dusty-rose-light transition-all">
              {uploadingGallery ? <Loader2 size={14} className="animate-spin" /> : <ImageIcon size={14} />}
              Add image
            </span>
            <input type="file" accept="image/*" className="hidden" onChange={handleGalleryAdd} disabled={uploadingGallery} />
          </label>
        </div>
        {(store.galleryImages || []).length === 0 ? (
          <p className="text-sm text-subtext">No gallery images yet.</p>
        ) : (
          <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
            {store.galleryImages.map((url) => (
              <div key={url} className="relative h-24 rounded-xl overflow-hidden bg-soft-pink group">
                <img src={resolveImageUrl(url)} alt="" className="h-full w-full object-cover" />
                <button
                  onClick={() => handleGalleryRemove(url)}
                  className="absolute top-1.5 right-1.5 h-7 w-7 rounded-full bg-black/50 text-white flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity"
                  aria-label="Remove image"
                >
                  <Trash2 size={13} />
                </button>
              </div>
            ))}
          </div>
        )}
      </Card>

      <div className="flex justify-end">
        <Button onClick={handleSave} disabled={saving}>
          {saving ? <Loader2 size={15} className="animate-spin" /> : <Save size={15} />}
          Save changes
        </Button>
      </div>
    </div>
  );
}
