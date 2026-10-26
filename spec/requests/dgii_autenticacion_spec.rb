require "rails_helper"
require "base64"

RSpec.describe "DGII Autenticación", type: :request do
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
    NcfSequence.find_or_create_by!(rnc: "101234567", tipo: 31, desde: 1, hasta: 999999) do |s|
      s.fecha_vencimiento = Date.current + 365
      s.activa = true
    end
  end

  it "returns a semilla XML" do
    get "/testecf/autenticacion/api/autenticacion/semilla"
    expect(response).to have_http_status(:ok)
    expect(response.content_type).to include("application/xml")
    expect(response.body).to include("<SemillaModel>")
    expect(response.body).to include("<valor>")
    expect(response.body).to include("<fecha>")
  end

  it "issues a token for a signed seed" do
    get "/testecf/autenticacion/api/autenticacion/semilla"
    seed = response.body
    signed = Ecfs::CryptoService.sign(seed)

    post "/testecf/autenticacion/api/autenticacion/validarsemilla",
         params: { xml: signed }

    expect(response).to have_http_status(:ok)
    json = JSON.parse(response.body)
    expect(json["token"]).to be_present
    expect(json["expira"]).to be_present
    expect(json["expedido"]).to be_present
  end

  it "rejects a reused seed" do
    get "/testecf/autenticacion/api/autenticacion/semilla"
    seed = response.body
    signed = Ecfs::CryptoService.sign(seed)

    post "/testecf/autenticacion/api/autenticacion/validarsemilla", params: { xml: signed }
    expect(response).to have_http_status(:ok)

    post "/testecf/autenticacion/api/autenticacion/validarsemilla", params: { xml: signed }
    expect(response).to have_http_status(:unauthorized)
  end

  it "rejects an unsigned seed" do
    get "/testecf/autenticacion/api/autenticacion/semilla"
    seed = response.body

    post "/testecf/autenticacion/api/autenticacion/validarsemilla", params: { xml: seed }
    expect(response).to have_http_status(:unauthorized)
  end
end
