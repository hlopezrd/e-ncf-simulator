import { createContext, useContext, useState, useCallback, useEffect, type ReactNode } from "react";
import type { AuthCredentials } from "../types/auth";
import { authApi, meApi } from "../lib/api";

interface AuthContextValue {
  isAuthenticated: boolean;
  role: string | null;
  loading: boolean;
  login: (creds: AuthCredentials) => Promise<void>;
  logout: () => Promise<void>;
}

const AuthContext = createContext<AuthContextValue | null>(null);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [role, setRole] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  const refreshMe = useCallback(async () => {
    try {
      const me = await meApi.get();
      setIsAuthenticated(true);
      setRole(me.role);
    } catch {
      setIsAuthenticated(false);
      setRole(null);
    }
  }, []);

  useEffect(() => {
    refreshMe().finally(() => setLoading(false));
  }, [refreshMe]);

  const login = useCallback(async (creds: AuthCredentials) => {
    await authApi.login(creds);
    await refreshMe();
  }, [refreshMe]);

  const logout = useCallback(async () => {
    await fetch("/api/auth", { method: "DELETE", credentials: "include" }).catch(() => {});
    setIsAuthenticated(false);
    setRole(null);
  }, []);

  if (loading) {
    return <div style={{ display: "flex", alignItems: "center", justifyContent: "center", minHeight: "100vh" }}>Cargando...</div>;
  }

  return (
    <AuthContext.Provider value={{ isAuthenticated, role, loading, login, logout }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth(): AuthContextValue {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth must be used within AuthProvider");
  return ctx;
}