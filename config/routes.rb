Rails.application.routes.draw do
  get "/health", to: "health#show"

  post "/api/auth", to: "api/auth#create"

  post "/api/recepcion", to: "api/recepcion#create"

  get "/api/consulta-estado/:track_id", to: "api/consulta_estado#show"

  get "/api/trackids/consulta", to: "api/trackids#consulta"

  scope "/api" do
    resources :ecf, only: [ :index, :show ], param: :track_id, controller: "api/ecfs"
    resources :empresas, only: [ :index ], controller: "api/empresas"
    resources :certificados, only: [ :index ], controller: "api/certificados"
    resources :validaciones, only: [ :index ], controller: "api/validaciones"
    resources :reglas, only: [ :index ], controller: "api/reglas"
    resources :allowed_origins, only: [ :index, :create, :destroy ], controller: "api/allowed_origins"
    resources :simulation_rules, only: [ :index, :create, :update, :destroy ], controller: "api/simulation_rules"
    resources :usuarios, only: [ :index ], controller: "api/usuarios"
    resources :auditoria, only: [ :index ], controller: "api/auditoria"
  end
end
