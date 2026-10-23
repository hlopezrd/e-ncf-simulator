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

export interface EcfItem {
  trackId: string;
  estado: string;
  rncEmisor: string;
  eNCF: string;
  tipoComprobante: string | null;
  fechaEmision: string | null;
  fechaRecepcion: string;
  errores: unknown[];
  advertencias: unknown[];
}

export interface EcfListResponse {
  data: EcfItem[];
  meta: { total: number; page: number; per_page: number };
}

export interface EmpresaItem {
  rnc: string;
  totalEcf: number;
  ultimaRecepcion: string | null;
}

export interface EmpresaListResponse {
  data: EmpresaItem[];
  meta: { total: number };
}

export const ecfApi = {
  list: (params?: { page?: number; per_page?: number; estado?: string; rnc?: string }) => {
    const q = new URLSearchParams();
    if (params?.page) q.set("page", String(params.page));
    if (params?.per_page) q.set("per_page", String(params.per_page));
    if (params?.estado) q.set("estado", params.estado);
    if (params?.rnc) q.set("rnc", params.rnc);
    return apiFetch<EcfListResponse>(`/api/ecf?${q.toString()}`);
  },
  detail: (trackId: string, token: string) => apiFetch<EcfItem & { xml: string }>(`/api/ecf/${trackId}`, {}, token),
};

export const empresasApi = {
  list: () => apiFetch<EmpresaListResponse>("/api/empresas"),
};

export interface CertificadoItem {
  id: number;
  rnc: string;
  alias: string | null;
  subject: string | null;
  issuer: string | null;
  serial: string | null;
  notBefore: string | null;
  notAfter: string | null;
  thumbprint: string | null;
  createdAt: string;
}

export interface CertificadoListResponse {
  data: CertificadoItem[];
  meta: { total: number };
}

export const certificadosApi = {
  list: () => apiFetch<CertificadoListResponse>("/api/certificados"),
};

export interface ValidacionItem {
  id: number;
  codigo: string;
  campo: string;
  mensaje: string;
  severidad: string;
  trackId: string;
  rncEmisor: string;
  eNCF: string;
  createdAt: string;
}

export interface ValidacionListResponse {
  data: ValidacionItem[];
  meta: { total: number };
}

export const validacionesApi = {
  list: (severidad?: string) => {
    const q = severidad ? `?severidad=${encodeURIComponent(severidad)}` : "";
    return apiFetch<ValidacionListResponse>(`/api/validaciones${q}`);
  },
};

export interface TrackIdQueryResponse {
  trackId: string | null;
  estado: string;
  rncEmisor?: string;
  eNCF?: string;
  fechaRecepcion?: string;
  mensaje?: string;
}

export const trackidsApi = {
  byTrackId: (trackId: string, token: string) =>
    apiFetch<TrackIdQueryResponse>(`/api/consulta-estado/${trackId}`, {}, token),
  byRncEncf: (rnc: string, encf: string, token: string) =>
    apiFetch<TrackIdQueryResponse>(
      `/api/trackids/consulta?rncemisor=${encodeURIComponent(rnc)}&encf=${encodeURIComponent(encf)}`,
      {},
      token
    ),
};