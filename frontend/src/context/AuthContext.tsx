import { createContext, useContext, useState, useCallback, useEffect, type ReactNode } from "react";
import type { AuthCredentials } from "../types/auth";
import { authApi, empresasApi } from "../lib/api";
import { setUnauthorizedHandler } from "../lib/authEvents";

interface AuthContextValue {
  isAuthenticated: boolean;
  loading: boolean;
  login: (creds: AuthCredentials) => Promise<void>;
  logout: () => Promise<void>;
}

const AuthContext = createContext<AuthContextValue | null>(null);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    setUnauthorizedHandler(() => setIsAuthenticated(false));
    empresasApi
      .list()
      .then(() => setIsAuthenticated(true))
      .catch(() => setIsAuthenticated(false))
      .finally(() => setLoading(false));
    return () => setUnauthorizedHandler(null);
  }, []);

  const login = useCallback(async (creds: AuthCredentials) => {
    await authApi.login(creds);
    setIsAuthenticated(true);
  }, []);

  const logout = useCallback(async () => {
    await fetch("/api/auth", { method: "DELETE", credentials: "include" }).catch(() => {});
    setIsAuthenticated(false);
  }, []);

  if (loading) {
    return <div style={{ display: "flex", alignItems: "center", justifyContent: "center", minHeight: "100vh" }}>Cargando...</div>;
  }

  return (
    <AuthContext.Provider value={{ isAuthenticated, loading, login, logout }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth(): AuthContextValue {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth must be used within AuthProvider");
  return ctx;
}