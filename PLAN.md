# Plan de implementación — Simulador local de e-CF (DGII RD)

## Estado de implementación

- [x] Estructura del proyecto (Rails 8 API)
- [x] Gemfile (sin PostgreSQL/Redis/Sidekiq/Docker en v1; Kamal/Docker añadido después para deploy)
- [x] Migraciones (auth_tokens, electronic_invoices, validation_errors) con índices y unique compuesto
- [x] Modelos (AuthToken, ElectronicInvoice, ValidationError)
- [x] Servicios (Auth::TokenService, Ecfs::ReceiveService, Ecfs::ValidateXmlService, Ecfs::StatusQueryService)
- [x] Controladores y rutas (health, auth, recepcion, consulta-estado, trackids)
- [x] Serializers/respuestas JSON claras
- [x] Fixtures XML
- [x] Request specs (14 casos) — todos pasan
- [x] README con comandos y ejemplos curl
- [x] Logging estructurado JSON + GUID de error para trazabilidad
- [x] Kamal + Dockerfile preparados para deploy
- [x] Validación XSD completa (hook implementado, activado por defecto; schemas en lib/xsd/)
- [ ] Firma digital real
- [ ] Panel administrativo / integración externa

## 1. Objetivo

Construir un simulador local (sin conexión real a la DGII) de los servicios de recepción y consulta de Comprobantes Fiscales Electrónicos (e-CF) de República Dominicana, con API REST en Rails 8 (modo API), SQLite, RSpec, Nokogiri y UUID para TrackId.

No debe afirmar validez fiscal. Solo imita el flujo técnico.

## 2. Stack y restricciones

- Rails 8.0 API mode
- Ruby 3.4
- SQLite (gem `sqlite3`)
- RSpec + FactoryBot + shoulda-matchers (opcional)
- Nokogiri para parseo/validación XML
- UUID v4 (`SecureRandom.uuid`)
- Sin PostgreSQL, Redis, Sidekiq, Docker
- Sin firma digital real
- Sin validación XSD completa (dejar hooks/preparación)

## 3. Estructura del proyecto

```
e-cf-simulator/
├── Gemfile
├── config/
│   ├── routes.rb
│   ├── database.yml          # sqlite3
│   └── initializers/
├── app/
│   ├── controllers/
│   │   └── api/
│   │       ├── health_controller.rb
│   │       ├── auth_controller.rb
│   │       ├── recepcion_controller.rb
│   │       ├── consulta_estado_controller.rb
│   │       └── trackids_controller.rb
│   ├── models/
│   │   ├── auth_token.rb
│   │   ├── electronic_invoice.rb
│   │   └── validation_error.rb  (POR CLARIFICAR: ver nota)
│   ├── services/
│   │   ├── auth/token_service.rb
│   │   └── ecfs/
│   │       ├── receive_service.rb
│   │       ├── validate_xml_service.rb
│   │       └── status_query_service.rb
│   └── serializers/ (opcional, respuestas manuales en controladores)
├── db/
│   ├── migrate/
│   │   ├── xxx_create_auth_tokens.rb
│   │   ├── xxx_create_electronic_invoices.rb
│   │   └── xxx_create_validation_errors.rb
│   └── seeds.rb
├── spec/
│   ├── requests/
│   │   ├── health_spec.rb
│   │   ├── auth_spec.rb
│   │   ├── recepcion_spec.rb
│   │   ├── consulta_estado_spec.rb
│   │   └── trackids_spec.rb
│   ├── models/
│   └── services/
├── fixtures/xml/
│   ├── valido.xml
│   ├── mal_formado.xml
│   ├── sin_rnc.xml
│   ├── sin_encf.xml
│   └── encf_invalido.xml
├── README.md
└── .rspec
```

### Nota sobre ValidationError

El prompt pide "ValidationError" como modelo. Opciones:
- (A) Modelo persistente asociado a ElectronicInvoice (tabla `validation_errors`) para guardar errores por comprobante.
- (B) Value object / PORO usado en respuestas.

Recomendación: implementar como modelo ActiveRecord asociado a `electronic_invoice` (has_many :validation_errors) para poder auditar y consultar errores históricos; además usarlo como PORO en el servicio de validación. La tabla almacena errores de validación por comprobante. Esto cumple "Crea únicamente: 1. AuthToken 2. ElectronicInvoice 3. ValidationError" y "Agrega migraciones, índices y validaciones."

## 4. Modelos y migraciones

### AuthToken
- id (PK)
- token (string, unique, indexed)
- rnc (string)
- expires_at (datetime)
- created_at, updated_at
- Validaciones: presence token, presence rnc, uniqueness token.

