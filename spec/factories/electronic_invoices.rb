FactoryBot.define do
  factory :electronic_invoice do
    track_id { "MyString" }
    rnc_emisor { "MyString" }
    encf { "MyString" }
    tipo_comprobante { "MyString" }
    fecha_emision { "2026-10-23" }
    xml_content { "MyText" }
    estado { "MyString" }
    fecha_recepcion { "2026-10-23 08:48:07" }
  end
end
