import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import DataTable from "datatables.net-react";
import DT from "datatables.net-dt";
import { validacionesApi } from "../lib/api";

DataTable.use(DT);

export function Validaciones() {
  const [sev, setSev] = useState("");
  const { data, isLoading, error } = useQuery({
    queryKey: ["validaciones", sev],
    queryFn: () => validacionesApi.list(sev || undefined),
  });

  const columns = [
    { title: "Código", data: "codigo", render: (d: string) => `<span class="badge info">${d}</span>` },
    {
      title: "Severidad",
      data: "severidad",
      render: (d: string) => `<span class="badge ${d === "ERROR" ? "danger" : "warning"}">${d}</span>`,
    },
    { title: "Campo", data: "campo" },
    { title: "Mensaje", data: "mensaje" },
    { title: "TrackId", data: "trackId", render: (d: string) => d.slice(0, 8) + "…" },
    { title: "RNC", data: "rncEmisor" },
    { title: "e-NCF", data: "eNCF" },
    { title: "Fecha", data: "createdAt", render: (d: string) => new Date(d).toLocaleString() },
  ];

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
        <DataTable
          data={data.data}
          columns={columns}
          className="display"
          options={{ pageLength: 10, language: { emptyTable: "Sin validaciones registradas" } }}
        />
      )}
    </div>
  );
}