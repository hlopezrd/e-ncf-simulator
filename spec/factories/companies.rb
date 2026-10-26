FactoryBot.define do
  factory :company do
    rnc { "101234567" }
    razon_social { "Empresa de Prueba SRL" }
    nombre_comercial { "Empresa de Prueba" }
    email { "contacto@empresa.test" }
    telefono { "809-555-0000" }
    activa { true }
  end
end
