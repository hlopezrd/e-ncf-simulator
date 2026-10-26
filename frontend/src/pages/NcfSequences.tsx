import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { ncfSequencesApi } from "../lib/api";
import Swal from "sweetalert2";

export function NcfSequences() {
  const qc = useQueryClient();
  const { data, isLoading, error } = useQuery({
    queryKey: ["ncf_sequences"],
    queryFn: ncfSequencesApi.list,
  });

  const [rnc, setRnc] = useState("");
  const [tipo, setTipo] = useState("31");
  const [desde, setDesde] = useState("");
  const [hasta, setHasta] = useState("");
  const [fecha, setFecha] = useState("");
  const [activa, setActiva] = useState(true);

  const [editingId, setEditingId] = useState<number | null>(null);
  const [editRnc, setEditRnc] = useState("");
  const [editTipo, setEditTipo] = useState("");
  const [editDesde, setEditDesde] = useState("");
  const [editHasta, setEditHasta] = useState("");
  const [editFecha, setEditFecha] = useState("");
  const [editActiva, setEditActiva] = useState(true);

  const createMut = useMutation({
    mutationFn: () =>
      ncfSequencesApi.create({
        rnc,
        tipo: Number(tipo),
        desde: Number(desde),
        hasta: Number(hasta),
        fecha_vencimiento: fecha,
        activa,
      }),
    onSuccess: () => {
      setRnc(""); setTipo("31"); setDesde(""); setHasta(""); setFecha(""); setActiva(true);
      qc.invalidateQueries({ queryKey: ["ncf_sequences"] });
    },
  });

  const deleteMut = useMutation({
    mutationFn: (id: number) => ncfSequencesApi.remove(id),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["ncf_sequences"] }),
  });

  const saveEdit = useMutation({
    mutationFn: () =>
      ncfSequencesApi.update(editingId!, {
        rnc: editRnc,
        tipo: Number(editTipo),
        desde: Number(editDesde),
        hasta: Number(editHasta),
        fecha_vencimiento: editFecha,
        activa: editActiva,
      }),
    onSuccess: () => { setEditingId(null); qc.invalidateQueries({ queryKey: ["ncf_sequences"] }); },
  });

  const startEdit = (s: { id: number; rnc: string; tipo: number; desde: number; hasta: number; fechaVencimiento: string | null; activa: boolean }) => {
    setEditingId(s.id);
    setEditRnc(s.rnc);
    setEditTipo(String(s.tipo));
    setEditDesde(String(s.desde));
    setEditHasta(String(s.hasta));
    setEditFecha(s.fechaVencimiento ? s.fechaVencimiento.slice(0, 10) : "");
    setEditActiva(s.activa);
  };

  const handleDelete = (id: number) => {
    Swal.fire({ title: "Eliminar rango", text: "¿Confirmar?", icon: "warning", showCancelButton: true }).then((r) => {
      if (r.isConfirmed) deleteMut.mutate(id);
    });
  };

  return (
    <div>
      <h1 style={{ marginBottom: "var(--space-5)" }}>Secuencias de e-NCF</h1>

      <div className="card" style={{ marginBottom: "var(--space-4)" }}>
        <h3>Registrar rango</h3>
        <p style={{ color: "var(--color-muted)", fontSize: 13, marginBottom: "var(--space-3)" }}>
          Registra un rango autorizado por la DGII para un RNC y un tipo de comprobante.
        </p>
        <div style={{ display: "flex", gap: "var(--space-2)", flexWrap: "wrap", alignItems: "center" }}>
          <input placeholder="RNC" value={rnc} onChange={(e) => setRnc(e.target.value)} style={{ width: 140 }} />
          <input placeholder="Tipo (31)" value={tipo} onChange={(e) => setTipo(e.target.value)} style={{ width: 90 }} />
          <input placeholder="Desde" value={desde} onChange={(e) => setDesde(e.target.value)} style={{ width: 90 }} />
          <input placeholder="Hasta" value={hasta} onChange={(e) => setHasta(e.target.value)} style={{ width: 90 }} />
          <input type="date" value={fecha} onChange={(e) => setFecha(e.target.value)} />
          <label style={{ display: "flex", alignItems: "center", gap: 4 }}>
            <input type="checkbox" checked={activa} onChange={(e) => setActiva(e.target.checked)} />
            Activa
          </label>
          <button className="primary" onClick={() => createMut.mutate()} disabled={!rnc || !desde || !hasta || !fecha}>
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
      {error && <p style={{ color: "var(--color-danger)" }}>Error al cargar secuencias</p>}

      {data && (
        <table>
          <thead>
            <tr>
              <th>RNC</th>
              <th>Tipo</th>
              <th>Desde</th>
              <th>Hasta</th>
              <th>Consumidos</th>
              <th>Disponibles</th>
              <th>Anulados</th>
              <th>Vencimiento</th>
              <th>Estado</th>
              <th>Acciones</th>
            </tr>
          </thead>
          <tbody>
            {data.data.map((s) => (
              <tr key={s.id}>
                {editingId === s.id ? (
                  <>
                    <td><input value={editRnc} onChange={(e) => setEditRnc(e.target.value)} style={{ width: 120 }} /></td>
                    <td><input value={editTipo} onChange={(e) => setEditTipo(e.target.value)} style={{ width: 70 }} /></td>
                    <td><input value={editDesde} onChange={(e) => setEditDesde(e.target.value)} style={{ width: 80 }} /></td>
                    <td><input value={editHasta} onChange={(e) => setEditHasta(e.target.value)} style={{ width: 80 }} /></td>
                    <td><input type="date" value={editFecha} onChange={(e) => setEditFecha(e.target.value)} /></td>
                    <td>
                      <label style={{ display: "flex", alignItems: "center", gap: 4 }}>
                        <input type="checkbox" checked={editActiva} onChange={(e) => setEditActiva(e.target.checked)} />
                        Activa
                      </label>
                    </td>
                    <td style={{ display: "flex", gap: "var(--space-2)" }}>
                      <button className="primary" onClick={() => saveEdit.mutate()}>Guardar</button>
                      <button onClick={() => setEditingId(null)}>Cancelar</button>
                    </td>
                  </>
                ) : (
                  <>
                    <td>{s.rnc}</td>
                    <td>{s.tipo}</td>
                    <td>{s.desde}</td>
                    <td>{s.hasta}</td>
                    <td>{s.consumidos}</td>
                    <td>{s.disponibles}</td>
                    <td>{s.anulados}{s.rangosAnulados.length ? ` (${s.rangosAnulados.map((r) => `${r.desde}-${r.hasta}`).join(", ")})` : ""}</td>
                    <td>{s.fechaVencimiento ? new Date(s.fechaVencimiento).toLocaleDateString() : "—"}</td>
                    <td>
                      <span className={`badge ${s.vigente ? "success" : (s.anulada ? "danger" : "secondary")}`}>
                        {s.estado}
                      </span>
                    </td>
                    <td style={{ display: "flex", gap: "var(--space-2)" }}>
                      <button onClick={() => startEdit(s)}>Editar</button>
                      <button onClick={() => handleDelete(s.id)}>Eliminar</button>
                    </td>
                  </>
                )}
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  );
}