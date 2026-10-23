FactoryBot.define do
  factory :auth_token do
    token { "MyString" }
    rnc { "MyString" }
    expires_at { "2026-10-23 08:48:04" }
  end
end
