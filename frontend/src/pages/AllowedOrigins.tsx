import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { allowedOriginsApi } from "../lib/api";
import Swal from "sweetalert2";

export function AllowedOrigins() {
  const qc = useQueryClient();
  const { data, isLoading, error } = useQuery({
    queryKey: ["allowed-origins"],
    queryFn: allowedOriginsApi.list,
  });
  const [origin, setOrigin] = useState("");

  const createMut = useMutation({
    mutationFn: () => allowedOriginsApi.create(origin),
    onSuccess: () => { setOrigin(""); qc.invalidateQueries({ queryKey: ["allowed-origins"] }); },
  });

  const deleteMut = useMutation({
    mutationFn: (id: number) => allowedOriginsApi.remove(id),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["allowed-origins"] }),
  });

  return (
    <div>
      <h1 style={{ marginBottom: "var(--space-5)" }}>Orígenes CORS permitidos</h1>

      <div className="card" style={{ marginBottom: "var(--space-4)", display: "flex", gap: "var(--space-2)" }}>
        <input placeholder="https://example.com" value={origin} onChange={(e) => setOrigin(e.target.value)} />
        <button className="primary" onClick={() => createMut.mutate()} disabled={!origin}>
          Agregar
        </button>
      </div>

      {isLoading && <div className="skeleton" style={{ height: 200 }} />}
      {error && <p style={{ color: "var(--color-danger)" }}>Error al cargar</p>}

      {data && (
        <table>
          <thead>
            <tr>
              <th>Origen</th>
              <th>Creado</th>
              <th>Acciones</th>
            </tr>
          </thead>
          <tbody>
            {data.data.map((o) => (
              <tr key={o.id}>
                <td>{o.origin}</td>
                <td>{new Date(o.createdAt).toLocaleString()}</td>
                <td>
                  <button onClick={async () => {
                    const r = await Swal.fire({ title: "Eliminar origen", text: o.origin, icon: "warning", showCancelButton: true, confirmButtonText: "Eliminar", cancelButtonText: "Cancelar", confirmButtonColor: "#dc2626" });
                    if (r.isConfirmed) deleteMut.mutate(o.id);
                  }}>Eliminar</button>
                </td>
              </tr>
            ))}
            {data.data.length === 0 && (
              <tr>
                <td colSpan={3} style={{ textAlign: "center", color: "var(--color-muted)" }}>
                  Sin orígenes registrados
                </td>
              </tr>
            )}
          </tbody>
        </table>
      )}
    </div>
  );
}