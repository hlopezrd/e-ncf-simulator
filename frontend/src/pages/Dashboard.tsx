import { useQuery } from "@tanstack/react-query";
import { healthApi } from "../lib/api";

export function Dashboard() {
  const { data, isLoading, error } = useQuery({
    queryKey: ["health"],
    queryFn: healthApi.check,
  });

  const metrics = [
    { label: "Total e-CF", value: "—", color: "primary" },
    { label: "Aceptados", value: "—", color: "success" },
    { label: "Rechazados", value: "—", color: "danger" },
    { label: "Condicionales", value: "—", color: "warning" },
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
          <div key={m.label} className="card elevated">
            <div style={{ color: "var(--color-muted)", fontSize: 13, marginBottom: 4 }}>
              {m.label}
            </div>
            <div style={{ fontSize: 28, fontWeight: 700, color: `var(--color-${m.color})` }}>
              {m.value}
            </div>
          </div>
        ))}
      </div>

      <div className="card">
        <h3>Estado del sistema</h3>
        {isLoading && <div className="skeleton" style={{ height: 20, width: 200 }} />}
        {error && <p style={{ color: "var(--color-danger)" }}>Error al consultar salud</p>}
        {data && (
          <p style={{ display: "flex", alignItems: "center", gap: "var(--space-2)" }}>
            <span className="badge success">{data.status}</span>
            <span style={{ color: "var(--color-muted)" }}>
              {data.service} — {data.timestamp}
            </span>
          </p>
        )}
      </div>
    </div>
  );
}