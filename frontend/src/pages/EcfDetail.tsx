import { useParams, Link } from "react-router-dom";
import { useQuery } from "@tanstack/react-query";
import { useAuth } from "../context/AuthContext";
import { ecfApi } from "../lib/api";

export function EcfDetail() {
  const trackId = useParams().trackId ?? "";
  const { token } = useAuth();
  const { data, isLoading, error } = useQuery({
    queryKey: ["ecf-detail", trackId],
    queryFn: () => ecfApi.detail(trackId, token as string),
    enabled: !!trackId && !!token,
  });

  if (isLoading) return <div className="skeleton" style={{ height: 200 }} />;
  if (error) return <p style={{ color: "var(--color-danger)" }}>Error al cargar detalle</p>;
  if (!data) return <p>No encontrado</p>;

  return (
    <div>
      <Link to="/ecf" style={{ fontSize: 13 }}>&larr; Volver</Link>
      <h1 style={{ marginTop: "var(--space-3)" }}>Detalle e-CF</h1>

      <div className="card" style={{ marginBottom: "var(--space-4)" }}>
        <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(220px, 1fr))", gap: "var(--space-3)" }}>
          <div><strong>TrackId</strong><br />{data.trackId}</div>
          <div><strong>Estado</strong><br /><span className={`badge ${data.estado === "Aceptado" ? "success" : data.estado === "Rechazado" ? "danger" : "warning"}`}>{data.estado}</span></div>
          <div><strong>RNC Emisor</strong><br />{data.rncEmisor}</div>
          <div><strong>e-NCF</strong><br />{data.eNCF}</div>
          <div><strong>Tipo</strong><br />{data.tipoComprobante ?? "—"}</div>
          <div><strong>Fecha emisión</strong><br />{data.fechaEmision ?? "—"}</div>
          <div><strong>Fecha recepción</strong><br />{new Date(data.fechaRecepcion).toLocaleString()}</div>
        </div>
      </div>

      {data.errores.length > 0 && (
        <div className="card" style={{ marginBottom: "var(--space-4)", borderColor: "var(--color-danger)" }}>
          <h3>Errores</h3>
          <pre style={{ whiteSpace: "pre-wrap", fontSize: 13 }}>{JSON.stringify(data.errores, null, 2)}</pre>
        </div>
      )}

      {data.advertencias.length > 0 && (
        <div className="card" style={{ marginBottom: "var(--space-4)", borderColor: "var(--color-warning)" }}>
          <h3>Advertencias</h3>
          <pre style={{ whiteSpace: "pre-wrap", fontSize: 13 }}>{JSON.stringify(data.advertencias, null, 2)}</pre>
        </div>
      )}

      <div className="card" style={{ marginBottom: "var(--space-4)" }}>
        <h3>XML</h3>
        <pre
          style={{
            whiteSpace: "pre-wrap",
            fontSize: 12,
            background: "var(--color-surface-alt)",
            padding: "var(--space-3)",
            borderRadius: "var(--radius-sm)",
            maxHeight: 400,
            overflow: "auto",
          }}
        >
          {data.xml}
        </pre>
      </div>
    </div>
  );
}