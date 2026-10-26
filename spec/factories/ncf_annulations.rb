FactoryBot.define do
  factory :ncf_annulation do
    rnc_emisor { "MyString" }
    cantidad_anulados { 1 }
    fecha_hora_anulacion { "2026-10-26 08:41:02" }
    xml_content { "MyText" }
  end
end
