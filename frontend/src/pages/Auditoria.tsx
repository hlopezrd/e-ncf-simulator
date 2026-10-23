import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { DataTable } from "../components/DataTable";
import { auditoriaApi } from "../lib/api";


export function Auditoria() {
  const [actor, setActor] = useState("");
  const [action, setAction] = useState("");
  const { data, isLoading, error } = useQuery({
    queryKey: ["auditoria", actor, action],
    queryFn: () => auditoriaApi.list(actor || undefined, action || undefined),
  });

  const columns = [
    { title: "Actor", data: "actor" },
    { title: "Acción", data: "action", render: (d: string) => `<span class="badge info">${d}</span>` },
    { title: "Objetivo", data: "target", defaultContent: "—" },
    { title: "Detalles", data: "details", defaultContent: "—", render: (d: string) => d ? (d.length > 60 ? d.slice(0, 60) + "…" : d) : "—" },
    { title: "Fecha", data: "createdAt", render: (d: string) => new Date(d).toLocaleString() },
  ];

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
        <DataTable
          data={data.data}
          columns={columns}
          pageLength={10} emptyTable="Sin registros de auditoría"
        />
      )}
    </div>
  );
}