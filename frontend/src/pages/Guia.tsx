export function Guia() {
  const xml = `<ECF>
  <Encabezado>
    <Version>1.0</Version>
    <IdDoc>
      <TipoeCF>31</TipoeCF>
      <eNCF>E310000000001</eNCF>
      <FechaVencimientoSecuencia>31-12-2026</FechaVencimientoSecuencia>
      <TipoIngresos>01</TipoIngresos>
      <TipoPago>1</TipoPago>
      <FechaEmision>01-01-2026</FechaEmision>
    </IdDoc>
    <Emisor>
      <RNCEmisor>101234567</RNCEmisor>
      <RazonSocialEmisor>Empresa Demo</RazonSocialEmisor>
      <DireccionEmisor>Calle 1</DireccionEmisor>
      <CorreoEmisor>demo@example.com</CorreoEmisor>
      <FechaEmision>01-01-2026</FechaEmision>
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
  <Signature xmlns="http://www.w3.org/2000/09/xmldsig#">
    <SignedInfo>
      <CanonicalizationMethod Algorithm="http://www.w3.org/TR/2001/REC-xml-c14n-20010315"/>
      <SignatureMethod Algorithm="http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"/>
      <Reference URI="">
        <DigestMethod Algorithm="http://www.w3.org/2001/04/xmlenc#sha256"/>
        <DigestValue>simulated-digest</DigestValue>
      </Reference>
    </SignedInfo>
    <SignatureValue>simulated-signature-value</SignatureValue>
    <KeyInfo>
      <X509Data>
        <X509Certificate>simulated-certificate</X509Certificate>
      </X509Data>
    </KeyInfo>
  </Signature>
</ECF>`;

  return (
    <div>
      <h1 style={{ marginBottom: "var(--space-5)" }}>Guía de envío de e-CF</h1>

      <div className="card" style={{ marginBottom: "var(--space-4)" }}>
        <h3>Flujo</h3>
        <ol style={{ lineHeight: 1.8 }}>
          <li>Autenticarse: <code>POST /api/auth</code> con RNC, usuario y contraseña.</li>
          <li>Obtener el token (válido por 1 hora).</li>
          <li>Enviar el XML: <code>POST /api/recepcion</code> con header <code>Authorization: Bearer &lt;token&gt;</code>.</li>
          <li>Consultar el estado por TrackId o por RNC + e-NCF.</li>
        </ol>
        <p style={{ color: "var(--color-muted)", fontSize: 13 }}>
          El token vence a los 3600 segundos (1 hora). Después hay que volver a autenticarse.
        </p>
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
          Nota: la firma debe ser válida criptográficamente en producción. En el simulador, la verificación
          usa el certificado incluido en el XML (self-signed de prueba).
        </p>
      </div>
    </div>
  );
}