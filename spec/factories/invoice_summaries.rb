FactoryBot.define do
  factory :invoice_summary do
    rnc_emisor { "MyString" }
    encf { "MyString" }
    codigo { 1 }
    estado { "MyString" }
    secuencia_utilizada { false }
    xml_content { "MyText" }
  end
end
