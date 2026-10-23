import { useState } from "react";
import { trackidsApi, type TrackIdQueryResponse } from "../lib/api";

export function TrackIds() {
  const [trackId, setTrackId] = useState("");
  const [rnc, setRnc] = useState("101234567");
  const [encf, setEncf] = useState("E310000000001");
  const [result, setResult] = useState<TrackIdQueryResponse | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  const queryByTrackId = async () => {
    setError(null);
    setLoading(true);
    try {
      const res = await trackidsApi.byTrackId(trackId);
      setResult(res);
    } catch (e) {
      setError(e instanceof Error ? e.message : "Error");
      setResult(null);
    } finally {
      setLoading(false);
    }
  };

  const queryByRncEncf = async () => {
    setError(null);
    setLoading(true);
    try {
      const res = await trackidsApi.byRncEncf(rnc, encf);
      setResult(res);
    } catch (e) {
      setError(e instanceof Error ? e.message : "Error");
      setResult(null);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div>
      <h1 style={{ marginBottom: "var(--space-5)" }}>Consulta de TrackIds</h1>

      <div className="card" style={{ marginBottom: "var(--space-4)" }}>
        <h3>Por TrackId</h3>
        <div style={{ display: "flex", gap: "var(--space-2)", marginBottom: "var(--space-3)" }}>
          <input placeholder="track-id" value={trackId} onChange={(e) => setTrackId(e.target.value)} />
          <button className="primary" onClick={queryByTrackId} disabled={loading || !trackId}>
            Consultar
          </button>
        </div>
      </div>

      <div className="card" style={{ marginBottom: "var(--space-4)" }}>
        <h3>Por RNC y e-NCF</h3>
        <div style={{ display: "flex", gap: "var(--space-2)", marginBottom: "var(--space-3)", flexWrap: "wrap" }}>
          <input placeholder="RNC emisor" value={rnc} onChange={(e) => setRnc(e.target.value)} style={{ width: 160 }} />
          <input placeholder="e-NCF" value={encf} onChange={(e) => setEncf(e.target.value)} style={{ width: 200 }} />
          <button className="primary" onClick={queryByRncEncf} disabled={loading}>
            Consultar
          </button>
        </div>
      </div>

      {error && <p style={{ color: "var(--color-danger)" }}>{error}</p>}

      {result && (
        <div className="card">
          <pre style={{ whiteSpace: "pre-wrap", fontSize: 13 }}>{JSON.stringify(result, null, 2)}</pre>
        </div>
      )}
    </div>
  );
}