FactoryBot.define do
  factory :validation_error do
    electronic_invoice { nil }
    codigo { "MyString" }
    campo { "MyString" }
    mensaje { "MyText" }
    severidad { "MyString" }
  end
end
