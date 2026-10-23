import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { reglasApi } from "../lib/api";

export function Reglas() {
  const [active, setActive] = useState<string>("");
  const { data, isLoading, error } = useQuery({
    queryKey: ["reglas", active],
    queryFn: () => reglasApi.list(active === "" ? undefined : active === "true"),
  });

  return (
    <div>
      <h1 style={{ marginBottom: "var(--space-5)" }}>Reglas de simulación</h1>

      <div className="card" style={{ marginBottom: "var(--space-4)", display: "flex", gap: "var(--space-3)" }}>
        <select value={active} onChange={(e) => setActive(e.target.value)} style={{ width: 180 }}>
          <option value="">Todas</option>
          <option value="true">Activas</option>
          <option value="false">Inactivas</option>
        </select>
      </div>

      {isLoading && <div className="skeleton" style={{ height: 200 }} />}
      {error && <p style={{ color: "var(--color-danger)" }}>Error al cargar reglas</p>}

      {data && (
        <table>
          <thead>
            <tr>
              <th>Nombre</th>
              <th>Tipo</th>
              <th>Activa</th>
              <th>Valor</th>
              <th>Descripción</th>
              <th>Actualizado</th>
            </tr>
          </thead>
          <tbody>
            {data.data.map((r) => (
              <tr key={r.id}>
                <td>{r.name}</td>
                <td><span className="badge info">{r.ruleType}</span></td>
                <td>
                  <span className={`badge ${r.active ? "success" : "danger"}`}>
                    {r.active ? "Sí" : "No"}
                  </span>
                </td>
                <td>{r.value ?? "—"}</td>
                <td style={{ color: "var(--color-muted)", fontSize: 13 }}>{r.description ?? "—"}</td>
                <td>{new Date(r.updatedAt).toLocaleString()}</td>
              </tr>
            ))}
            {data.data.length === 0 && (
              <tr>
                <td colSpan={6} style={{ textAlign: "center", color: "var(--color-muted)" }}>
                  Sin reglas registradas
                </td>
              </tr>
            )}
          </tbody>
        </table>
      )}
    </div>
  );
}