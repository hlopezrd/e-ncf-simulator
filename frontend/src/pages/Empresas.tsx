import { useState, type FormEvent } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { DataTable } from "../components/DataTable";
import { empresasApi, type EmpresaItem } from "../lib/api";
import Swal from "sweetalert2";

type EmpresaEdicion = {
  razon_social: string;
  nombre_comercial: string;
  email: string;
  telefono: string;
  activa: boolean;
};

export function Empresas() {
  const qc = useQueryClient();
  const { data, isLoading, error } = useQuery({
    queryKey: ["empresas"],
    queryFn: empresasApi.list,
  });

  const [rnc, setRnc] = useState("");
  const [razon, setRazon] = useState("");
  const [editing, setEditing] = useState<EmpresaItem | null>(null);
  const [form, setForm] = useState<EmpresaEdicion>({
    razon_social: "",
    nombre_comercial: "",
    email: "",
    telefono: "",
    activa: true,
  });

  const invalidate = () => qc.invalidateQueries({ queryKey: ["empresas"] });

  const createMut = useMutation({
    mutationFn: () => empresasApi.create({ rnc, razon_social: razon }),
    onSuccess: () => { setRnc(""); setRazon(""); invalidate(); },
    onError: (e: unknown) => Swal.fire("Error", String(e), "error"),
  });

  const updateMut = useMutation({
    mutationFn: ({ id, payload }: { id: number; payload: EmpresaEdicion }) => empresasApi.update(id, payload),
    onSuccess: () => {
      setEditing(null);
      invalidate();
      Swal.fire("OK", "Empresa actualizada", "success");
    },
    onError: (e: unknown) => Swal.fire("Error", String(e), "error"),
  });

  const deleteMut = useMutation({
    mutationFn: (id: number) => empresasApi.remove(id),
    onSuccess: invalidate,
  });

  const uploadMut = useMutation({
    mutationFn: ({ id, file }: { id: number; file: File }) => empresasApi.uploadCertificado(id, file),
    onSuccess: () => { invalidate(); Swal.fire("OK", "Certificado registrado", "success"); },
    onError: (e: unknown) => Swal.fire("Error", String(e), "error"),
  });

  const rangoMut = useMutation({
    mutationFn: (p: { id: number; tipo: number; desde: number; hasta: number; vencimiento: string }) =>
      empresasApi.registerRango(p.id, { tipo: p.tipo, desde: p.desde, hasta: p.hasta, vencimiento: p.vencimiento }),
    onSuccess: () => { invalidate(); Swal.fire("OK", "Rango registrado", "success"); },
    onError: (e: unknown) => Swal.fire("Error", String(e), "error"),
  });

  const handleDelete = (id: number) => {
    Swal.fire({ title: "Eliminar empresa", text: "¿Confirmar?", icon: "warning", showCancelButton: true }).then((r) => {
      if (r.isConfirmed) deleteMut.mutate(id);
    });
  };

  const openEdit = (empresa: EmpresaItem) => {
    setEditing(empresa);
    setForm({
      razon_social: empresa.razonSocial ?? "",
      nombre_comercial: empresa.nombreComercial ?? "",
      email: empresa.email ?? "",
      telefono: empresa.telefono ?? "",
      activa: empresa.activa,
    });
  };

  const handleUpdate = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    if (!editing) return;

    const razon_social = form.razon_social.trim();
    if (!razon_social) {
      Swal.fire("Error", "La razón social es obligatoria", "error");
      return;
    }
    const email = form.email.trim();
    if (email && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
      Swal.fire("Error", "El email no tiene un formato válido", "error");
      return;
    }

    updateMut.mutate({
      id: editing.id,
      payload: {
        razon_social,
        nombre_comercial: form.nombre_comercial.trim(),
        email,
        telefono: form.telefono.trim(),
        activa: form.activa,
      },
    });
  };

  const handleUpload = (id: number) => {
    const input = document.createElement("input");
    input.type = "file";
    input.accept = ".crt,.cer,.pem";
    input.onchange = () => {
      const file = input.files?.[0];
      if (file) uploadMut.mutate({ id, file });
    };
    input.click();
  };

  const handleRango = (id: number) => {
    Swal.fire({
      title: "Registrar rango de e-NCF",
      html: `
        <input id="sw-tipo" class="swal2-input" placeholder="Tipo (31)" value="31">
        <input id="sw-desde" class="swal2-input" placeholder="Desde" value="1">
        <input id="sw-hasta" class="swal2-input" placeholder="Hasta" value="1000">
        <input id="sw-venc" class="swal2-input" placeholder="Vencimiento (YYYY-MM-DD)" value="${new Date(Date.now() + 365 * 86400000).toISOString().slice(0, 10)}">
      `,
      showCancelButton: true,
      preConfirm: () => ({
        tipo: Number((document.getElementById("sw-tipo") as HTMLInputElement).value),
        desde: Number((document.getElementById("sw-desde") as HTMLInputElement).value),
        hasta: Number((document.getElementById("sw-hasta") as HTMLInputElement).value),
        vencimiento: (document.getElementById("sw-venc") as HTMLInputElement).value,
      }),
    }).then((r) => {
      if (r.isConfirmed) {
        const p = r.value as { tipo: number; desde: number; hasta: number; vencimiento: string };
        rangoMut.mutate({ id, ...p });
      }
    });
  };

  const columns = [
    { title: "ID", data: "id" },
    { title: "RNC", data: "rnc" },
    { title: "Razón social", data: "razonSocial", defaultContent: "—" },
    { title: "Total e-CF", data: "totalEcf" },
    { title: "Cert. vigente", data: "certificadoVigente", render: (v: boolean | null) => (v ? "✅" : "❌") },
    { title: "Rangos activos", data: "rangosActivos" },
    { title: "Última recepción", data: "ultimaRecepcion", defaultContent: "—" },
    {
      title: "Acciones",
      data: "id",
      render: (id: number) =>
        `<button class="btn-sec" data-act="edit" data-id="${id}">Editar</button>
         <button class="btn-sec" data-act="cert" data-id="${id}">Cert</button>
         <button class="btn-sec" data-act="rango" data-id="${id}">Rango</button>
         <button class="btn-danger" data-act="del" data-id="${id}">Eliminar</button>`,
    },
  ];

  return (
    <div>
      <h1 style={{ marginBottom: "var(--space-5)" }}>Empresas y RNC</h1>

      <div style={{ marginBottom: "var(--space-4)", display: "flex", gap: "var(--space-2)", flexWrap: "wrap" }}>
        <input placeholder="RNC" value={rnc} onChange={(e) => setRnc(e.target.value)} style={{ padding: "var(--space-2)" }} />
        <input placeholder="Razón social" value={razon} onChange={(e) => setRazon(e.target.value)} style={{ padding: "var(--space-2)" }} />
        <button className="btn-primary" onClick={() => createMut.mutate()} disabled={!rnc || createMut.isPending}>
          Crear empresa
        </button>
      </div>

      {editing && (
        <form
          onSubmit={handleUpdate}
          style={{
            marginBottom: "var(--space-4)",
            padding: "var(--space-4)",
            border: "1px solid var(--color-border)",
            borderRadius: "var(--radius-md)",
            display: "grid",
            gap: "var(--space-2)",
          }}
        >
          <strong>Editar empresa</strong>
          <label>
            RNC (no editable)
            <input value={editing.rnc} disabled style={{ padding: "var(--space-2)" }} />
          </label>
          <label>
            Razón social
            <input
              value={form.razon_social}
              onChange={(e) => setForm({ ...form, razon_social: e.target.value })}
              style={{ padding: "var(--space-2)" }}
            />
          </label>
          <label>
            Nombre comercial
            <input
              value={form.nombre_comercial}
              onChange={(e) => setForm({ ...form, nombre_comercial: e.target.value })}
              style={{ padding: "var(--space-2)" }}
            />
          </label>
          <label>
            Email
            <input
              type="email"
              value={form.email}
              onChange={(e) => setForm({ ...form, email: e.target.value })}
              style={{ padding: "var(--space-2)" }}
            />
          </label>
          <label>
            Teléfono
            <input
              value={form.telefono}
              onChange={(e) => setForm({ ...form, telefono: e.target.value })}
              style={{ padding: "var(--space-2)" }}
            />
          </label>
          <label style={{ display: "flex", gap: "var(--space-2)", alignItems: "center" }}>
            <input
              type="checkbox"
              checked={form.activa}
              onChange={(e) => setForm({ ...form, activa: e.target.checked })}
            />
            Activa
          </label>
          <div style={{ display: "flex", gap: "var(--space-2)" }}>
            <button className="btn-primary" type="submit" disabled={updateMut.isPending}>Guardar</button>
            <button className="btn-sec" type="button" onClick={() => setEditing(null)}>Cancelar</button>
          </div>
        </form>
      )}

      {isLoading && <div className="skeleton" style={{ height: 200 }} />}
      {error && <p style={{ color: "var(--color-danger)" }}>Error al cargar empresas</p>}
      {data && (
        <div
          onClick={(e) => {
            const t = e.target as HTMLElement;
            const id = Number(t.getAttribute("data-id"));
            const act = t.getAttribute("data-act");
            if (!id || !act) return;
            if (act === "edit") {
              const empresa = data.data.find((c) => c.id === id);
              if (empresa) openEdit(empresa);
            }
            if (act === "cert") handleUpload(id);
            if (act === "rango") handleRango(id);
            if (act === "del") handleDelete(id);
          }}
        >
          <DataTable data={data.data} columns={columns} pageLength={10} emptyTable="Sin datos" />
        </div>
      )}
    </div>
  );
}
