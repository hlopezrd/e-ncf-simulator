require "rails_helper"
require "base64"

RSpec.describe "DGII Consultas", type: :request do
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

    # issue a token via semilla
    get "/testecf/autenticacion/api/autenticacion/semilla"
    seed = response.body
    signed = Ecfs::CryptoService.sign(seed)
    post "/testecf/autenticacion/api/autenticacion/validarsemilla", params: { xml: signed }
    @token = JSON.parse(response.body)["token"]

    # receive an e-CF
    ecf_xml = File.read(Rails.root.join("spec", "fixtures", "xml", "valido_xsd.xml"))
    ecf_xml = ecf_xml.sub("E310000000001", "E310000009999")
    signed_ecf = Ecfs::CryptoService.sign(Nokogiri::XML(ecf_xml).to_xml)
    post "/testecf/recepcion/api/facturaselectronicas",
         params: { xml: signed_ecf },
         headers: { "Authorization" => "Bearer #{@token}" }
    @track_id = JSON.parse(response.body)["trackId"]
  end

  it "consulta resultado by trackId" do
    get "/testecf/consultaresultado/api/Consultas/Estado", params: { trackId: @track_id }, headers: { "Authorization" => "Bearer #{@token}" }
    expect(response).to have_http_status(:ok)
    json = JSON.parse(response.body)
    expect(json["trackId"]).to eq(@track_id)
    expect(json["codigo"]).to eq(1)
    expect(json["estado"]).to eq("Aceptado")
  end

  it "returns not found for unknown trackId" do
    get "/testecf/consultaresultado/api/Consultas/Estado", params: { trackId: "no-existe" }, headers: { "Authorization" => "Bearer #{@token}" }
    expect(response).to have_http_status(:ok)
    json = JSON.parse(response.body)
    expect(json["codigo"]).to eq(0)
    expect(json["estado"]).to eq("No encontrado")
  end

  it "consulta estado by rnc+encf" do
    get "/testecf/consultaestado/api/Consultas/Estado",
        params: { rncEmisor: "101234567", ncfElectronico: "E310000009999" },
        headers: { "Authorization" => "Bearer #{@token}" }
    expect(response).to have_http_status(:ok)
    json = JSON.parse(response.body)
    expect(json["codigo"]).to eq(1)
    expect(json["rncEmisor"]).to eq("101234567")
    expect(json["ncfElectronico"]).to eq("E310000009999")
  end

  it "consulta trackids by rnc+encf" do
    get "/testecf/consultatrackids/api/TrackIds/Consulta",
        params: { rncEmisor: "101234567", encf: "E310000009999" },
        headers: { "Authorization" => "Bearer #{@token}" }
    expect(response).to have_http_status(:ok)
    json = JSON.parse(response.body)
    expect(json).to be_an(Array)
    expect(json.first["trackId"]).to eq(@track_id)
  end
end
