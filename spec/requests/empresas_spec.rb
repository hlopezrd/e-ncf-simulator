require "rails_helper"

RSpec.describe "Empresas", type: :request do
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

  let(:token) do
    post "/api/auth", params: { rnc: "101234567", usuario: "usuario-prueba", password: "password-prueba" }
    JSON.parse(response.body)["token"]
  end

  let(:headers) { { "Authorization" => "Bearer #{token}" } }

  it "actualiza todos los campos editables sin cambiar el RNC" do
    company = Company.create!(rnc: "400000002", razon_social: "Razón anterior", activa: true)

    patch "/api/empresas/#{company.id}", params: {
      rnc: "999999999",
      razon_social: "Razón nueva",
      nombre_comercial: "Nombre comercial",
      email: "facturacion@example.com",
      telefono: "8095550000",
      activa: false
    }, headers: headers

    expect(response).to have_http_status(:ok)
    data = JSON.parse(response.body)["data"]
    expect(data).to include(
      "rnc" => "400000002",
      "razonSocial" => "Razón nueva",
      "nombreComercial" => "Nombre comercial",
      "email" => "facturacion@example.com",
      "telefono" => "8095550000",
      "activa" => false
    )
    expect(company.reload.attributes).to include(
      "rnc" => "400000002",
      "razon_social" => "Razón nueva",
      "nombre_comercial" => "Nombre comercial",
      "email" => "facturacion@example.com",
      "telefono" => "8095550000",
      "activa" => false
    )
  end

  it "permite crear de nuevo una empresa después de eliminarla (soft delete)" do
    post "/api/empresas", params: { rnc: "400000003", razon_social: "Primera" }, headers: headers
    expect(response).to have_http_status(:created)
    first_id = JSON.parse(response.body)["data"]["id"]

    delete "/api/empresas/#{first_id}", headers: headers
    expect(response).to have_http_status(:ok)
    expect(Company.find_by(rnc: "400000003")).to be_nil

    post "/api/empresas", params: { rnc: "400000003", razon_social: "Segunda" }, headers: headers

    expect(response).to have_http_status(:created)
    expect(JSON.parse(response.body)["data"]["razonSocial"]).to eq("Segunda")
    expect(Company.unscoped.where(rnc: "400000003").count).to eq(2)
  end

  it "rechaza con 422 un RNC activo duplicado" do
    Company.create!(rnc: "400000004", razon_social: "Existente")

    post "/api/empresas", params: { rnc: "400000004", razon_social: "Duplicada" }, headers: headers

    expect(response).to have_http_status(:unprocessable_entity)
    expect(JSON.parse(response.body)["errors"]).to be_present
  end
end
