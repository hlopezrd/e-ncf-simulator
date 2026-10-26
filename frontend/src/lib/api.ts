import type { AuthResponse } from "../types/auth";

const BASE = "";

import { getUnauthorizedHandler } from "./authEvents";

export async function apiFetch<T>(
  path: string,
  options: RequestInit = {},
  _token?: string | null
): Promise<T> {
  const isForm = options.body instanceof FormData;
  const headers: Record<string, string> = isForm
    ? { ...(options.headers as Record<string, string>) }
    : {
        "Content-Type": "application/json",
        ...(options.headers as Record<string, string>),
      };

  const res = await fetch(`${BASE}${path}`, { ...options, headers, credentials: "include" });
  if (res.status === 401) {
    getUnauthorizedHandler()?.();
  }
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

export interface MeResponse {
  id: number;
  name: string;
  email: string;
  role: string;
  rnc: string;
}

export const meApi = {
  get: () => apiFetch<MeResponse>("/api/me"),
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
  detail: (trackId: string) => apiFetch<EcfItem & { xml: string }>(`/api/ecf/${trackId}`),
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
  active: boolean;
  createdAt: string;
}

export interface CertificadoListResponse {
  data: CertificadoItem[];
  meta: { total: number };
}

export const certificadosApi = {
  list: () => apiFetch<CertificadoListResponse>("/api/certificados"),
  create: (data: { rnc: string; alias_name?: string; file: File }) => {
    const fd = new FormData();
    fd.append("rnc", data.rnc);
    if (data.alias_name) fd.append("alias_name", data.alias_name);
    fd.append("file", data.file);
    return apiFetch<CertificadoItem>("/api/certificados", { method: "POST", body: fd });
  },
  update: (id: number, data: { alias_name?: string; subject?: string; issuer?: string }) =>
    apiFetch<CertificadoItem>(`/api/certificados/${id}`, { method: "PATCH", body: JSON.stringify(data) }),
  remove: (id: number) => apiFetch<void>(`/api/certificados/${id}`, { method: "DELETE" }),
};

export interface NcfSequenceItem {
  id: number;
  rnc: string;
  tipo: number;
  desde: number;
  hasta: number;
  fechaVencimiento: string | null;
  activa: boolean;
  anulada: boolean;
  vigente: boolean;
  estado: string;
  consumidos: number;
  disponibles: number;
  anulados: number;
  rangosAnulados: { desde: number; hasta: number }[];
  createdAt: string;
  deletedAt: string | null;
}

export interface NcfSequenceListResponse {
  data: NcfSequenceItem[];
  meta: { total: number };
}

export const ncfSequencesApi = {
  list: () => apiFetch<NcfSequenceListResponse>("/api/ncf_sequences"),
  create: (data: { rnc: string; tipo: number; desde: number; hasta: number; fecha_vencimiento: string; activa?: boolean }) =>
    apiFetch<NcfSequenceItem>("/api/ncf_sequences", { method: "POST", body: JSON.stringify(data) }),
  update: (id: number, data: Partial<{ rnc: string; tipo: number; desde: number; hasta: number; fecha_vencimiento: string; activa: boolean }>) =>
    apiFetch<NcfSequenceItem>(`/api/ncf_sequences/${id}`, { method: "PATCH", body: JSON.stringify(data) }),
  remove: (id: number) => apiFetch<void>(`/api/ncf_sequences/${id}`, { method: "DELETE" }),
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

export interface ReglaItem {
  id: number;
  name: string;
  description: string | null;
  ruleType: string;
  active: boolean;
  value: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface ReglaListResponse {
  data: ReglaItem[];
  meta: { total: number };
}

export const reglasApi = {
  list: (active?: boolean) => {
    const q = active !== undefined ? `?active=${active}` : "";
    return apiFetch<ReglaListResponse>(`/api/reglas${q}`);
  },
  create: (data: { name: string; description?: string; rule_type: string; active?: boolean; value?: string }) =>
    apiFetch<ReglaItem>("/api/simulation_rules", { method: "POST", body: JSON.stringify(data) }),
  update: (id: number, data: Partial<{ name: string; description: string; rule_type: string; active: boolean; value: string }>) =>
    apiFetch<ReglaItem>(`/api/simulation_rules/${id}`, { method: "PATCH", body: JSON.stringify(data) }),
  remove: (id: number) =>
    apiFetch<void>(`/api/simulation_rules/${id}`, { method: "DELETE" }),
};

export interface AllowedOriginItem {
  id: number;
  origin: string;
  createdAt: string;
}

export interface AllowedOriginListResponse {
  data: AllowedOriginItem[];
  meta: { total: number };
}

export const allowedOriginsApi = {
  list: () => apiFetch<AllowedOriginListResponse>("/api/allowed_origins"),
  create: (origin: string) =>
    apiFetch<AllowedOriginItem>("/api/allowed_origins", { method: "POST", body: JSON.stringify({ origin }) }),
  remove: (id: number) => apiFetch<void>(`/api/allowed_origins/${id}`, { method: "DELETE" }),
};

export interface UsuarioItem {
  id: number;
  name: string;
  email: string;
  rnc: string;
  username: string;
  role: string;
  active: boolean;
  createdAt: string;
}

export interface RoleItem {
  id: number;
  name: string;
  description: string | null;
}

export interface UsuarioListResponse {
  users: UsuarioItem[];
  roles: RoleItem[];
  meta: { total_users: number; total_roles: number };
}

export const usuariosApi = {
  list: () => apiFetch<UsuarioListResponse>("/api/usuarios"),
  create: (data: { name: string; email: string; rnc: string; username: string; password: string; role_id: number; active?: boolean }) =>
    apiFetch<UsuarioItem>("/api/usuarios", { method: "POST", body: JSON.stringify(data) }),
  update: (id: number, data: { name?: string; email?: string; role_id?: number; active?: boolean; password?: string }) =>
    apiFetch<UsuarioItem>(`/api/usuarios/${id}`, { method: "PATCH", body: JSON.stringify(data) }),
  remove: (id: number) => apiFetch<void>(`/api/usuarios/${id}`, { method: "DELETE" }),
};

export const rolesApi = {
  create: (data: { name: string; description?: string }) =>
    apiFetch<RoleItem>("/api/roles", { method: "POST", body: JSON.stringify(data) }),
};

export interface AuditItem {
  id: number;
  actor: string;
  action: string;
  target: string | null;
  details: string | null;
  createdAt: string;
}

export interface AuditListResponse {
  data: AuditItem[];
  meta: { total: number };
}

export const auditoriaApi = {
  list: (actor?: string, action?: string) => {
    const q = new URLSearchParams();
    if (actor) q.set("actor", actor);
    if (action) q.set("action_type", action);
    return apiFetch<AuditListResponse>(`/api/auditoria?${q.toString()}`);
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
  byTrackId: (trackId: string) =>
    apiFetch<TrackIdQueryResponse>(`/api/consulta-estado/${trackId}`),
  byRncEncf: (rnc: string, encf: string) =>
    apiFetch<TrackIdQueryResponse>(
      `/api/trackids/consulta?rncemisor=${encodeURIComponent(rnc)}&encf=${encodeURIComponent(encf)}`
    ),
};