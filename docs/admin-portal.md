# Plan — Portal Administrativo e-CF Simulator

## Estado de implementación

- [x] Fase 1 — Shell visual + Login + Auth
- [x] Fase 2 — Dashboard + Empresas/RNC
- [x] Fase 3 — e-CF + TrackIds + visor XML/JSON
- [x] Fase 4 — Certificados + Validaciones + Historial
- [x] Fase 5 — Reglas de simulación
- [x] Fase 6 — Usuarios, roles y auditoría
- [x] Fase 7 — Hardening (accesibilidad, rendimiento, pruebas, docs)

### Ubicación del frontend
- `/frontend` (Vite + React + TS + Yarn)

### Deploy
- Estrategia Opción A: multi-stage Dockerfile (Node build → Rails public/), un solo contenedor.
- Kamal sin cambios; proxy enruta `sim.ecfgateway.com` al contenedor.

## 1. Arquitectura propuesta

- **Backend**: Rails 8 API existente (sin cambios de contrato). Endpoints actuales reutilizados.
- **Frontend**: Nueva app React + TypeScript + Vite en `/frontend` (directorio separado).
- **Comunicación**: REST/JSON sobre HTTPS. Auth por Bearer token (sim-token).
- **Estado**: TanStack Query para server state; React Router para SPA.
- **Estilos**: CSS variables centralizadas, sin framework UI pesado.

## 2. Mapa de pantallas

1. `/login` — Autenticación (rnc, usuario, password).
2. `/` (Dashboard) — métricas: total e-CF, aceptados, rechazados, condicionales, últimos requests.
3. `/empresas` — Empresas y RNC (CRUD simulado).
4. `/ecf` — Lista de e-CF con filtros por estado, RNC, fecha.
5. `/ecf/:trackId` — Detalle de e-CF: datos, XML visor, JSON, errores, advertencias.
6. `/trackids` — Consulta por TrackId y por RNC+eNCF.
7. `/certificados` — Certificados asociados (listado).
8. `/reglas` — Reglas de simulación (listado).
9. `/usuarios` — Usuarios y roles.
10. `/auditoria` — Auditoría de acciones.
11. `/configuracion` — Configuración del simulador.
12. `/health` — Estado de salud del sistema.
13. `/404`, `/error` — Estados de error.

## 3. Inventario de código reutilizable (backend)

### Endpoints existentes
- `GET /health`
- `POST /api/auth` → `{ token, expiresIn, tokenType }`
- `POST /api/recepcion` → `{ trackId, codigo, mensaje, fechaRecepcion }` (422 con errores)
- `GET /api/consulta-estado/:track_id`
- `GET /api/trackids/consulta?rncemisor=&encf=`

### Modelos existentes
- `AuthToken` (token_digest, rnc, expires_at)
- `ElectronicInvoice` (track_id, rnc_emisor, encf, tipo_comprobante, fecha_emision, xml_content, estado, fecha_recepcion, validation_errors)
- `ValidationError` (codigo, campo, mensaje, severidad)
- `AllowedOrigin` (origin)

### Servicios
- `Auth::TokenService`
- `Ecfs::ReceiveService`
- `Ecfs::ValidateXmlService`
- `Ecfs::StatusQueryService`
- `Ecfs::CryptoService`

### Autenticación
- Bearer token (sim-token-<uuid>), expiración 3600s. Credenciales de prueba únicas.

## 4. Endpoints faltantes (necesarios para el portal)

| Endpoint | Por qué | Respuesta esperada |
|---|---|---|
| `GET /api/ecf` (listado paginado) | Dashboard y tabla de e-CF | `{ data: [...], meta: { total, page } }` |
| `GET /api/ecf/:track_id` (detalle) | Detalle | Igual a consulta-estado + xml_content |
| `GET /api/empresas` | Lista de empresas/RNC | `{ data: [{ rnc, razon_social, ... }] }` |
| `GET /api/certificados` | Lista de certificados | `{ data: [...] }` |
| `GET /api/reglas` | Reglas de simulación | `{ data: [...] }` |
| `GET /api/usuarios` | Usuarios y roles | `{ data: [...] }` |
| `GET /api/auditoria` | Auditoría | `{ data: [...] }` |
| `GET /api/configuracion` | Configuración | `{ ... }` |

Estos endpoints pueden implementarse en Rails con serializers simples o mocks temporales en el frontend (claramente identificados).

## 5. Modelo de autenticación

