import { useState, useRef } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { certificadosApi } from "../lib/api";
import Swal from "sweetalert2";

export function Certificados() {
  const qc = useQueryClient();
  const { data, isLoading, error } = useQuery({
    queryKey: ["certificados"],
    queryFn: certificadosApi.list,
  });

  const [rnc, setRnc] = useState("");
  const [aliasName, setAliasName] = useState("");
  const [file, setFile] = useState<File | null>(null);
  const fileRef = useRef<HTMLInputElement>(null);

  const [editingId, setEditingId] = useState<number | null>(null);
  const [editAlias, setEditAlias] = useState("");

  const createMut = useMutation({
    mutationFn: () => {
      if (!file) throw new Error("Falta el archivo");
      return certificadosApi.create({ rnc, alias_name: aliasName || undefined, file });
    },
    onSuccess: () => {
      setRnc(""); setAliasName(""); setFile(null);
      if (fileRef.current) fileRef.current.value = "";
      qc.invalidateQueries({ queryKey: ["certificados"] });
    },
  });

  const deleteMut = useMutation({
    mutationFn: (id: number) => certificadosApi.remove(id),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["certificados"] }),
  });

  const saveEdit = useMutation({
    mutationFn: () => certificadosApi.update(editingId!, { alias_name: editAlias }),
    onSuccess: () => { setEditingId(null); qc.invalidateQueries({ queryKey: ["certificados"] }); },
  });

  const startEdit = (c: { id: number; alias: string | null }) => {
    setEditingId(c.id);
    setEditAlias(c.alias ?? "");
  };

  return (
    <div>
      <h1 style={{ marginBottom: "var(--space-5)" }}>Certificados</h1>

      <div className="card" style={{ marginBottom: "var(--space-4)" }}>
        <h3>Registrar certificado</h3>
        <p style={{ color: "var(--color-muted)", fontSize: 13, marginBottom: "var(--space-3)" }}>
          Sube el archivo del certificado (.crt / .pem). Los metadatos se extraen automáticamente.
        </p>
        <div style={{ display: "flex", gap: "var(--space-2)", flexWrap: "wrap", alignItems: "center" }}>
          <input placeholder="RNC" value={rnc} onChange={(e) => setRnc(e.target.value)} style={{ width: 140 }} />
          <input placeholder="Alias" value={aliasName} onChange={(e) => setAliasName(e.target.value)} style={{ width: 140 }} />
          <input
            ref={fileRef}
            type="file"
            accept=".crt,.pem,.cer"
            onChange={(e) => setFile(e.target.files?.[0] ?? null)}
          />
          <button className="primary" onClick={() => createMut.mutate()} disabled={!rnc || !file}>
            Registrar
          </button>
        </div>
        {createMut.isError && (
          <p style={{ color: "var(--color-danger)", marginTop: "var(--space-2)" }}>
            {(createMut.error as Error)?.message ?? "Error al registrar"}
          </p>
        )}
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
              <th>Estado</th>
              <th>Acciones</th>
            </tr>
          </thead>
          <tbody>
            {data.data.map((c) => (
              <tr key={c.id}>
                {editingId === c.id ? (
                  <>
                    <td>{c.rnc}</td>
                    <td><input value={editAlias} onChange={(e) => setEditAlias(e.target.value)} /></td>
                    <td>{c.subject ?? "—"}</td>
                    <td>{c.issuer ?? "—"}</td>
                    <td>{c.notBefore ? new Date(c.notBefore).toLocaleDateString() : "—"}</td>
                    <td>{c.notAfter ? new Date(c.notAfter).toLocaleDateString() : "—"}</td>
                    <td><span className={`badge ${c.active ? "success" : "secondary"}`}>{c.active ? "Activo" : "Inactivo"}</span></td>
                    <td style={{ display: "flex", gap: "var(--space-2)" }}>
                      <button className="primary" onClick={() => saveEdit.mutate()}>Guardar</button>
                      <button onClick={() => setEditingId(null)}>Cancelar</button>
                    </td>
                  </>
                ) : (
                  <>
                    <td>{c.rnc}</td>
                    <td>{c.alias ?? "—"}</td>
                    <td style={{ fontSize: 12 }}>{c.subject ?? "—"}</td>
                    <td style={{ fontSize: 12 }}>{c.issuer ?? "—"}</td>
                    <td>{c.notBefore ? new Date(c.notBefore).toLocaleDateString() : "—"}</td>
                    <td>{c.notAfter ? new Date(c.notAfter).toLocaleDateString() : "—"}</td>
                    <td>
                      <span className={`badge ${c.active ? (new Date(c.notAfter ?? "") >= new Date() ? "success" : "danger") : "secondary"}`}>
                        {c.active ? (c.notAfter && new Date(c.notAfter) >= new Date() ? "Vigente" : "Vencido") : "Inactivo"}
                      </span>
                    </td>
                    <td style={{ display: "flex", gap: "var(--space-2)" }}>
                      <button onClick={() => startEdit(c)}>Editar</button>
                      <button onClick={async () => {
                        const res = await Swal.fire({ title: "Eliminar certificado", text: c.rnc, icon: "warning", showCancelButton: true, confirmButtonText: "Eliminar", cancelButtonText: "Cancelar", confirmButtonColor: "#dc2626" });
                        if (res.isConfirmed) deleteMut.mutate(c.id);
                      }}>Eliminar</button>
                    </td>
                  </>
                )}
              </tr>
            ))}
            {data.data.length === 0 && (
              <tr>
                <td colSpan={8} style={{ textAlign: "center", color: "var(--color-muted)" }}>
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