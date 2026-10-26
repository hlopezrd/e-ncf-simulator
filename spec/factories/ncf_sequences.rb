FactoryBot.define do
  factory :ncf_sequence do
    rnc { "MyString" }
    tipo { 1 }
    desde { 1 }
    hasta { 1 }
    fecha_vencimiento { "2026-10-26" }
    activa { false }
  end
end
