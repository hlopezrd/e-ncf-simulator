import { useQuery } from "@tanstack/react-query";
import { certificadosApi } from "../lib/api";

export function Certificados() {
  const { data, isLoading, error } = useQuery({
    queryKey: ["certificados"],
    queryFn: certificadosApi.list,
  });

  return (
    <div>
      <h1 style={{ marginBottom: "var(--space-5)" }}>Certificados</h1>
      {isLoading && <div className="skeleton" style={{ height: 200 }} />}
      {error && <p style={{ color: "var(--color-danger)" }}>Error al cargar certificados</p>}
      {data && (
        <table>
          <thead>
            <tr>
              <th>RNC</th>
              <th>Alias</th>
              <th>Subject</th>
              <th>Issuer</th>
              <th>Válido desde</th>
              <th>Válido hasta</th>
              <th>Thumbprint</th>
            </tr>
          </thead>
          <tbody>
            {data.data.map((c) => (
              <tr key={c.id}>
                <td>{c.rnc}</td>
                <td>{c.alias ?? "—"}</td>
                <td>{c.subject ?? "—"}</td>
                <td>{c.issuer ?? "—"}</td>
                <td>{c.notBefore ? new Date(c.notBefore).toLocaleDateString() : "—"}</td>
                <td>{c.notAfter ? new Date(c.notAfter).toLocaleDateString() : "—"}</td>
                <td style={{ fontFamily: "monospace", fontSize: 11 }}>{c.thumbprint ?? "—"}</td>
              </tr>
            ))}
            {data.data.length === 0 && (
              <tr>
                <td colSpan={7} style={{ textAlign: "center", color: "var(--color-muted)" }}>
                  Sin certificados registrados
                </td>
              </tr>
            )}
          </tbody>
        </table>
      )}
    </div>
  );
}