require "rails_helper"
require "base64"

RSpec.describe "ConsultaEstado", type: :request do
  before do
    role = Role.find_or_create_by!(name: "admin") { |r| r.description = "Administrador" }
    User.find_or_create_by!(rnc: "101234567", username: "usuario-prueba") do |u|
      u.name = "usuario-prueba"
      u.email = "usuario-prueba@sim.local"
      u.role = role
      u.active = true
      u.password = "password-prueba"
    end

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
    NcfSequence.find_or_create_by!(rnc: "101234567", tipo: 31, desde: 1, hasta: 999999) do |s|
      s.fecha_vencimiento = Date.current + 365
      s.activa = true
    end
  end

  let(:token) do
    post "/api/auth", params: { rnc: "101234567", usuario: "usuario-prueba", password: "password-prueba" }
    JSON.parse(response.body)["token"]
  end

  def fixture(name)
    File.read(Rails.root.join("spec/fixtures/xml/#{name}"))
  end

  it "returns estado for existing trackId" do
    post "/api/recepcion", params: { xml: fixture("valido_xsd.xml") }, headers: { "Authorization" => "Bearer #{token}" }
    track_id = JSON.parse(response.body)["trackId"]

    get "/api/consulta-estado/#{track_id}", headers: { "Authorization" => "Bearer #{token}" }
    expect(response).to have_http_status(:ok)
    json = JSON.parse(response.body)
    expect(json["trackId"]).to eq(track_id)
    expect(json["estado"]).to eq("Aceptado")
    expect(json["rncEmisor"]).to eq("101234567")
    expect(json["eNCF"]).to eq("E310000000001")
  end

  it "returns 404 for unknown trackId" do
    get "/api/consulta-estado/no-existe", headers: { "Authorization" => "Bearer #{token}" }
    expect(response).to have_http_status(:not_found)
  end
end
