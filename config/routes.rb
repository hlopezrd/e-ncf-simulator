Rails.application.routes.draw do
  get "/health", to: "health#show"

  post "/api/auth", to: "api/auth#create"

  post "/api/recepcion", to: "api/recepcion#create"

  get "/api/consulta-estado/:track_id", to: "api/consulta_estado#show"

  get "/api/trackids/consulta", to: "api/trackids#consulta"
end
