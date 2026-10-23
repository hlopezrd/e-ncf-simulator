# e-CF Simulator (DGII RD) — Local Simulator

Simulador local de los servicios de recepción y consulta de Comprobantes Fiscales Electrónicos (e-CF) de la DGII de República Dominicana.

> **Aviso:** Este es únicamente un simulador local. No se conecta a la DGII real y sus respuestas NO tienen validez fiscal.

## Stack

- Rails 8.0 (API mode)
- Ruby 3.4
- SQLite
- RSpec
- Nokogiri
- UUID (SecureRandom)

## Instalación

```bash
bundle install
bin/rails db:create db:migrate
```

## Ejecutar

```bash
bin/rails server   # http://localhost:3000
```

## Pruebas

```bash
bundle exec rspec
```

## Endpoints

- `GET /health`
- `POST /api/auth`
- `POST /api/recepcion`
- `GET /api/consulta-estado/:track_id`
- `GET /api/trackids/consulta?rncemisor=:rnc&encf=:encf`

## Ejemplos curl

```bash
# Health
curl http://localhost:3000/health

# Auth
curl -X POST http://localhost:3000/api/auth \
  -H 'Content-Type: application/json' \
  -d '{"rnc":"101234567","usuario":"usuario-prueba","password":"password-prueba"}'

# Recepción
TOKEN=$(curl -s -X POST http://localhost:3000/api/auth \
  -H 'Content-Type: application/json' \
  -d '{"rnc":"101234567","usuario":"usuario-prueba","password":"password-prueba"}' | ruby -rjson -e 'puts JSON.parse(STDIN.read)["token"]')

curl -X POST http://localhost:3000/api/recepcion \
  -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{"xml":"<ECF><Encabezado><IdDoc><TipoeCF>31</TipoeCF><eNCF>E310000000001</eNCF><FechaEmision>2026-10-23</FechaEmision></IdDoc><Emisor><RNCEmisor>101234567</RNCEmisor></Emisor><Comprador><RNCComprador>101987654</RNCComprador></Comprador></Encabezado><Totales><MontoTotal>1000.00</MontoTotal></Totales></ECF>"}'

# Consulta por TrackId
curl -H "Authorization: Bearer $TOKEN" http://localhost:3000/api/consulta-estado/<TRACK_ID>

# Consulta por RNC y e-NCF
curl -H "Authorization: Bearer $TOKEN" \
  "http://localhost:3000/api/trackids/consulta?rncemisor=101234567&encf=E310000000001"
```

## Logging y trazabilidad

- Logs estructurados en JSON a STDOUT (ideal para Kamal/Docker).
- Cada request tiene un `request_id` (header `X-Request-Id` y campo `request_id` en respuestas).
- Los errores 500 generan un `error_id` (GUID) que se devuelve al cliente y se registra en los logs junto con el `request_id`, clase de excepción, mensaje y backtrace.

## Deploy con Kamal

Configuración preparada en `config/deploy.yml` y `Dockerfile`.

Pasos (cuando tengas servidor y registry):

```bash
# Configurar secretos
cp .kamal/secrets.example .kamal/secrets  # si aplica
# Editar config/deploy.yml: service, image, servers, registry, proxy host

# Primer deploy
bin/kamal setup
bin/kamal deploy
```

Secretos requeridos en `.kamal/secrets`: `KAMAL_REGISTRY_PASSWORD`, `RAILS_MASTER_KEY`.

## Credenciales de prueba

- RNC: `101234567`
- Usuario: `usuario-prueba`
- Password: `password-prueba`

## Notas

- Validación XSD disponible. Schemas oficiales en `lib/xsd/`. Activada por defecto en producción (deploy.yml); en desarrollo/tests se activa con `XSD_VALIDATION_ENABLED=true`.
- Firma digital no implementada (simulada).
- No incluye Docker, Redis, Sidekiq ni PostgreSQL.