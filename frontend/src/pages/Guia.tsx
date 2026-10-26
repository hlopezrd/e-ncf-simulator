import { useState } from "react";

export function Guia() {
  const [xml] = useState(`<ECF>
  <Encabezado>
    <Version>1.0</Version>
    <IdDoc>
      <TipoeCF>31</TipoeCF>
      <eNCF>E310000000001</eNCF>
      <FechaVencimientoSecuencia>31-12-2027</FechaVencimientoSecuencia>
      <TipoIngresos>01</TipoIngresos>
      <TipoPago>1</TipoPago>
      <FechaEmision>01-01-2026</FechaEmision>
    </IdDoc>
    <Emisor>
      <RNCEmisor>101234567</RNCEmisor>
      <RazonSocialEmisor>Empresa Demo</RazonSocialEmisor>
      <DireccionEmisor>Calle 1</DireccionEmisor>
      <CorreoEmisor>demo@example.com</CorreoEmisor>
    </Emisor>
    <Comprador>
      <RNCComprador>101987654</RNCComprador>
      <RazonSocialComprador>Comprador Demo</RazonSocialComprador>
    </Comprador>
    <Totales>
      <MontoGravadoTotal>1000.00</MontoGravadoTotal>
      <MontoGravadoI1>1000.00</MontoGravadoI1>
      <TotalITBIS>0.00</TotalITBIS>
      <MontoTotal>1000.00</MontoTotal>
    </Totales>
  </Encabezado>
  <DetallesItems>
    <Item>
      <NumeroLinea>1</NumeroLinea>
      <IndicadorFacturacion>1</IndicadorFacturacion>
      <NombreItem>Item demo</NombreItem>
      <IndicadorBienoServicio>1</IndicadorBienoServicio>
      <CantidadItem>1</CantidadItem>
      <PrecioUnitarioItem>1000.00</PrecioUnitarioItem>
      <MontoItem>1000.00</MontoItem>
    </Item>
  </DetallesItems>
  <FechaHoraFirma>01-01-2026 10:00:00</FechaHoraFirma>
  <!-- Signature (XMLDSig, RSA-SHA256) con el certificado registrado -->
</ECF>`);

  return (
    <div>
      <h1 style={{ marginBottom: "var(--space-5)" }}>Guía de envío de e-CF (DGII)</h1>

      <div className="card" style={{ marginBottom: "var(--space-4)" }}>
        <h3>Flujo de autenticación (semilla)</h3>
        <ol style={{ lineHeight: 1.8 }}>
          <li>Obtener la semilla: <code>GET /testecf/autenticacion/api/autenticacion/semilla</code></li>
          <li>Validar la firma de la semilla con el certificado público del simulador:
            <code>GET /testecf/autenticacion/api/autenticacion/certificado</code>
          </li>
          <li>Firmar la semilla (sin la firma del simulador) con tu certificado (RSA-SHA256).</li>
          <li>Enviarla: <code>POST /testecf/autenticacion/api/autenticacion/validarsemilla</code> (multipart, campo <code>xml</code>).</li>
          <li>Recibir el token JWT (válido 1 hora).</li>
        </ol>
        <p style={{ color: "var(--color-muted)", fontSize: 13 }}>
          El token vence a los 3600 segundos. Después hay que volver a autenticarse.
        </p>
      </div>

      <div className="card" style={{ marginBottom: "var(--space-4)" }}>
        <h3>Envío de un e-CF</h3>
        <ol style={{ lineHeight: 1.8 }}>
          <li>Autenticarse y obtener el token JWT.</li>
          <li>Enviar el XML firmado:
            <code>POST /testecf/recepcion/api/facturaselectronicas</code> con header
            <code>Authorization: Bearer &lt;token&gt;</code> y campo <code>xml</code> (multipart).
          </li>
          <li>Recibir el <code>trackId</code>.</li>
          <li>Consultar el estado por TrackId o por RNC + e-NCF.</li>
        </ol>
        <p style={{ color: "var(--color-muted)", fontSize: 13 }}>
          El RNC del token debe coincidir con el <code>rncEmisor</code> del XML (si no, E019).
        </p>
      </div>

      <div className="card" style={{ marginBottom: "var(--space-4)" }}>
        <h3>Requisitos de la firma (XMLDSig)</h3>
        <ul style={{ lineHeight: 1.8 }}>
          <li>Algoritmo: RSA-SHA256.</li>
          <li>Canonicalización: C14N 1.0.</li>
          <li>Reference URI = "" (todo el documento).</li>
          <li>Digest: SHA-256.</li>
          <li>El certificado embebido debe ser exactamente el registrado para el RNC (si no, E018).</li>
          <li>El certificado debe estar vigente (si no, E017).</li>
          <li>El e-NCF debe pertenecer a un rango autorizado y seguir la secuencia (E020, E023).</li>
        </ul>
      </div>

      <div className="card">
        <h3>Ejemplo de XML (estructura mínima)</h3>
        <pre
          style={{
            whiteSpace: "pre-wrap",
            fontSize: 12,
            background: "var(--color-surface-alt)",
            padding: "var(--space-3)",
            borderRadius: "var(--radius-sm)",
            maxHeight: 500,
            overflow: "auto",
          }}
        >
          {xml}
        </pre>
        <p style={{ color: "var(--color-muted)", fontSize: 12, marginTop: "var(--space-3)" }}>
          Nota: la firma debe ser válida criptográficamente. En el simulador se verifica contra el
          certificado registrado para el RNC (acepta self-signed y emitidos por CA).
        </p>
      </div>
    </div>
  );
}