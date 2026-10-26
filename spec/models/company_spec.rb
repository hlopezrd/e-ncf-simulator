require "rails_helper"

RSpec.describe Company, type: :model do
  def build_company(attrs = {})
    Company.new({ rnc: "101234567", razon_social: "Empresa de Prueba SRL" }.merge(attrs))
  end

  it "es válido con atributos válidos" do
    expect(build_company).to be_valid
  end

  it "requiere rnc" do
    c = build_company(rnc: nil)
    expect(c).not_to be_valid
  end

  it "valida formato de rnc (9 u 11 dígitos)" do
    expect(build_company(rnc: "123")).not_to be_valid
    expect(build_company(rnc: "123456789")).to be_valid
    expect(build_company(rnc: "12345678901")).to be_valid
  end

  it "requiere rnc único" do
    Company.create!(rnc: "999999999", razon_social: "X")
    dup = build_company(rnc: "999999999")
    expect(dup).not_to be_valid
  end

  it "soft-delete con paranoia" do
    c = Company.create!(rnc: "888888888", razon_social: "Y")
    c.destroy
    expect(Company.find_by(id: c.id)).to be_nil
    expect(Company.with_deleted.find_by(id: c.id)).to be_present
  end

  it "tiene asociaciones" do
    c = Company.new(rnc: "777777777")
    expect(c).to respond_to(:certificates, :ncf_sequences, :users, :electronic_invoices)
  end
end
