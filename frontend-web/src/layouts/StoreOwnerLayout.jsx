import { useState } from "react";
import { Outlet, Link } from "react-router-dom";
import { AlertTriangle } from "lucide-react";
import { StoreOwnerProvider, useStoreOwner } from "../context/StoreOwnerContext";
import Sidebar from "../components/storeOwner/Sidebar";
import Topbar from "../components/storeOwner/Topbar";
import StorePendingScreen from "../components/storeOwner/StorePendingScreen";

function StoreOwnerContent() {
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const { store, loading, error } = useStoreOwner();

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-cream">
        <div className="h-10 w-10 rounded-full border-4 border-soft-pink border-t-wine animate-spin" />
      </div>
    );
  }

  if (error || !store) {
    return <StorePendingScreen status={error || "no-store"} />;
  }

  if (store.approvalStatus !== "approved") {
    return <StorePendingScreen status={store.approvalStatus} reason={store.rejectionReason} />;
  }

  return (
    <div className="flex min-h-screen bg-cream">
      <Sidebar open={sidebarOpen} onClose={() => setSidebarOpen(false)} />
      <div className="flex-1 flex flex-col min-w-0">
        <Topbar onMenuClick={() => setSidebarOpen(true)} />
        {store.isActive === false && (
          <div className="print:hidden bg-gold/20 border-b border-gold/40 text-wine-dark text-sm px-4 sm:px-6 py-2 flex items-center justify-between gap-2 animate-fade-slide-in">
            <span className="flex items-center gap-2">
              <AlertTriangle size={16} />
              Your store is currently inactive and hidden from customers.
            </span>
            <Link
              to="/store-owner/store-profile"
              className="font-semibold underline hover:no-underline shrink-0"
            >
              Reactivate
            </Link>
          </div>
        )}
        <main className="flex-1 p-4 sm:p-6">
          <Outlet />
        </main>
      </div>
    </div>
  );
}

export default function StoreOwnerLayout() {
  return (
    <StoreOwnerProvider>
      <StoreOwnerContent />
    </StoreOwnerProvider>
  );
}