### ElectronicInvoice
- id (PK)
- track_id (string, unique, indexed)
- rnc_emisor (string, indexed)
- encf (string, indexed)
- tipo_comprobante (string)
- fecha_emision (date/datetime)
- xml_content (text)
- estado (string) — enum-like: "En Proceso", "Aceptado", "Aceptado Condicional", "Rechazado"
- fecha_recepcion (datetime)
- created_at, updated_at
- Índice único compuesto: (rnc_emisor, encf)
- Validaciones: presence track_id, rnc_emisor, encf, estado, fecha_recepcion; uniqueness track_id; uniqueness [rnc_emisor, encf].
- has_many :validation_errors, dependent: :destroy

### ValidationError
- id (PK)
- electronic_invoice_id (FK, indexed)
- codigo (string) — ej. E001
- campo (string) — ej. eNCF
- mensaje (text)
- severidad (string) — ERROR / WARNING
- created_at, updated_at
- Validaciones: presence codigo, campo, mensaje, severidad.

## 5. Autenticación

`POST /api/auth`
- Body: { rnc, usuario, password }
- Credenciales válidas únicas: RNC 101234567 / usuario-prueba / password-prueba
- Si válidas: crear AuthToken con token "sim-token-<valor>" (valor = SecureRandom.hex o UUID), expires_at = now + 3600s. Respuesta { token, expiresIn: 3600, tokenType: "Bearer" }.
- Si inválidas: 401 { error }.
- Token validation: middleware/concern `AuthenticateRequest` que busca AuthToken por token, verifica no expirado. Si inválido/expirado -> 401.

`<valor>`: usar SecureRandom.hex(16) o UUID sin guiones. Formato final: "sim-token-<valor>".

## 6. Servicios

### Auth::TokenService
- `authenticate(rnc:, usuario:, password:)` -> AuthToken o nil/raise
- `issue_token(rnc:)` -> AuthToken
- `valid?(token)` -> boolean (existe y no expirado)

### Ecfs::ValidateXmlService
Input: string xml.
Output: result object con:
- `valid?` (boolean)
- `errors` (array de hashes { codigo, campo, mensaje, severidad })
- `warnings` (array)
- `parsed` (Nokogiri doc) o nil
- `rnc_emisor`, `encf`, `tipo_comprobante`, `fecha_emision`, `totales` extraídos
- `duplicate?` (verificado por servicio de recepción contra BD)

Validaciones mínimas:
1. Presencia de xml (no vacío) -> E001? definir códigos.
2. XML bien formado (Nokogiri parse sin errors) -> E002
3. Nodo raíz presente -> E003
4. RNC emisor presente -> E004
5. e-NCF presente -> E005
6. e-NCF comienza con "E" -> E006
7. Tipo de comprobante presente -> E007
8. Fecha de emisión presente -> E008
9. Totales presentes -> E009
10. Duplicado (rnc+encf) -> E010 (warning o error crítico? prompt dice "Que el XML no sea duplicado" como validación; duplicado debe rechazar con 422 probablemente. Tratar como error crítico.)

Códigos sugeridos:
- E001 XML_VACIO
- E002 XML_MAL_FORMADO
- E003 ROOT_MISSING
- E004 RNC_MISSING
- E005 ENCF_MISSING
- E006 ENCF_INVALID (no empieza con E)
- E007 TIPO_MISSING
- E008 FECHA_MISSING
- E009 TOTALES_MISSING
- E010 DUPLICATE

XPaths a definir según estructura e-CF. DGII e-CF típico:
```
<ECF>
  <Encabezado>
    <Version>1.0</Version>
    <IdDoc>
      <TipoeCF>31</TipoeCF>
      <eNCF>E310000000001</eNCF>
      <FechaEmision>...</FechaEmision>
    </IdDoc>
    <Emisor>
      <RNCEmisor>101234567</RNCEmisor>
      ...
    </Emisor>
  </Encabezado>
  <Totales>
    <MontoTotal>...</MontoTotal>
  </Totales>
</ECF>
```
Pero para el simulador, hacer búsqueda flexible: buscar por nombre de elemento en todo el documento (descendant) para rnc emisor, encf, tipo, fecha, totales. Así fixtures simples funcionan.

Implementar extracción con XPath genérico:
- rnc_emisor: `//RNCEmisor | //RncEmisor | //rncEmisor` (first)
- encf: `//eNCF | //ENCF | //encf`
- tipo: `//TipoeCF | //TipoECF | //tipoComprobante`
- fecha: `//FechaEmision | //fechaEmision`
- totales: presencia de nodo `Totales` o `Total` o elementos `MontoTotal`.

Warnings: si algún campo opcional falta pero no crítico. Para primera versión, solo errores críticos; warnings vacío por defecto, pero permitir "Aceptado Condicional" si hay warnings. Podemos generar warnings cuando, por ejemplo, falta algún campo no crítico. Para tests, XML válido -> Aceptado; XML válido con advertencias -> Aceptado Condicional. Necesitamos un fixture/caso que genere warning. Definir warning por ejemplo si fecha de emisión está en el futuro o monto total <= 0? O si falta campo opcional como "RNCComprador"? 

