import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { DataTable } from "../components/DataTable";

import { ecfApi } from "../lib/api";


export function EcfList() {
  const [estado, setEstado] = useState("");
  const [rnc, setRnc] = useState("");
  const [page, setPage] = useState(1);

  const { data, isLoading, error } = useQuery({
    queryKey: ["ecf", estado, rnc, page],
    queryFn: () => ecfApi.list({ page, per_page: 20, estado: estado || undefined, rnc: rnc || undefined }),
  });

  const columns = [
    {
      title: "TrackId",
      data: "trackId",
      render: (d: string) => `<a href="/ecf/${d}" class="dt-link">${d.slice(0, 8)}…</a>`,
    },
    {
      title: "Estado",
      data: "estado",
      render: (d: string) => {
        const cls = d === "Aceptado" ? "success" : d === "Rechazado" ? "danger" : d === "Aceptado Condicional" ? "warning" : "info";
        return `<span class="badge ${cls}">${d}</span>`;
      },
    },
    { title: "RNC Emisor", data: "rncEmisor" },
    { title: "e-NCF", data: "eNCF" },
    { title: "Tipo", data: "tipoComprobante", defaultContent: "—" },
    {
      title: "Fecha recepción",
      data: "fechaRecepcion",
      render: (d: string) => new Date(d).toLocaleString(),
    },
  ];

  return (
    <div>
      <h1 style={{ marginBottom: "var(--space-5)" }}>e-CF</h1>

      <div className="card" style={{ marginBottom: "var(--space-4)", display: "flex", gap: "var(--space-3)", flexWrap: "wrap" }}>
        <select value={estado} onChange={(e) => { setEstado(e.target.value); setPage(1); }} style={{ width: 180 }}>
          <option value="">Todos los estados</option>
          <option value="Aceptado">Aceptado</option>
          <option value="Aceptado Condicional">Aceptado Condicional</option>
          <option value="Rechazado">Rechazado</option>
          <option value="En Proceso">En Proceso</option>
        </select>
        <input
          placeholder="Filtrar por RNC"
          value={rnc}
          onChange={(e) => { setRnc(e.target.value); setPage(1); }}
          style={{ width: 200 }}
        />
      </div>

      {isLoading && <div className="skeleton" style={{ height: 200 }} />}
      {error && <p style={{ color: "var(--color-danger)" }}>Error al cargar e-CF</p>}

      {data && (
        <DataTable
          data={data.data}
          columns={columns}
          pageLength={10} emptyTable="Sin resultados"
        />
      )}
    </div>
  );
}