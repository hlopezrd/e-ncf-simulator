# e-CF Simulator (DGII RD) — Local Simulator

Simulador local de los servicios de recepción y consulta de Comprobantes Fiscales Electrónicos (e-CF) de la DGII de República Dominicana.

> **Aviso:** Este es únicamente un simulador local. No se conecta a la DGII real y sus respuestas NO tienen validez fiscal.

**Glosario:** ver [`docs/GLOSSARY.md`](docs/GLOSSARY.md) para definiciones de emisor/comprador, tipos de NCF, documentos (ARECF, ACECF, ANECF, RFCE) y códigos de error.
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

### Backend

```bash
bin/rails server -p 13000   # http://localhost:13000
```

### Frontend (portal admin)

```bash
cd frontend
yarn install
yarn dev   # http://localhost:5173 (proxy a Rails en 13000)
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

## Calidad y análisis estático

```bash
bundle exec rspec
bundle exec rubocop
bundle exec fasterer
bundle exec brakeman -q
```

- Bullet habilitado en desarrollo (solo notificación, no lanza errores).

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

## Crear el primer usuario administrador

No existen credenciales hardcodeadas. Crea el primer admin con:

```bash
rails users:create ADMIN_RNC=101234567 ADMIN_USER=admin ADMIN_PASSWORD=changeme ADMIN_EMAIL=admin@sim.local
```

Luego inicia sesión con ese usuario. Los usuarios adicionales se crean desde el portal admin.

## Entorno de producción

El entorno de producción del simulador es:

- URL: https://sim.ecfgateway.com
- Deploy: Kamal (Docker) sobre el servidor `tempest` (108.181.196.247).
- Proxy: kamal-proxy compartido con staging.ecfgateway.com.
- DNS: Cloudflare, registro `A sim → 108.181.196.247` (DNS only).
- Certificado: Let's Encrypt (gestionado por Kamal).

Aunque se denomina "producción", sigue siendo un **simulador sin validez fiscal**. No se conecta a la DGII real.

## Certificados en producción (importante)

El directorio `config/certs/` está en `.gitignore` y **no se incluye en la imagen Docker**. `Ecfs::CryptoService` genera un certificado self-signed automáticamente si no existe. Por eso, tras un deploy limpio el certificado del simulador cambia y su thumbprint ya no coincide con los registrados en la BD. Para evitarlo, el directorio `config/certs/` se monta como volumen persistente (`e_cf_simulator_certs`).

**Acción obligatoria tras un deploy limpio o regeneración de certificado:**

```bash
bin/kamal app exec --reuse "bin/rails certificates:register RNC=<RNC> FILE=config/certs/simulator.crt ALIAS=simulator"
```

Además, registra los certificados de las empresas que vayan a probar recepción. Sin un certificado registrado para el RNC emisor, la recepción responderá `E016`.

Secretos requeridos en `.kamal/secrets`: `KAMAL_REGISTRY_PASSWORD`, `RAILS_MASTER_KEY`, `APPSIGNAL_PUSH_API_KEY`, `JWT_SECRET`.

## Monitoreo

AppSignal configurado para producción (error tracking y performance). Requiere `APPSIGNAL_PUSH_API_KEY` en `.kamal/secrets`.

## Notas

- Auditoría: PaperTrail (versionado de cambios) + AuditLog (acciones de panel).
- Soft-delete: Paranoia (`deleted_at`) en todos los modelos.

- Validación XSD disponible. Schemas oficiales en `lib/xsd/`. Activada por defecto en producción (deploy.yml); en desarrollo/tests se activa con `XSD_VALIDATION_ENABLED=true`.
- Firma digital: validación estructural + verificación criptográfica real (RSA-SHA256) usando un certificado self-signed de prueba. Desactivable con `SIGNATURE_VERIFICATION_ENABLED=false`.
- No incluye Docker, Redis, Sidekiq ni PostgreSQL.