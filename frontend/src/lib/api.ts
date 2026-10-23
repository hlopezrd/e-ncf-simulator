import type { AuthResponse } from "../types/auth";

const BASE = "";

export async function apiFetch<T>(
  path: string,
  options: RequestInit = {},
  token?: string | null
): Promise<T> {
  const headers: Record<string, string> = {
    "Content-Type": "application/json",
    ...(options.headers as Record<string, string>),
  };
  if (token) headers["Authorization"] = `Bearer ${token}`;

  const res = await fetch(`${BASE}${path}`, { ...options, headers });
  if (!res.ok) {
    const body = await res.json().catch(() => ({}));
    throw new ApiError(res.status, body);
  }
  return res.json() as Promise<T>;
}

export class ApiError extends Error {
  status: number;
  body: unknown;
  constructor(status: number, body: unknown) {
    super(`HTTP ${status}`);
    this.status = status;
    this.body = body;
  }
}

export const authApi = {
  login: (creds: { rnc: string; usuario: string; password: string }) =>
    apiFetch<AuthResponse>("/api/auth", {
      method: "POST",
      body: JSON.stringify(creds),
    }),
};

export const healthApi = {
  check: () => apiFetch<{ status: string; service: string; timestamp: string }>("/health"),
};