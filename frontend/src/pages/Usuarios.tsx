import { useQuery } from "@tanstack/react-query";
import { usuariosApi } from "../lib/api";

export function Usuarios() {
  const { data, isLoading, error } = useQuery({
    queryKey: ["usuarios"],
    queryFn: usuariosApi.list,
  });

  return (
    <div>
      <h1 style={{ marginBottom: "var(--space-5)" }}>Usuarios y roles</h1>

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
                <th>Creado</th>
              </tr>
            </thead>
            <tbody>
              {data.users.map((u) => (
                <tr key={u.id}>
                  <td>{u.name}</td>
                  <td>{u.email}</td>
                  <td><span className="badge info">{u.role}</span></td>
                  <td>
                    <span className={`badge ${u.active ? "success" : "danger"}`}>
                      {u.active ? "Sí" : "No"}
                    </span>
                  </td>
                  <td>{new Date(u.createdAt).toLocaleString()}</td>
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