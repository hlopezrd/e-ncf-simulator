require "rails_helper"
require "base64"

RSpec.describe "Recepcion", type: :request do
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
  end

  let(:token) do
    post "/api/auth", params: { rnc: "101234567", usuario: "usuario-prueba", password: "password-prueba" }
    JSON.parse(response.body)["token"]
  end

  def fixture(name)
    File.read(Rails.root.join("spec/fixtures/xml/#{name}"))
  end

  it "rejects request without token" do
    post "/api/recepcion", params: { xml: fixture("valido.xml") }
    expect(response).to have_http_status(:unauthorized)
  end

  it "accepts valid XML" do
    post "/api/recepcion", params: { xml: fixture("valido_xsd.xml") }, headers: { "Authorization" => "Bearer #{token}" }
    expect(response).to have_http_status(:ok)
    json = JSON.parse(response.body)
    expect(json["trackId"]).to be_present
    expect(json["mensajes"]).to eq([])
  end

  it "returns messages for malformed XML" do
    post "/api/recepcion", params: { xml: fixture("mal_formado.xml") }, headers: { "Authorization" => "Bearer #{token}" }
    expect(response).to have_http_status(:ok)
    json = JSON.parse(response.body)
    expect(json["trackId"]).to be_present
    codigos = json["mensajes"].map { |m| m["codigo"] }
    expect(codigos).to include("E002")
  end

  it "returns messages for XML without RNC" do
    post "/api/recepcion", params: { xml: fixture("sin_rnc.xml") }, headers: { "Authorization" => "Bearer #{token}" }
    expect(response).to have_http_status(:ok)
    json = JSON.parse(response.body)
    codigos = json["mensajes"].map { |m| m["codigo"] }
    expect(codigos).to include("E004")
  end

  it "returns messages for XML without eNCF" do
    post "/api/recepcion", params: { xml: fixture("sin_encf.xml") }, headers: { "Authorization" => "Bearer #{token}" }
    expect(response).to have_http_status(:ok)
    json = JSON.parse(response.body)
    codigos = json["mensajes"].map { |m| m["codigo"] }
    expect(codigos).to include("E005")
  end

  it "returns messages for invalid eNCF" do
    post "/api/recepcion", params: { xml: fixture("encf_invalido.xml") }, headers: { "Authorization" => "Bearer #{token}" }
    expect(response).to have_http_status(:ok)
    json = JSON.parse(response.body)
    codigos = json["mensajes"].map { |m| m["codigo"] }
    expect(codigos).to include("E006")
  end

  it "accepts XML that passes XSD validation when enabled" do
    ENV["XSD_VALIDATION_ENABLED"] = "true"
    post "/api/recepcion", params: { xml: fixture("valido_xsd.xml") }, headers: { "Authorization" => "Bearer #{token}" }
    expect(response).to have_http_status(:ok)
    json = JSON.parse(response.body)
    expect(json["trackId"]).to be_present
  ensure
    ENV.delete("XSD_VALIDATION_ENABLED")
  end

  it "returns messages for XML that fails XSD validation when enabled" do
    ENV["XSD_VALIDATION_ENABLED"] = "true"
    post "/api/recepcion", params: { xml: fixture("valido.xml") }, headers: { "Authorization" => "Bearer #{token}" }
    expect(response).to have_http_status(:ok)
    json = JSON.parse(response.body)
    codigos = json["mensajes"].map { |m| m["codigo"] }
    expect(codigos).to include("X001")
  ensure
    ENV.delete("XSD_VALIDATION_ENABLED")
  end

  it "returns duplicate message for duplicate e-CF" do
    post "/api/recepcion", params: { xml: fixture("valido_xsd.xml") }, headers: { "Authorization" => "Bearer #{token}" }
    expect(response).to have_http_status(:ok)
    post "/api/recepcion", params: { xml: fixture("valido_xsd.xml") }, headers: { "Authorization" => "Bearer #{token}" }
    expect(response).to have_http_status(:ok)
    json = JSON.parse(response.body)
    codigos = json["mensajes"].map { |m| m["codigo"] }
    expect(codigos).to include("E010")
  end
end
