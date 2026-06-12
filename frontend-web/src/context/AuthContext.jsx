import { createContext, useCallback, useContext, useEffect, useState } from "react";
import { authService } from "../services/authService";

const AuthContext = createContext(null);

export function AuthProvider({ children }) {
  const [user, setUser] = useState(() => {
    const userId = localStorage.getItem("userId");
    const userRole = localStorage.getItem("userRole");
    const fullName = localStorage.getItem("fullName");
    return userId ? { userId, role: userRole, fullName } : null;
  });
  const [profile, setProfile] = useState(null);
  const [loading, setLoading] = useState(false);

  const persist = (data) => {
    localStorage.setItem("userId", data.userId);
    localStorage.setItem("userRole", data.role || "user");
    localStorage.setItem("fullName", data.fullName || "");
    setUser({ userId: data.userId, role: data.role, fullName: data.fullName });
  };

  const login = useCallback(async (email, password) => {
    setLoading(true);
    try {
      const data = await authService.login(email, password);
      persist(data);
      return data;
    } finally {
      setLoading(false);
    }
  }, []);

  const register = useCallback(async (fullName, email, password) => {
    setLoading(true);
    try {
      const data = await authService.register(fullName, email, password);
      const loginData = await authService.login(email, password);
      persist(loginData);
      return { ...data, ...loginData };
    } finally {
      setLoading(false);
    }
  }, []);

  const logout = useCallback(() => {
    localStorage.removeItem("userId");
    localStorage.removeItem("userRole");
    localStorage.removeItem("fullName");
    setUser(null);
    setProfile(null);
  }, []);

  const refreshProfile = useCallback(async () => {
    if (!user?.userId) return null;
    const data = await authService.getProfile(user.userId);
    setProfile(data);
    return data;
  }, [user?.userId]);

  useEffect(() => {
    if (user?.userId) {
      refreshProfile().catch(() => {});
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [user?.userId]);

  return (
    <AuthContext.Provider
      value={{
        user,
        profile,
        loading,
        isAuthenticated: !!user,
        login,
        register,
        logout,
        refreshProfile,
        setProfile,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}

// eslint-disable-next-line react-refresh/only-export-components
export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth must be used within AuthProvider");
  return ctx;
}
