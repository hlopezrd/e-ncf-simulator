import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { reglasApi } from "../lib/api";

export function Reglas() {
  const qc = useQueryClient();
  const [active, setActive] = useState<string>("");
  const [name, setName] = useState("");
  const [ruleType, setRuleType] = useState("");
  const [value, setValue] = useState("");

  const { data, isLoading, error } = useQuery({
    queryKey: ["reglas", active],
    queryFn: () => reglasApi.list(active === "" ? undefined : active === "true"),
  });

  const createMut = useMutation({
    mutationFn: () => reglasApi.create({ name, rule_type: ruleType, value: value || undefined, active: true }),
    onSuccess: () => { setName(""); setRuleType(""); setValue(""); qc.invalidateQueries({ queryKey: ["reglas"] }); },
  });

  const deleteMut = useMutation({
    mutationFn: (id: number) => reglasApi.remove(id),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["reglas"] }),
  });

  const toggleMut = useMutation({
    mutationFn: ({ id, active }: { id: number; active: boolean }) => reglasApi.update(id, { active }),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["reglas"] }),
  });

  return (
    <div>
      <h1 style={{ marginBottom: "var(--space-5)" }}>Reglas de simulación</h1>

      <div className="card" style={{ marginBottom: "var(--space-4)", display: "flex", gap: "var(--space-2)", flexWrap: "wrap", alignItems: "center" }}>
        <input placeholder="Nombre" value={name} onChange={(e) => setName(e.target.value)} style={{ width: 160 }} />
        <input placeholder="Tipo" value={ruleType} onChange={(e) => setRuleType(e.target.value)} style={{ width: 140 }} />
        <input placeholder="Valor" value={value} onChange={(e) => setValue(e.target.value)} style={{ width: 120 }} />
        <button className="primary" onClick={() => createMut.mutate()} disabled={!name || !ruleType}>
          Agregar
        </button>
        <select value={active} onChange={(e) => setActive(e.target.value)} style={{ width: 140, marginLeft: "auto" }}>
          <option value="">Todas</option>
          <option value="true">Activas</option>
          <option value="false">Inactivas</option>
        </select>
      </div>

      {isLoading && <div className="skeleton" style={{ height: 200 }} />}
      {error && <p style={{ color: "var(--color-danger)" }}>Error al cargar reglas</p>}

      {data && (
        <table>
          <thead>
            <tr>
              <th>Nombre</th>
              <th>Tipo</th>
              <th>Activa</th>
              <th>Valor</th>
              <th>Descripción</th>
              <th>Acciones</th>
            </tr>
          </thead>
          <tbody>
            {data.data.map((r) => (
              <tr key={r.id}>
                <td>{r.name}</td>
                <td><span className="badge info">{r.ruleType}</span></td>
                <td>
                  <button onClick={() => toggleMut.mutate({ id: r.id, active: !r.active })}>
                    {r.active ? "Sí" : "No"}
                  </button>
                </td>
                <td>{r.value ?? "—"}</td>
                <td style={{ color: "var(--color-muted)", fontSize: 13 }}>{r.description ?? "—"}</td>
                <td>
                  <button onClick={() => deleteMut.mutate(r.id)}>Eliminar</button>
                </td>
              </tr>
            ))}
            {data.data.length === 0 && (
              <tr>
                <td colSpan={6} style={{ textAlign: "center", color: "var(--color-muted)" }}>
                  Sin reglas registradas
                </td>
              </tr>
            )}
          </tbody>
        </table>
      )}
    </div>
  );
}