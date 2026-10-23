import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { useAuth } from "../context/AuthContext";

export function Login() {
  const { login } = useAuth();
  const navigate = useNavigate();
  const [rnc, setRnc] = useState("101234567");
  const [usuario, setUsuario] = useState("usuario-prueba");
  const [password, setPassword] = useState("password-prueba");
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setLoading(true);
    try {
      await login({ rnc, usuario, password });
      navigate("/");
    } catch (err: unknown) {
      const msg =
        err instanceof Error ? err.message : "Credenciales inválidas";
      setError(msg);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={{ maxWidth: 400, margin: "80px auto" }} className="card">
      <h1>Iniciar sesión</h1>
      <p style={{ color: "var(--color-muted)", fontSize: 13 }}>
        Simulador local e-CF — sin validez fiscal
      </p>
      <form onSubmit={handleSubmit}>
        <div style={{ marginBottom: "var(--space-3)" }}>
          <label>RNC</label>
          <input value={rnc} onChange={(e) => setRnc(e.target.value)} />
        </div>
        <div style={{ marginBottom: "var(--space-3)" }}>
          <label>Usuario</label>
          <input value={usuario} onChange={(e) => setUsuario(e.target.value)} />
        </div>
        <div style={{ marginBottom: "var(--space-4)" }}>
          <label>Contraseña</label>
          <input
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
          />
        </div>
        {error && (
          <div style={{ color: "var(--color-danger)", marginBottom: "var(--space-3)" }}>
            {error}
          </div>
        )}
        <button type="submit" className="primary" disabled={loading} style={{ width: "100%" }}>
          {loading ? "Ingresando..." : "Ingresar"}
        </button>
      </form>
    </div>
  );
}