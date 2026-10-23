import { useQuery } from "@tanstack/react-query";
import { healthApi } from "../lib/api";

export function Dashboard() {
  const { data, isLoading, error } = useQuery({
    queryKey: ["health"],
    queryFn: healthApi.check,
  });

  return (
    <div>
      <h1>Dashboard</h1>
      <div className="card" style={{ marginBottom: "var(--space-4)" }}>
        <h3>Estado del sistema</h3>
        {isLoading && <div className="skeleton" style={{ height: 20, width: 200 }} />}
        {error && <p style={{ color: "var(--color-danger)" }}>Error al consultar salud</p>}
        {data && (
          <p>
            <span className="badge success">{data.status}</span>{" "}
            {data.service} — {data.timestamp}
          </p>
        )}
      </div>
      <div className="card">
        <h3>Métricas (pendiente)</h3>
        <p style={{ color: "var(--color-muted)" }}>
          Total e-CF, aceptados, rechazados y condicionales se mostrarán aquí cuando
          el backend exponga el endpoint de listado.
        </p>
      </div>
    </div>
  );
}