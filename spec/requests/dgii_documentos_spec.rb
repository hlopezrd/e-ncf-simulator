require "rails_helper"
require "base64"

RSpec.describe "DGII Documentos (Fase 5)", type: :request do
  before do
    xml = File.read(Rails.root.join("spec", "fixtures", "xml", "valido_xsd.xml"))
    doc = Nokogiri::XML(xml)
    node = doc.xpath("//*[local-name()='X509Certificate']").first
    cert = OpenSSL::X509::Certificate.new(Base64.decode64(node.content.strip))
    tp = Digest::SHA256.hexdigest(cert.to_der)
    Certificate.find_or_create_by!(rnc: "101234567", thumbprint: tp) do |c|
      c.certificate_pem = cert.to_pem
      c.alias_name = "simulator"
      c.active = true
    end
    NcfSequence.find_or_create_by!(rnc: "101234567", tipo: 31, desde: 9999, hasta: 9999) do |s|
      s.fecha_vencimiento = Date.current + 365
      s.activa = true
    end

    get "/testecf/autenticacion/api/autenticacion/semilla"
    seed = response.body
    signed = Ecfs::CryptoService.sign(seed)
    post "/testecf/autenticacion/api/autenticacion/validarsemilla", params: { xml: signed }
    @token = JSON.parse(response.body)["token"]
  end

  it "acepta ACECF" do
    acecf = <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <ACECF>
        <DetalleAprobacionComercial>
          <Version>1.0</Version>
          <RNCEmisor>101234567</RNCEmisor>
          <eNCF>E310000000001</eNCF>
          <FechaEmision>01-01-2026</FechaEmision>
          <MontoTotal>1000.00</MontoTotal>
          <RNCComprador>101234567</RNCComprador>
          <Estado>1</Estado>
          <FechaHoraAprobacionComercial>01-01-2026 10:00:00</FechaHoraAprobacionComercial>
        </DetalleAprobacionComercial>
      </ACECF>
    XML
    signed = Ecfs::CryptoService.sign(acecf)
    post "/testecf/aprobacioncomercial/api/AprobacionComercial",
         params: { xml: signed },
         headers: { "Authorization" => "Bearer #{@token}" }
    expect(response).to have_http_status(:ok)
    json = JSON.parse(response.body)
    expect(json["codigo"]).to eq("01")
  end

  it "acepta ANECF" do
    anecf = <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <ANECF>
        <Encabezado>
          <Version>1.0</Version>
          <RncEmisor>101234567</RncEmisor>
          <CantidadeNCFAnulados>1</CantidadeNCFAnulados>
          <FechaHoraAnulacioneNCF>23-10-2026 10:00:00</FechaHoraAnulacioneNCF>
        </Encabezado>
        <DetalleAnulacion>
          <Anulacion>
            <NoLinea>1</NoLinea>
            <TipoeCF>31</TipoeCF>
            <TablaRangoSecuenciasAnuladaseNCF>
              <Secuencias>
                <SecuenciaeNCFDesde>E310000009999</SecuenciaeNCFDesde>
                <SecuenciaeNCFHasta>E310000009999</SecuenciaeNCFHasta>
              </Secuencias>
            </TablaRangoSecuenciasAnuladaseNCF>
            <CantidadeNCFAnulados>1</CantidadeNCFAnulados>
          </Anulacion>
        </DetalleAnulacion>
      </ANECF>
    XML
    signed = Ecfs::CryptoService.sign(anecf)
    post "/testecf/anulacionrangos/api/operaciones/anularrango",
         params: { xml: signed },
         headers: { "Authorization" => "Bearer #{@token}" }
    expect(response).to have_http_status(:ok)
    json = JSON.parse(response.body)
    expect(json["codigo"]).to eq("0")
  end

  it "acepta RFCE" do
    rfce = <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <RFCE>
        <Encabezado>
          <Version>1.0</Version>
          <IdDoc>
            <TipoeCF>32</TipoeCF>
            <eNCF>E320000000001</eNCF>
            <TipoIngresos>01</TipoIngresos>
            <TipoPago>1</TipoPago>
          </IdDoc>
          <Emisor>
            <RNCEmisor>101234567</RNCEmisor>
            <RazonSocialEmisor>Empresa Demo</RazonSocialEmisor>
            <FechaEmision>01-01-2026</FechaEmision>
          </Emisor>
          <Comprador>
            <RNCComprador>101987654</RNCComprador>
            <RazonSocialComprador>Cliente Demo</RazonSocialComprador>
          </Comprador>
          <Totales>
            <MontoTotal>1000.00</MontoTotal>
          </Totales>
          <CodigoSeguridadeCF>ABCDEF</CodigoSeguridadeCF>
        </Encabezado>
      </RFCE>
    XML
    signed = Ecfs::CryptoService.sign(rfce)
    post "/testecf/recepcionfc/api/recepcion/ecf",
         params: { xml: signed },
         headers: { "Authorization" => "Bearer #{@token}" }
    expect(response).to have_http_status(:ok)
    json = JSON.parse(response.body)
    expect(json["codigo"]).to eq(0)
    expect(json["estado"]).to eq("Aceptado")
  end
end
