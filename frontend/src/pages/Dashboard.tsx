import { useQuery } from "@tanstack/react-query";
import { healthApi, ecfApi } from "../lib/api";

export function Dashboard() {
  const health = useQuery({ queryKey: ["health"], queryFn: healthApi.check });
  const ecf = useQuery({ queryKey: ["ecf"], queryFn: () => ecfApi.list({ per_page: 100 }) });

  const items = ecf.data?.data ?? [];
  const total = ecf.data?.meta.total ?? 0;
  const aceptados = items.filter((e) => e.estado === "Aceptado").length;
  const rechazados = items.filter((e) => e.estado === "Rechazado").length;
  const condicionales = items.filter((e) => e.estado === "Aceptado Condicional").length;

  const metrics = [
    { label: "Total e-CF", value: total, color: "primary", icon: "📄" },
    { label: "Aceptados", value: aceptados, color: "success", icon: "✅" },
    { label: "Rechazados", value: rechazados, color: "danger", icon: "❌" },
    { label: "Condicionales", value: condicionales, color: "warning", icon: "⚠️" },
  ];

  return (
    <div>
      <h1 style={{ marginBottom: "var(--space-5)" }}>Dashboard</h1>

      <div
        style={{
          display: "grid",
          gridTemplateColumns: "repeat(auto-fit, minmax(200px, 1fr))",
          gap: "var(--space-4)",
          marginBottom: "var(--space-6)",
        }}
      >
        {metrics.map((m) => (
          <div key={m.label} className="card elevated accent">
            <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: "var(--space-2)" }}>
              <span style={{ color: "var(--color-muted)", fontSize: 13, fontWeight: 500 }}>
                {m.label}
              </span>
              <span style={{ fontSize: 20 }}>{m.icon}</span>
            </div>
            <div style={{ fontSize: 32, fontWeight: 700, color: `var(--color-${m.color})` }}>
              {ecf.isLoading ? "…" : m.value}
            </div>
          </div>
        ))}
      </div>

      <div className="card">
        <h3>Estado del sistema</h3>
        {health.isLoading && <div className="skeleton" style={{ height: 20, width: 200 }} />}
        {health.error && <p style={{ color: "var(--color-danger)" }}>Error al consultar salud</p>}
        {health.data && (
          <p style={{ display: "flex", alignItems: "center", gap: "var(--space-2)" }}>
            <span className="badge success">{health.data.status}</span>
            <span style={{ color: "var(--color-muted)" }}>
              {health.data.service} — {health.data.timestamp}
            </span>
          </p>
        )}
      </div>
    </div>
  );
}