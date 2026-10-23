import type { ReactNode } from "react";
import { Link, useLocation } from "react-router-dom";
import { useAuth } from "../context/AuthContext";

const nav = [
  { to: "/", label: "Dashboard" },
  { to: "/ecf", label: "e-CF" },
  { to: "/trackids", label: "TrackIds" },
  { to: "/empresas", label: "Empresas" },
  { to: "/certificados", label: "Certificados" },
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
        <h2 style={{ marginTop: 0 }}>e-CF Admin</h2>
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