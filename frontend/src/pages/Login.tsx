import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { useAuth } from "../context/AuthContext";

export function Login() {
  const { login } = useAuth();
  const navigate = useNavigate();
  const [rnc, setRnc] = useState("");
  const [usuario, setUsuario] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  const fillDemo = () => {
    setRnc("101234567");
    setUsuario("usuario-prueba");
    setPassword("password-prueba");
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setLoading(true);
    try {
      await login({ rnc, usuario, password });
      navigate("/");
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : "Credenciales inválidas";
      setError(msg);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div
      style={{
        minHeight: "100vh",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        background: "linear-gradient(135deg, #0f172a 0%, #1e3a8a 50%, #2563eb 100%)",
        padding: "var(--space-4)",
      }}
    >
      <div
        className="card elevated"
        style={{
          width: "100%",
          maxWidth: 420,
          padding: "var(--space-8)",
        }}
      >
        <div style={{ textAlign: "center", marginBottom: "var(--space-6)" }}>
          <div
            style={{
              width: 56,
              height: 56,
              borderRadius: "var(--radius-lg)",
              background: "linear-gradient(135deg, var(--color-primary), var(--color-primary-hover))",
              color: "#fff",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              fontSize: 24,
              fontWeight: 700,
              margin: "0 auto var(--space-3)",
              boxShadow: "var(--shadow-md)",
            }}
          >
            e
          </div>
          <h1 style={{ margin: 0, fontSize: 22 }}>Portal Administrativo</h1>
          <p style={{ color: "var(--color-muted)", fontSize: 13, marginTop: 4 }}>
            Simulador e-CF (DGII RD) — sin validez fiscal
          </p>
        </div>

        <form onSubmit={handleSubmit}>
          <div style={{ marginBottom: "var(--space-3)" }}>
            <label style={{ fontSize: 13, fontWeight: 500, display: "block", marginBottom: 4 }}>
              RNC
            </label>
            <input aria-label="RNC" value={rnc} onChange={(e) => setRnc(e.target.value)} placeholder="101234567" />
          </div>
          <div style={{ marginBottom: "var(--space-3)" }}>
            <label style={{ fontSize: 13, fontWeight: 500, display: "block", marginBottom: 4 }}>
              Usuario
            </label>
            <input aria-label="Usuario" value={usuario} onChange={(e) => setUsuario(e.target.value)} placeholder="usuario-prueba" />
          </div>
          <div style={{ marginBottom: "var(--space-4)" }}>
            <label style={{ fontSize: 13, fontWeight: 500, display: "block", marginBottom: 4 }}>
              Contraseña
            </label>
            <input
              type="password"
              aria-label="Contraseña"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="password-prueba"
            />
          </div>

          {error && (
            <div
              style={{
                color: "var(--color-danger)",
                background: "var(--color-danger-light)",
                padding: "var(--space-2) var(--space-3)",
                borderRadius: "var(--radius-sm)",
                fontSize: 13,
                marginBottom: "var(--space-3)",
              }}
            >
              {error}
            </div>
          )}

          <button type="submit" className="primary" disabled={loading} style={{ width: "100%", marginBottom: "var(--space-3)" }}>
            {loading ? "Ingresando..." : "Ingresar"}
          </button>

          {import.meta.env.DEV && (
            <button type="button" onClick={fillDemo} style={{ width: "100%", fontSize: 12, marginTop: "var(--space-2)" }}>
              Usar credenciales de prueba
            </button>
          )}
        </form>

        {import.meta.env.DEV && (
          <p style={{ color: "var(--color-muted)", fontSize: 11, textAlign: "center", marginTop: "var(--space-4)" }}>
            Credenciales: RNC 101234567 / usuario-prueba / password-prueba
          </p>
        )}
      </div>
    </div>
  );
}