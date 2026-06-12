import { createContext, useCallback, useContext, useEffect, useState } from "react";
import { useAuth } from "./AuthContext";
import { storeOwnerService } from "../services/storeOwnerService";

const StoreOwnerContext = createContext(null);

export function StoreOwnerProvider({ children }) {
  const { user } = useAuth();
  const [store, setStore] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  const refreshStore = useCallback(async () => {
    if (!user?.userId) return;
    setLoading(true);
    setError(null);
    try {
      const data = await storeOwnerService.fetchMyStore(user.userId);
      setStore(data);
    } catch (err) {
      setStore(null);
      setError(err.response?.status === 404 ? "no-store" : "error");
    } finally {
      setLoading(false);
    }
  }, [user?.userId]);

  useEffect(() => {
    refreshStore();
  }, [refreshStore]);

  return (
    <StoreOwnerContext.Provider value={{ store, loading, error, refreshStore }}>
      {children}
    </StoreOwnerContext.Provider>
  );
}

// eslint-disable-next-line react-refresh/only-export-components
export function useStoreOwner() {
  const ctx = useContext(StoreOwnerContext);
  if (!ctx) throw new Error("useStoreOwner must be used within StoreOwnerProvider");
  return ctx;
}
