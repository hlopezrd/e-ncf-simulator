import { useQuery } from "@tanstack/react-query";
import { empresasApi } from "../lib/api";

export function Empresas() {
  const { data, isLoading, error } = useQuery({
    queryKey: ["empresas"],
    queryFn: empresasApi.list,
  });

  return (
    <div>
      <h1 style={{ marginBottom: "var(--space-5)" }}>Empresas y RNC</h1>
      {isLoading && <div className="skeleton" style={{ height: 200 }} />}
      {error && <p style={{ color: "var(--color-danger)" }}>Error al cargar empresas</p>}
      {data && (
        <table>
          <thead>
            <tr>
              <th>RNC Emisor</th>
              <th>Total e-CF</th>
              <th>Última recepción</th>
            </tr>
          </thead>
          <tbody>
            {data.data.map((e) => (
              <tr key={e.rnc}>
                <td>{e.rnc}</td>
                <td>{e.totalEcf}</td>
                <td>{e.ultimaRecepcion ?? "—"}</td>
              </tr>
            ))}
            {data.data.length === 0 && (
              <tr>
                <td colSpan={3} style={{ textAlign: "center", color: "var(--color-muted)" }}>
                  Sin datos
                </td>
              </tr>
            )}
          </tbody>
        </table>
      )}
    </div>
  );
}