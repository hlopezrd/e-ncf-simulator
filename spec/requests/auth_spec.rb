require "rails_helper"

RSpec.describe "Auth", type: :request do
  before do
    role = Role.find_or_create_by!(name: "admin") { |r| r.description = "Administrador" }
    User.find_or_create_by!(rnc: "101234567", username: "usuario-prueba") do |u|
      u.name = "usuario-prueba"
      u.email = "usuario-prueba@sim.local"
      u.role = role
      u.active = true
      u.password = "password-prueba"
    end
  end

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
