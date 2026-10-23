import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { usuariosApi, rolesApi } from "../lib/api";

export function Usuarios() {
  const qc = useQueryClient();
  const { data, isLoading, error } = useQuery({
    queryKey: ["usuarios"],
    queryFn: usuariosApi.list,
  });

  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [roleId, setRoleId] = useState("");
  const [roleName, setRoleName] = useState("");

  const [editingId, setEditingId] = useState<number | null>(null);
  const [editName, setEditName] = useState("");
  const [editEmail, setEditEmail] = useState("");
  const [editRoleId, setEditRoleId] = useState("");
  const [editActive, setEditActive] = useState(true);

  const createUser = useMutation({
    mutationFn: () => usuariosApi.create({ name, email, role_id: Number(roleId), active: true }),
    onSuccess: () => { setName(""); setEmail(""); setRoleId(""); qc.invalidateQueries({ queryKey: ["usuarios"] }); },
  });

  const deleteUser = useMutation({
    mutationFn: (id: number) => usuariosApi.remove(id),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["usuarios"] }),
  });

  const createRole = useMutation({
    mutationFn: () => rolesApi.create({ name: roleName }),
    onSuccess: () => { setRoleName(""); qc.invalidateQueries({ queryKey: ["usuarios"] }); },
  });

  const saveEdit = useMutation({
    mutationFn: () => usuariosApi.update(editingId!, { name: editName, email: editEmail, role_id: Number(editRoleId), active: editActive }),
    onSuccess: () => { setEditingId(null); qc.invalidateQueries({ queryKey: ["usuarios"] }); },
  });

  const startEdit = (u: { id: number; name: string; email: string; roleId?: number; active: boolean }) => {
    setEditingId(u.id);
    setEditName(u.name);
    setEditEmail(u.email);
    setEditRoleId(u.roleId ? String(u.roleId) : "");
    setEditActive(u.active);
  };

  return (
    <div>
      <h1 style={{ marginBottom: "var(--space-5)" }}>Usuarios y roles</h1>

      <div className="card" style={{ marginBottom: "var(--space-4)" }}>
        <h3>Crear usuario</h3>
        <div style={{ display: "flex", gap: "var(--space-2)", flexWrap: "wrap", alignItems: "center" }}>
          <input placeholder="Nombre" value={name} onChange={(e) => setName(e.target.value)} style={{ width: 160 }} />
          <input placeholder="Email" value={email} onChange={(e) => setEmail(e.target.value)} style={{ width: 200 }} />
          <select value={roleId} onChange={(e) => setRoleId(e.target.value)} style={{ width: 160 }}>
            <option value="">Seleccionar rol</option>
            {data?.roles.map((r) => (
              <option key={r.id} value={r.id}>{r.name}</option>
            ))}
          </select>
          <button className="primary" onClick={() => createUser.mutate()} disabled={!name || !email || !roleId}>
            Crear
          </button>
        </div>
      </div>

      <div className="card" style={{ marginBottom: "var(--space-4)" }}>
        <h3>Crear rol</h3>
        <div style={{ display: "flex", gap: "var(--space-2)" }}>
          <input placeholder="Nombre del rol" value={roleName} onChange={(e) => setRoleName(e.target.value)} />
          <button className="primary" onClick={() => createRole.mutate()} disabled={!roleName}>
            Crear rol
          </button>
        </div>
      </div>

      {isLoading && <div className="skeleton" style={{ height: 200 }} />}
      {error && <p style={{ color: "var(--color-danger)" }}>Error al cargar usuarios</p>}

      {data && (
        <>
          <h3>Usuarios</h3>
          <table style={{ marginBottom: "var(--space-6)" }}>
            <thead>
              <tr>
                <th>Nombre</th>
                <th>Email</th>
                <th>Rol</th>
                <th>Activo</th>
                <th>Acciones</th>
              </tr>
            </thead>
            <tbody>
              {data.users.map((u) => (
                <tr key={u.id}>
                  {editingId === u.id ? (
                    <>
                      <td><input value={editName} onChange={(e) => setEditName(e.target.value)} /></td>
                      <td><input value={editEmail} onChange={(e) => setEditEmail(e.target.value)} /></td>
                      <td>
                        <select value={editRoleId} onChange={(e) => setEditRoleId(e.target.value)}>
                          {data.roles.map((r) => (
                            <option key={r.id} value={r.id}>{r.name}</option>
                          ))}
                        </select>
                      </td>
                      <td>
                        <input type="checkbox" checked={editActive} onChange={(e) => setEditActive(e.target.checked)} />
                      </td>
                      <td style={{ display: "flex", gap: "var(--space-2)" }}>
                        <button className="primary" onClick={() => saveEdit.mutate()}>Guardar</button>
                        <button onClick={() => setEditingId(null)}>Cancelar</button>
                      </td>
                    </>
                  ) : (
                    <>
                      <td>{u.name}</td>
                      <td>{u.email}</td>
                      <td><span className="badge info">{u.role}</span></td>
                      <td>
                        <span className={`badge ${u.active ? "success" : "danger"}`}>
                          {u.active ? "Sí" : "No"}
                        </span>
                      </td>
                      <td style={{ display: "flex", gap: "var(--space-2)" }}>
                        <button onClick={() => startEdit({ ...u, roleId: data.roles.find((r) => r.name === u.role)?.id })}>
                          Editar
                        </button>
                        <button onClick={() => deleteUser.mutate(u.id)}>Eliminar</button>
                      </td>
                    </>
                  )}
                </tr>
              ))}
              {data.users.length === 0 && (
                <tr>
                  <td colSpan={5} style={{ textAlign: "center", color: "var(--color-muted)" }}>
                    Sin usuarios
                  </td>
                </tr>
              )}
            </tbody>
          </table>

          <h3>Roles</h3>
          <table>
            <thead>
              <tr>
                <th>Nombre</th>
                <th>Descripción</th>
              </tr>
            </thead>
            <tbody>
              {data.roles.map((r) => (
                <tr key={r.id}>
                  <td><span className="badge primary">{r.name}</span></td>
                  <td style={{ color: "var(--color-muted)" }}>{r.description ?? "—"}</td>
                </tr>
              ))}
              {data.roles.length === 0 && (
                <tr>
                  <td colSpan={2} style={{ textAlign: "center", color: "var(--color-muted)" }}>
                    Sin roles
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </>
      )}
    </div>
  );
}