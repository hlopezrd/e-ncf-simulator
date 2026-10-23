import { useState, useRef, useEffect } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import DataTable from "datatables.net-react";
import DT from "datatables.net-dt";
import { allowedOriginsApi } from "../lib/api";
import Swal from "sweetalert2";

DataTable.use(DT);

export function AllowedOrigins() {
  const qc = useQueryClient();
  const containerRef = useRef<HTMLDivElement>(null);
  const { data, isLoading, error } = useQuery({
    queryKey: ["allowed-origins"],
    queryFn: allowedOriginsApi.list,
  });
  const [origin, setOrigin] = useState("");

  const deleteMut = useMutation({
    mutationFn: (id: number) => allowedOriginsApi.remove(id),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["allowed-origins"] }),
  });

  const createMut = useMutation({
    mutationFn: () => allowedOriginsApi.create(origin),
    onSuccess: () => { setOrigin(""); qc.invalidateQueries({ queryKey: ["allowed-origins"] }); },
  });

  const columns = [
    { title: "Origen", data: "origin" },
    { title: "Creado", data: "createdAt", render: (d: string) => new Date(d).toLocaleString() },
    {
      title: "Acciones",
      data: "id",
      orderable: false,
      render: (id: number) => `<button class="dt-delete" data-id="${id}">Eliminar</button>`,
    },
  ];

  useEffect(() => {
    const el = containerRef.current;
    if (!el) return;
    const handler = async (e: MouseEvent) => {
      const target = e.target as HTMLElement;
      const btn = target.closest(".dt-delete") as HTMLElement | null;
      if (!btn) return;
      const id = Number(btn.dataset.id);
      const res = await Swal.fire({ title: "Eliminar origen", icon: "warning", showCancelButton: true, confirmButtonText: "Eliminar", cancelButtonText: "Cancelar", confirmButtonColor: "#dc2626" });
      if (res.isConfirmed) deleteMut.mutate(id);
    };
    el.addEventListener("click", handler);
    return () => el.removeEventListener("click", handler);
  }, [deleteMut]);

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
        <div ref={containerRef}>
          <DataTable
            data={data.data}
            columns={columns}
            className="display"
            options={{ pageLength: 10, language: { emptyTable: "Sin orígenes registrados" } }}
          />
        </div>
      )}
    </div>
  );
}