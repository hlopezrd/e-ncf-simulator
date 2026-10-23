FactoryBot.define do
  factory :certificate do
    rnc { "MyString" }
    alias_name { "MyString" }
    subject { "MyString" }
    issuer { "MyString" }
    serial { "MyString" }
    not_before { "2026-10-23 12:59:24" }
    not_after { "2026-10-23 12:59:24" }
    thumbprint { "MyString" }
  end
end
