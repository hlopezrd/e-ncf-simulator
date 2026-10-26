Rails.application.routes.draw do
  get "/health", to: "health#show"

  post "/api/auth", to: "api/auth#create"
  delete "/api/auth", to: "api/auth#destroy"
  get "/api/me", to: "api/me#show"

  post "/api/recepcion", to: "api/recepcion#create"

  get "/api/consulta-estado/:track_id", to: "api/consulta_estado#show"

  get "/api/trackids/consulta", to: "api/trackids#consulta"

  scope "/api" do
    resources :ecf, only: [ :index, :show ], param: :track_id, controller: "api/ecfs"
    resources :empresas, only: [ :index, :show, :create, :update, :destroy ], controller: "api/empresas" do
      member do
        post :certificados
        post :ncf_sequences
        get :estado_onboarding
      end
    end
    resources :validaciones, only: [ :index ], controller: "api/validaciones"
    resources :reglas, only: [ :index, :create, :update, :destroy ], controller: "api/reglas"
    resources :allowed_origins, only: [ :index, :create, :destroy ], controller: "api/allowed_origins"
    resources :simulation_rules, only: [ :index, :create, :update, :destroy ], controller: "api/simulation_rules"
    resources :usuarios, only: [ :index, :create, :update, :destroy ], controller: "api/usuarios"
    resources :roles, only: [ :index ], controller: "api/roles"
    resources :auditoria, only: [ :index ], controller: "api/auditoria"
    resources :certificados, only: [ :index, :create, :update, :destroy ], controller: "api/certificados"
  resources :ncf_sequences, only: [ :index, :create, :update, :destroy ], controller: "api/ncf_sequences"
  end

  # DGII-compatible endpoints (Fase 1: autenticación por semilla)
  dgii_auth_routes = lambda do |prefix|
    scope prefix do
      get "autenticacion/api/autenticacion/semilla", to: "api/dgii/autenticacion#semilla"
    get "autenticacion/api/autenticacion/certificado", to: "api/dgii/autenticacion#certificado"
    post "autenticacion/api/autenticacion/validarsemilla", to: "api/dgii/autenticacion#validar_semilla"
      post "recepcion/api/facturaselectronicas", to: "api/dgii/recepcion#create"
      get "consultaresultado/api/Consultas/Estado", to: "api/dgii/consultas#resultado"
      get "consultaestado/api/Consultas/Estado", to: "api/dgii/consultas#estado"
      get "consultatrackids/api/TrackIds/Consulta", to: "api/dgii/consultas#track_ids"
      post "aprobacioncomercial/api/AprobacionComercial", to: "api/dgii/aprobacion_comercial#create"
      post "anulacionrangos/api/operaciones/anularrango", to: "api/dgii/anulacion#create"
      post "recepcionfc/api/recepcion/ecf", to: "api/dgii/resumen#create"
      get "consultadirectorio/api/consultas/obtenerdirectorioporrnc", to: "api/dgii/directorio#obtener_por_rnc"
      get "consultadirectorio/api/consultas/listado", to: "api/dgii/directorio#listado"
      get "api/estatusservicios/obtenerestatus", to: "api/dgii/estatus#obtener_estatus"
      get "api/estatusservicios/obtenerventanasmantenimiento", to: "api/dgii/estatus#ventanas_mantenimiento"
      get "api/estatusservicios/verificarestado", to: "api/dgii/estatus#verificar_estado"
    end
  end
  dgii_auth_routes.call("/testecf")
  dgii_auth_routes.call("/certecf")
  dgii_auth_routes.call("/ecf")
  dgii_auth_routes.call("")

  # Serve the React SPA (must be last)
  dgii_roots = %w[/autenticacion /recepcion /consultaresultado /consultaestado /consultatrackids /aprobacioncomercial /anulacionrangos /recepcionfc /consultarfce /consultadirectorio]
  get "*path", to: "frontend#index", constraints: ->(req) {
    p = req.path
    return false if p.start_with?("/api", "/health")
    return false if p.start_with?("/testecf/", "/certecf/")
    return false if dgii_roots.any? { |r| p == r || p.start_with?("#{r}/") }
    return false if p.start_with?("/ecf/") && dgii_roots.any? { |r| p.start_with?("/ecf#{r}/") }
    true
  }
end
