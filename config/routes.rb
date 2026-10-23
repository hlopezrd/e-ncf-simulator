Rails.application.routes.draw do
  get "/health", to: "health#show"

  post "/api/auth", to: "api/auth#create"

  post "/api/recepcion", to: "api/recepcion#create"

  get "/api/consulta-estado/:track_id", to: "api/consulta_estado#show"

  get "/api/trackids/consulta", to: "api/trackids#consulta"

  scope "/api" do
    resources :ecf, only: [:index, :show], param: :track_id, controller: "api/ecfs"
    resources :empresas, only: [:index], controller: "api/empresas"
  end
end