Simplificar: warning si no hay RNC comprador o si total es 0. Pero tests solo piden estados. Para cubrir "Aceptado Condicional", agregar validación de warning: por ejemplo, si el XML no contiene nodo `<Detalle>` o falta RNCComprador. Mejor: warning si falta `RNCComprador` (comprador). Así un XML válido sin comprador -> condicional. Pero tests de "XML válido" deben incluir comprador para ser Aceptado. Ajustar fixtures.

Alternativa más simple y controlable: warning si el monto total es 0 o negativo, o si falta fecha de vencimiento. Decisión final: warning si no existe `RNCComprador` (o `RncComprador`). Fixtures: válido incluye comprador.

### Ecfs::ReceiveService
- Input: xml string, token (o rnc del token)
- Flow:
  1. Validar token (ya en controller, pero servicio puede recibir rnc_emisor esperado? No, extraer del xml).
  2. Llamar ValidateXmlService.
  3. Si errores críticos -> retornar failure con errores, estado Rechazado? Prompt: XML inválido -> Rechazado. Pero recepción de XML inválido devuelve 422 con errores y NO guarda? Prompt dice "Si el XML tiene errores críticos, devuelve HTTP 422". No especifica guardar. Recomendación: no guardar comprobante inválido (o guardar con estado Rechazado). Para simplicidad y tests, no persistir inválidos; pero estado "Rechazado" debe existir para consulta? Solo si se guardó. 

Decisión: Para XML inválido, devolver 422 sin persistir. Para duplicado, 422 con error E010. Para válido, persistir con estado inicial "En Proceso", luego cambiar a "Aceptado" (o "Aceptado Condicional" si warnings) inmediatamente. Devolver respuesta.

  4. Verificar duplicado por rnc_emisor+encf antes de guardar; si existe -> 422 E010.
  5. Generar track_id = SecureRandom.uuid.
  6. Crear ElectronicInvoice con estado "En Proceso", fecha_recepcion now.
  7. Actualizar estado a final ("Aceptado" / "Aceptado Condicional").
  8. Crear ValidationError records para errores/warnings? Guardar warnings como ValidationError con severidad WARNING. Errores críticos no se persisten porque no se guarda. Para válidos con warnings, guardar warnings.
  9. Retornar { track_id, codigo: "0", mensaje, fecha_recepcion }.

- Retorno: Result struct con `success?`, `status_code`, `payload`, `errors`.

### Ecfs::StatusQueryService
- `by_track_id(track_id)` -> ElectronicInvoice o nil; arma respuesta.
- `by_rnc_encf(rnc, encf)` -> ElectronicInvoice o nil; arma respuesta (con estado "No Encontrado" si nil).

## 7. Controladores y rutas

```ruby
Rails.application.routes.draw do
  get '/health', to: 'health#show'
  post '/api/auth', to: 'api/auth#create'
  post '/api/recepcion', to: 'api/recepcion#create'
  get '/api/consulta-estado/:track_id', to: 'api/consulta_estado#show'
  get '/api/trackids/consulta', to: 'api/trackids#consulta'
end
```

Concern `Authenticatable` en ApplicationController o base Api::BaseController.

## 8. Respuestas

Health: `{ status: "ok", service: "e-cf-simulator", timestamp: ... }` con 200.

Auth success: `{ token:, expiresIn: 3600, tokenType: "Bearer" }`.

Recepción success: `{ trackId:, codigo: "0", mensaje: "e-CF recibido correctamente", fechaRecepcion: }`.

Recepción error 422: `{ codigo: "VALIDATION_ERROR", mensaje: "El e-CF contiene errores de validación", errores: [ { codigo, campo, mensaje, severidad } ] }`.

Consulta estado: `{ trackId:, estado:, rncEmisor:, eNCF:, fechaRecepcion:, codigo: "0", mensaje:, errores: [], advertencias: [] }`.

Consulta trackids: `{ trackId:, estado:, fechaRecepcion:, rncEmisor:, eNCF: }` o `{ trackId: null, estado: "No Encontrado", mensaje: }`.

## 9. Pruebas RSpec (14 casos)

1. GET /health -> 200.
2. Auth exitosa -> 200 + token.
3. Auth fallida -> 401.
4. Request sin token a endpoint protegido -> 401.
5. XML válido -> 201/200 + trackId, estado Aceptado.
6. XML mal formado -> 422.
7. XML sin RNC -> 422 E004.
8. XML sin e-NCF -> 422 E005.
9. e-NCF inválido -> 422 E006.
10. Comprobante duplicado -> 422 E010.
11. Consulta por TrackId -> 200.
12. TrackId inexistente -> 404.
13. Consulta por RNC y e-NCF -> 200.
14. RNC y e-NCF inexistentes -> 200 con No Encontrado (o 404? Prompt dice devuelve objeto con null; usar 200).

