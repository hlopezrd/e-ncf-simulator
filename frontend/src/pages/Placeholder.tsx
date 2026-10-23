export function Placeholder({ title }: { title: string }) {
  return (
    <div className="card">
      <h1>{title}</h1>
      <p style={{ color: "var(--color-muted)" }}>
        Esta sección estará disponible en fases posteriores.
      </p>
    </div>
  );
}