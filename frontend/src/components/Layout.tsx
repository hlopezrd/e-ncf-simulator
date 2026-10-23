import type { ReactNode } from "react";
import { Link, useLocation } from "react-router-dom";
import { useAuth } from "../context/AuthContext";

const nav = [
  { to: "/", label: "Dashboard" },
  { to: "/ecf", label: "e-CF" },
  { to: "/trackids", label: "TrackIds" },
  { to: "/empresas", label: "Empresas" },
  { to: "/certificados", label: "Certificados" },
  { to: "/validaciones", label: "Validaciones" },
  { to: "/reglas", label: "Reglas" },
  { to: "/usuarios", label: "Usuarios" },
  { to: "/auditoria", label: "Auditoría" },
  { to: "/configuracion", label: "Configuración" },
  { to: "/health", label: "Salud" },
];

export function Layout({ children }: { children: ReactNode }) {
  const { logout } = useAuth();
  const loc = useLocation();
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
        <button onClick={logout} style={{ marginTop: "var(--space-4)", width: "100%" }}>
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