require "rails_helper"

RSpec.describe "Auth", type: :request do
  it "authenticates with valid credentials" do
    post "/api/auth", params: { rnc: "101234567", usuario: "usuario-prueba", password: "password-prueba" }
    expect(response).to have_http_status(:ok)
    json = JSON.parse(response.body)
    expect(json["token"]).to start_with("sim-token-")
    expect(json["expiresIn"]).to eq(3600)
    expect(json["tokenType"]).to eq("Bearer")
  end

  it "rejects invalid credentials" do
    post "/api/auth", params: { rnc: "101234567", usuario: "x", password: "y" }
    expect(response).to have_http_status(:unauthorized)
  end
end
