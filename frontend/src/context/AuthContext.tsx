import { createContext, useContext, useState, useCallback, type ReactNode } from "react";
import type { AuthCredentials, AuthResponse } from "../types/auth";
import { authApi } from "../lib/api";
import { setToken as storeToken, getToken } from "../lib/tokenStore";

interface AuthContextValue {
  token: string | null;
  isAuthenticated: boolean;
  login: (creds: AuthCredentials) => Promise<void>;
  logout: () => void;
}

const AuthContext = createContext<AuthContextValue | null>(null);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [token, setToken] = useState<string | null>(() => getToken());

  const login = useCallback(async (creds: AuthCredentials) => {
    const res: AuthResponse = await authApi.login(creds);
    setToken(res.token);
    storeToken(res.token);
  }, []);

  const logout = useCallback(() => {
    setToken(null);
    storeToken(null);
  }, []);

  return (
    <AuthContext.Provider value={{ token, isAuthenticated: !!token, login, logout }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth(): AuthContextValue {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth must be used within AuthProvider");
  return ctx;
}