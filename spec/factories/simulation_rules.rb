FactoryBot.define do
  factory :simulation_rule do
    name { "MyString" }
    description { "MyText" }
    rule_type { "MyString" }
    active { false }
    value { "MyString" }
  end
end
