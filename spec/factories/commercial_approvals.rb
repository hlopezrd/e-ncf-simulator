FactoryBot.define do
  factory :commercial_approval do
    rnc_emisor { "MyString" }
    rnc_comprador { "MyString" }
    encf { "MyString" }
    estado { 1 }
    motivo_rechazo { "MyString" }
    fecha_hora_aprobacion { "2026-10-26 08:40:59" }
    xml_content { "MyText" }
  end
end
