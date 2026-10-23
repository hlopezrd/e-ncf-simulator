import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { Link } from "react-router-dom";
import { ecfApi } from "../lib/api";

export function EcfList() {
  const [estado, setEstado] = useState("");
  const [rnc, setRnc] = useState("");
  const [page, setPage] = useState(1);

  const { data, isLoading, error } = useQuery({
    queryKey: ["ecf", estado, rnc, page],
    queryFn: () => ecfApi.list({ page, per_page: 20, estado: estado || undefined, rnc: rnc || undefined }),
  });

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
        <>
          <table>
            <thead>
              <tr>
                <th>TrackId</th>
                <th>Estado</th>
                <th>RNC Emisor</th>
                <th>e-NCF</th>
                <th>Tipo</th>
                <th>Fecha recepción</th>
              </tr>
            </thead>
            <tbody>
              {data.data.map((e) => (
                <tr key={e.trackId}>
                  <td>
                    <Link to={`/ecf/${e.trackId}`}>{e.trackId.slice(0, 8)}…</Link>
                  </td>
                  <td>
                    <span className={`badge ${e.estado === "Aceptado" ? "success" : e.estado === "Rechazado" ? "danger" : e.estado === "Aceptado Condicional" ? "warning" : "info"}`}>
                      {e.estado}
                    </span>
                  </td>
                  <td>{e.rncEmisor}</td>
                  <td>{e.eNCF}</td>
                  <td>{e.tipoComprobante ?? "—"}</td>
                  <td>{new Date(e.fechaRecepcion).toLocaleString()}</td>
                </tr>
              ))}
              {data.data.length === 0 && (
                <tr>
                  <td colSpan={6} style={{ textAlign: "center", color: "var(--color-muted)" }}>
                    Sin resultados
                  </td>
                </tr>
              )}
            </tbody>
          </table>

          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginTop: "var(--space-4)" }}>
            <span style={{ color: "var(--color-muted)", fontSize: 13 }}>
              Total: {data.meta.total} — Página {data.meta.page}
            </span>
            <div style={{ display: "flex", gap: "var(--space-2)" }}>
              <button onClick={() => setPage((p) => Math.max(1, p - 1))} disabled={page <= 1}>
                Anterior
              </button>
              <button
                onClick={() => setPage((p) => p + 1)}
                disabled={page * data.meta.per_page >= data.meta.total}
              >
                Siguiente
              </button>
            </div>
          </div>
        </>
      )}
    </div>
  );
}