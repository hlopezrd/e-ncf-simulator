require "rails_helper"

RSpec.describe "ConsultaEstado", type: :request do
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
