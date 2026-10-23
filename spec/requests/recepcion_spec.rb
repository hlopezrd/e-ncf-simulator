require "rails_helper"

RSpec.describe "Recepcion", type: :request do
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
    expect(json["codigo"]).to eq("0")
    expect(json["mensaje"]).to eq("e-CF recibido correctamente")
  end

  it "rejects malformed XML" do
    post "/api/recepcion", params: { xml: fixture("mal_formado.xml") }, headers: { "Authorization" => "Bearer #{token}" }
    expect(response).to have_http_status(:unprocessable_entity)
    json = JSON.parse(response.body)
    expect(json["codigo"]).to eq("VALIDATION_ERROR")
    expect(json["errores"]).to be_an(Array)
  end

  it "rejects XML without RNC" do
    post "/api/recepcion", params: { xml: fixture("sin_rnc.xml") }, headers: { "Authorization" => "Bearer #{token}" }
    expect(response).to have_http_status(:unprocessable_entity)
    json = JSON.parse(response.body)
    codigos = json["errores"].map { |e| e["codigo"] }
    expect(codigos).to include("E004")
  end

  it "rejects XML without eNCF" do
    post "/api/recepcion", params: { xml: fixture("sin_encf.xml") }, headers: { "Authorization" => "Bearer #{token}" }
    expect(response).to have_http_status(:unprocessable_entity)
    json = JSON.parse(response.body)
    codigos = json["errores"].map { |e| e["codigo"] }
    expect(codigos).to include("E005")
  end

  it "rejects invalid eNCF" do
    post "/api/recepcion", params: { xml: fixture("encf_invalido.xml") }, headers: { "Authorization" => "Bearer #{token}" }
    expect(response).to have_http_status(:unprocessable_entity)
    json = JSON.parse(response.body)
    codigos = json["errores"].map { |e| e["codigo"] }
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

  it "rejects XML that fails XSD validation when enabled" do
    ENV["XSD_VALIDATION_ENABLED"] = "true"
    post "/api/recepcion", params: { xml: fixture("valido.xml") }, headers: { "Authorization" => "Bearer #{token}" }
    expect(response).to have_http_status(:unprocessable_entity)
    json = JSON.parse(response.body)
    codigos = json["errores"].map { |e| e["codigo"] }
    expect(codigos).to include("X001")
  ensure
    ENV.delete("XSD_VALIDATION_ENABLED")
  end

  it "rejects duplicate e-CF" do
    post "/api/recepcion", params: { xml: fixture("valido_xsd.xml") }, headers: { "Authorization" => "Bearer #{token}" }
    expect(response).to have_http_status(:ok)
    post "/api/recepcion", params: { xml: fixture("valido_xsd.xml") }, headers: { "Authorization" => "Bearer #{token}" }
    expect(response).to have_http_status(:unprocessable_entity)
    json = JSON.parse(response.body)
    codigos = json["errores"].map { |e| e["codigo"] }
    expect(codigos).to include("E010")
  end
end