Adicionales recomendados: XML válido con advertencias -> Aceptado Condicional; token expirado.

## 10. Fixtures XML

Crear en spec/fixtures/files o spec/support/fixtures/xml. Ejemplos mínimos:

valido.xml:
```xml
<ECF>
  <Encabezado>
    <IdDoc>
      <TipoeCF>31</TipoeCF>
      <eNCF>E310000000001</eNCF>
      <FechaEmision>2026-10-23</FechaEmision>
    </IdDoc>
    <Emisor>
      <RNCEmisor>101234567</RNCEmisor>
    </Emisor>
    <Comprador>
      <RNCComprador>101987654</RNCComprador>
    </Comprador>
  </Encabezado>
  <Totales>
    <MontoTotal>1000.00</MontoTotal>
  </Totales>
</ECF>
```

mal_formado.xml: `<ECF><Encabezado>...` sin cerrar.

sin_rnc.xml: omitir RNCEmisor.

sin_encf.xml: omitir eNCF.

encf_invalido.xml: eNCF = "310000000001" (sin E).

valido_condicional.xml: omitir RNCComprador (genera warning).

## 11. Gemfile

```ruby
source 'https://rubygems.org'
ruby '3.4.12' # o ~> 3.4

gem 'rails', '~> 8.0.0'
gem 'sqlite3', '>= 2.1'
gem 'nokogiri', '~> 1.18'
gem 'puma'
gem 'bootsnap', require: false
gem 'tzinfo-data', platforms: %i[windows jruby]

group :development, :test do
  gem 'rspec-rails', '~> 7.1'
  gem 'factory_bot_rails'
  gem 'shoulda-matchers'
  gem 'faker'
end

group :test do
  gem 'database_cleaner-active_record'
end
```

## 12. Comandos de ejecución

```bash
bundle install
bin/rails db:create db:migrate
bundle exec rspec
bin/rails server  # http://localhost:3000
```

## 13. Ejemplos curl

```bash
# Health
curl http://localhost:3000/health

# Auth
curl -X POST http://localhost:3000/api/auth \
  -H 'Content-Type: application/json' \
  -d '{"rnc":"101234567","usuario":"usuario-prueba","password":"password-prueba"}'

# Recepción
TOKEN=...
curl -X POST http://localhost:3000/api/recepcion \
  -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{"xml":"<ECF>...</ECF>"}'

# Consulta estado
curl -H "Authorization: Bearer $TOKEN" http://localhost:3000/api/consulta-estado/<track_id>

# Consulta por RNC/eNCF
curl -H "Authorization: Bearer $TOKEN" \
  "http://localhost:3000/api/trackids/consulta?rncemisor=101234567&encf=E310000000001"
```

## 14. Preparación para XSD futuro

- En ValidateXmlService, dejar método `validate_xsd!(doc)` que por ahora retorna [] (sin validación) y un flag `XSD_VALIDATION_ENABLED = false`. Cuando se active, usar Nokogiri::XML::Schema.
- Estructura de errores ya soporta códigos; agregar nuevos códigos XSD (X001..) sin romper API.

## 15. Orden de implementación sugerido

1. `rails new e-cf-simulator --api --skip-docker --database=sqlite3` (en directorio vacío; ajustar).
2. Gemfile + bundle install.
3. Configurar RSpec (rails g rspec:install).
4. Migraciones + modelos.
5. Servicios (ValidateXmlService primero).
6. Controladores + rutas.
7. Fixtures XML.
8. Request specs.
9. README.

## Lo que falta (por diseño o futuro)

- Validación XSD completa (hook `XSD_VALIDATION_ENABLED` listo; falta incorporar schemas oficiales).
- Firma digital real (criptografía).
- Deploy real con Kamal (falta servidor destino, registry y secretos).
- Limpieza automática de tokens expirados (no requerido en v1).
- Model specs (opcional; se eliminaron placeholders pendientes).
- Tests de servicio unitarios (opcional; cubierto por request specs).

## 16. Riesgos / decisiones

- Parseo de XML con Nokogiri: usar `Nokogiri::XML(xml) { |config| config.strict }` para detectar mal formado; capturar `Nokogiri::XML::SyntaxError`.
- Duplicado: índice único a nivel BD + validación en servicio; manejar `ActiveRecord::RecordNotUnique` -> 422 E010.
- Token: almacenar en BD para poder validar; limpieza de expirados no necesaria en v1.
- Concurrencia: no aplica (simulador local).

---

¿Procedo a implementar el proyecto completo siguiendo este plan?
