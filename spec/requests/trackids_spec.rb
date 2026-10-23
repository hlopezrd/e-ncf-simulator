require "rails_helper"

RSpec.describe "Trackids", type: :request do
  let(:token) do
    post "/api/auth", params: { rnc: "101234567", usuario: "usuario-prueba", password: "password-prueba" }
    JSON.parse(response.body)["token"]
  end

  def fixture(name)
    File.read(Rails.root.join("spec/fixtures/xml/#{name}"))
  end

  it "returns trackId for existing rnc+encf" do
    post "/api/recepcion", params: { xml: fixture("valido_xsd.xml") }, headers: { "Authorization" => "Bearer #{token}" }
    track_id = JSON.parse(response.body)["trackId"]

    get "/api/trackids/consulta", params: { rncemisor: "101234567", encf: "E310000000001" }, headers: { "Authorization" => "Bearer #{token}" }
    expect(response).to have_http_status(:ok)
    json = JSON.parse(response.body)
    expect(json["trackId"]).to eq(track_id)
    expect(json["estado"]).to eq("Aceptado")
  end

  it "returns not found for unknown rnc+encf" do
    get "/api/trackids/consulta", params: { rncemisor: "999999999", encf: "E310000009999" }, headers: { "Authorization" => "Bearer #{token}" }
    expect(response).to have_http_status(:ok)
    json = JSON.parse(response.body)
    expect(json["trackId"]).to be_nil
    expect(json["estado"]).to eq("No Encontrado")
  end
end
