import type { ReactNode } from "react";
import { Link, useLocation } from "react-router-dom";
import { useAuth } from "../context/AuthContext";

const allNav = [
  { to: "/", label: "Dashboard", roles: ["admin", "operator", "viewer"] },
  { to: "/ecf", label: "e-CF", roles: ["admin", "operator", "viewer"] },
  { to: "/trackids", label: "TrackIds", roles: ["admin", "operator", "viewer"] },
  { to: "/empresas", label: "Empresas", roles: ["admin", "operator", "viewer"] },
  { to: "/certificados", label: "Certificados", roles: ["admin"] },
  { to: "/ncf-sequences", label: "Secuencias NCF", roles: ["admin"] },
  { to: "/validaciones", label: "Validaciones", roles: ["admin", "operator", "viewer"] },
  { to: "/reglas", label: "Reglas", roles: ["admin", "operator"] },
  { to: "/cors", label: "CORS", roles: ["admin"] },
  { to: "/usuarios", label: "Usuarios", roles: ["admin"] },
  { to: "/auditoria", label: "Auditoría", roles: ["admin", "operator"] },
  { to: "/configuracion", label: "Configuración", roles: ["admin"] },
  { to: "/health", label: "Salud", roles: ["admin", "operator", "viewer"] },
  { to: "/guia", label: "Guía de envío", roles: ["admin", "operator", "viewer"] },
];

export function Layout({ children }: { children: ReactNode }) {
  const { logout, role } = useAuth();
  const loc = useLocation();
  const nav = allNav.filter((n) => !role || n.roles.includes(role));
  return (
    <div className="layout">
      <aside className="sidebar">
        <div style={{ display: "flex", alignItems: "center", gap: "var(--space-2)", marginBottom: "var(--space-6)" }}>
          <div
            style={{
              width: 36,
              height: 36,
              borderRadius: "var(--radius-md)",
              background: "linear-gradient(135deg, #818cf8, #6366f1)",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              fontWeight: 700,
              color: "#fff",
              fontSize: 18,
              boxShadow: "0 4px 12px rgba(99, 102, 241, 0.4)",
            }}
          >
            e
          </div>
          <div>
            <div style={{ fontWeight: 700, fontSize: 16, color: "#fff" }}>e-CF Admin</div>
            <div style={{ fontSize: 11, color: "#94a3b8" }}>Simulador DGII RD</div>
          </div>
        </div>
        {nav.map((n) => (
          <Link
            key={n.to}
            to={n.to}
            className={loc.pathname === n.to ? "active" : ""}
          >
            {n.label}
          </Link>
        ))}
        <div style={{ marginTop: "var(--space-4)", padding: "var(--space-2) var(--space-3)", fontSize: 12, color: "#94a3b8" }}>
          Rol: <strong style={{ color: "#fff" }}>{role ?? "—"}</strong>
        </div>
        <button onClick={logout} style={{ marginTop: "var(--space-2)", width: "100%" }}>
          Salir
        </button>
      </aside>
      <div className="main">
        <header className="header">
          <strong>Simulador e-CF (DGII RD)</strong>
          <span style={{ color: "var(--color-muted)", fontSize: 12 }}>
            Entorno de simulación — sin validez fiscal
          </span>
        </header>
        <main className="content">{children}</main>
      </div>
    </div>
  );
}