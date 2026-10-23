import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { validacionesApi } from "../lib/api";

export function Validaciones() {
  const [sev, setSev] = useState("");
  const { data, isLoading, error } = useQuery({
    queryKey: ["validaciones", sev],
    queryFn: () => validacionesApi.list(sev || undefined),
  });

  return (
    <div>
      <h1 style={{ marginBottom: "var(--space-5)" }}>Historial de validaciones</h1>

      <div className="card" style={{ marginBottom: "var(--space-4)", display: "flex", gap: "var(--space-3)" }}>
        <select value={sev} onChange={(e) => setSev(e.target.value)} style={{ width: 180 }}>
          <option value="">Todas</option>
          <option value="ERROR">ERROR</option>
          <option value="WARNING">WARNING</option>
        </select>
      </div>

      {isLoading && <div className="skeleton" style={{ height: 200 }} />}
      {error && <p style={{ color: "var(--color-danger)" }}>Error al cargar validaciones</p>}

      {data && (
        <table>
          <thead>
            <tr>
              <th>Código</th>
              <th>Severidad</th>
              <th>Campo</th>
              <th>Mensaje</th>
              <th>TrackId</th>
              <th>RNC</th>
              <th>e-NCF</th>
              <th>Fecha</th>
            </tr>
          </thead>
          <tbody>
            {data.data.map((v) => (
              <tr key={v.id}>
                <td><span className="badge info">{v.codigo}</span></td>
                <td>
                  <span className={`badge ${v.severidad === "ERROR" ? "danger" : "warning"}`}>
                    {v.severidad}
                  </span>
                </td>
                <td>{v.campo}</td>
                <td>{v.mensaje}</td>
                <td style={{ fontFamily: "monospace", fontSize: 11 }}>{v.trackId.slice(0, 8)}…</td>
                <td>{v.rncEmisor}</td>
                <td>{v.eNCF}</td>
                <td>{new Date(v.createdAt).toLocaleString()}</td>
              </tr>
            ))}
            {data.data.length === 0 && (
              <tr>
                <td colSpan={8} style={{ textAlign: "center", color: "var(--color-muted)" }}>
                  Sin validaciones registradas
                </td>
              </tr>
            )}
          </tbody>
        </table>
      )}
    </div>
  );
}