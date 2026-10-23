import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { auditoriaApi } from "../lib/api";

export function Auditoria() {
  const [actor, setActor] = useState("");
  const [action, setAction] = useState("");
  const { data, isLoading, error } = useQuery({
    queryKey: ["auditoria", actor, action],
    queryFn: () => auditoriaApi.list(actor || undefined, action || undefined),
  });

  return (
    <div>
      <h1 style={{ marginBottom: "var(--space-5)" }}>Auditoría</h1>

      <div className="card" style={{ marginBottom: "var(--space-4)", display: "flex", gap: "var(--space-3)", flexWrap: "wrap" }}>
        <input placeholder="Actor" value={actor} onChange={(e) => setActor(e.target.value)} style={{ width: 180 }} />
        <input placeholder="Acción" value={action} onChange={(e) => setAction(e.target.value)} style={{ width: 180 }} />
      </div>

      {isLoading && <div className="skeleton" style={{ height: 200 }} />}
      {error && <p style={{ color: "var(--color-danger)" }}>Error al cargar auditoría</p>}

      {data && (
        <table>
          <thead>
            <tr>
              <th>Actor</th>
              <th>Acción</th>
              <th>Objetivo</th>
              <th>Detalles</th>
              <th>Fecha</th>
            </tr>
          </thead>
          <tbody>
            {data.data.map((a) => (
              <tr key={a.id}>
                <td>{a.actor}</td>
                <td><span className="badge info">{a.action}</span></td>
                <td>{a.target ?? "—"}</td>
                <td style={{ fontSize: 12, color: "var(--color-muted)" }}>{a.details ?? "—"}</td>
                <td>{new Date(a.createdAt).toLocaleString()}</td>
              </tr>
            ))}
            {data.data.length === 0 && (
              <tr>
                <td colSpan={5} style={{ textAlign: "center", color: "var(--color-muted)" }}>
                  Sin registros de auditoría
                </td>
              </tr>
            )}
          </tbody>
        </table>
      )}
    </div>
  );
}