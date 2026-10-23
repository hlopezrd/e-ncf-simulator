import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { certificadosApi } from "../lib/api";

export function Certificados() {
  const qc = useQueryClient();
  const { data, isLoading, error } = useQuery({
    queryKey: ["certificados"],
    queryFn: certificadosApi.list,
  });

  const [rnc, setRnc] = useState("");
  const [aliasName, setAliasName] = useState("");
  const [subject, setSubject] = useState("");
  const [issuer, setIssuer] = useState("");
  const [serial, setSerial] = useState("");
  const [thumbprint, setThumbprint] = useState("");

  const createMut = useMutation({
    mutationFn: () =>
      certificadosApi.create({
        rnc,
        alias_name: aliasName || undefined,
        subject: subject || undefined,
        issuer: issuer || undefined,
        serial: serial || undefined,
        thumbprint: thumbprint || undefined,
      }),
    onSuccess: () => {
      setRnc(""); setAliasName(""); setSubject(""); setIssuer(""); setSerial(""); setThumbprint("");
      qc.invalidateQueries({ queryKey: ["certificados"] });
    },
  });

  const deleteMut = useMutation({
    mutationFn: (id: number) => certificadosApi.remove(id),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["certificados"] }),
  });

  return (
    <div>
      <h1 style={{ marginBottom: "var(--space-5)" }}>Certificados</h1>

      <div className="card" style={{ marginBottom: "var(--space-4)" }}>
        <h3>Registrar certificado</h3>
        <div style={{ display: "flex", gap: "var(--space-2)", flexWrap: "wrap", alignItems: "center" }}>
          <input placeholder="RNC" value={rnc} onChange={(e) => setRnc(e.target.value)} style={{ width: 140 }} />
          <input placeholder="Alias" value={aliasName} onChange={(e) => setAliasName(e.target.value)} style={{ width: 140 }} />
          <input placeholder="Subject" value={subject} onChange={(e) => setSubject(e.target.value)} style={{ width: 160 }} />
          <input placeholder="Issuer" value={issuer} onChange={(e) => setIssuer(e.target.value)} style={{ width: 160 }} />
          <input placeholder="Serial" value={serial} onChange={(e) => setSerial(e.target.value)} style={{ width: 140 }} />
          <input placeholder="Thumbprint" value={thumbprint} onChange={(e) => setThumbprint(e.target.value)} style={{ width: 160 }} />
          <button className="primary" onClick={() => createMut.mutate()} disabled={!rnc}>
            Registrar
          </button>
        </div>
      </div>

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
              <th>Acciones</th>
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
                <td>
                  <button onClick={() => deleteMut.mutate(c.id)}>Eliminar</button>
                </td>
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