- Login con credenciales de prueba.
- Token Bearer en `Authorization`.
- Expiración 1 hora.
- Logout = descartar token en cliente.

## 6. Modelo de permisos

- Roles simulados: `admin`, `operator`, `viewer`.
- Por ahora, todos los usuarios autenticados tienen acceso completo (simulador).
- Preparar estructura para RBAC futuro.

## 7. Riesgos de seguridad

- No exponer tokens en logs.
- Sanitizar XML en el visor (usar text/plain o DOMPurify si se renderiza HTML).
- CORS configurable (ya implementado con `allowed_origins`).
- Rate limiting ya activo.
- No almacenar secretos en el frontend.

## 8. Plan de migración sin romper el backend

- Frontend en `/frontend`, independiente.
- Consumir endpoints existentes sin modificar contratos.
- Endpoints faltantes se añaden en Rails como rutas nuevas (no rompen existentes).
- Mocks temporales en frontend claramente etiquetados.

## 9. Cambios mínimos en Rails necesarios

- Añadir endpoints de listado (ecf, empresas, certificados, reglas, usuarios, auditoria, configuracion).
- Añadir serializers JSON consistentes.
- Añadir CORS origins para el frontend (localhost:5173 en dev).

## 9.5 Estrategia de deploy (Opción A — Multi-stage Dockerfile)

El frontend React se construye dentro del mismo Dockerfile y se sirve desde Rails (`public/`). Un solo contenedor, un solo dominio.

### Dockerfile (multi-stage)

```dockerfile
# Stage 1: build frontend
FROM node:20-alpine AS frontend
WORKDIR /frontend
COPY frontend/package.json frontend/yarn.lock ./
RUN yarn install --frozen-lockfile
COPY frontend/ ./
RUN yarn build

# Stage 2: Rails (existente) + frontend
FROM ruby:3.4-slim AS base
...
COPY --from=frontend /frontend/dist /rails/public
```

### Rails sirve la SPA

- `config.public_file_server.enabled = true` en producción.
- Ruta catch-all en `routes.rb`:
  ```ruby
  get "*path", to: "frontend#index", constraints: ->(req) { !req.xhr? && req.format.html? }
  ```
- Controlador `FrontendController#index` renderiza `public/index.html`.
- `/api/*` y `/health` tienen prioridad (rutas definidas antes del catch-all).

### Kamal

Sin cambios. El proxy ya enruta `sim.ecfgateway.com` al contenedor. Rails sirve `/api/*` y el resto es SPA.

### CORS

No necesario (mismo origen). Dejar `allowed_origins` vacío o desactivar CORS.

### Ventajas

- Un solo deploy (`bin/kamal deploy`).
- Un solo dominio.
- Sin volumen externo.
- Frontend versionado con backend.

## 10. Fases de implementación

### Fase 1 — Shell visual
- Vite + React + TS.
- Layout: sidebar, header, breadcrumbs.
- Login page.
- Auth context (token storage).
- Error handling (401, 404, 500).
- Toasts, skeleton loaders.

### Fase 2 — Dashboard + Empresas
- Dashboard con métricas (mock o endpoint).
- Tabla de empresas/RNC.

### Fase 3 — e-CF + TrackIds
- Lista de e-CF con filtros.
- Detalle de e-CF con visor XML/JSON.
- Consulta por TrackId y RNC+eNCF.

### Fase 4 — Certificados + Validaciones
- Lista de certificados.
- Historial de validaciones.

### Fase 5 — Reglas de simulación
- Lista de reglas.

### Fase 6 — Usuarios, roles, auditoría
- Listas de usuarios y auditoría.

### Fase 7 — Hardening
- Accesibilidad (focus, contraste, ARIA).
- Rendimiento (lazy loading, memoization).
- Pruebas con Vitest + RTL.
- Documentación.

## 11. Convenciones de nombres

- Componentes: PascalCase.
- Hooks: useXxx.
- Servicios API: xxxApi.ts.
- Tipos: xxx.types.ts.
- CSS: BEM-like con variables CSS.

## 12. Riesgos y mitigaciones

- **Acoplamiento con backend**: usar tipos generados desde OpenAPI si existe; si no, definir tipos manualmente alineados con respuestas.
- **CORS**: configurar orígenes permitidos.
- **Seguridad del token**: almacenar en memoria (no localStorage) si es posible; para SPA simple, localStorage con XSS mitigation (CSP).
- **XSS en visor XML**: renderizar como texto (text/plain) o usar DOMPurify.
