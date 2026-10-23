import { createContext, useContext, useState, useCallback, type ReactNode } from "react";
import type { AuthCredentials } from "../types/auth";
import { authApi } from "../lib/api";

interface AuthContextValue {
  isAuthenticated: boolean;
  login: (creds: AuthCredentials) => Promise<void>;
  logout: () => Promise<void>;
}

const AuthContext = createContext<AuthContextValue | null>(null);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [isAuthenticated, setIsAuthenticated] = useState(false);

  const login = useCallback(async (creds: AuthCredentials) => {
    await authApi.login(creds);
    setIsAuthenticated(true);
  }, []);

  const logout = useCallback(async () => {
    await fetch("/api/auth", { method: "DELETE", credentials: "include" }).catch(() => {});
    setIsAuthenticated(false);
  }, []);

  return (
    <AuthContext.Provider value={{ isAuthenticated, login, logout }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth(): AuthContextValue {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth must be used within AuthProvider");
  return ctx;
}