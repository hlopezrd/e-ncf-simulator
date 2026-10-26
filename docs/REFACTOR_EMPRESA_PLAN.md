# Plan de Refactor — Unificación por Empresa (RNC)

**Estado general:** Fases 0–6 completadas. Refactor finalizado.
**Última actualización:** 2026-10-26 (Fase 0)
**Motivación:** La información por RNC/empresa está dispersa (certificados por rake, rangos por rake, usuarios por RNC, e-CF por RNC emisor). Unificar bajo una entidad `Empresa` para simplificar onboarding, self-service desde el portal y coherencia.

---

## Objetivo

Crear una entidad **`Empresa`** (identificada por RNC) que sea el "dueño" de certificados, rangos de e-NCF, usuarios y e-CF emitidos, y mover la carga de certificado/rangos al portal admin (self-service), dejando los rake tasks solo para bootstrap.

---

## Estado de implementación

- [x] Fase 0 — Análisis y diseño del modelo
- [x] Fase 1 — Modelo `Empresa` + migraciones + relaciones
- [x] Fase 2 — Servicios y controladores adaptados (certificado/rangos por empresa)
- [x] Fase 3 — Endpoints + UI del portal (alta de empresa, upload de certificado, registro de rango)
- [x] Fase 4 — Migración de datos existentes (RNCs → Empresas)
- [x] Fase 5 — Documentación y onboarding actualizados
- [x] Fase 6 — Retiro de rake tasks del flujo normal (mantener bootstrap)

---

## 1. Modelo propuesto

### `Empresa` (tabla `companies`)

| Campo | Tipo | Notas |
|---|---|---|
| id | PK | |
| rnc | string, unique, indexed | RNC de la empresa (9 u 11 dígitos) |
| razon_social | string | |
| nombre_comercial | string | opcional |
| email | string | opcional |
| telefono | string | opcional |
| activa | boolean, default true | soft-delete friendly |
| created_at, updated_at | | |
| deleted_at | datetime | paranoia (soft-delete) |

### Relaciones

```
Empresa
  ├── has_many :certificates, dependent: :destroy
  ├── has_many :ncf_sequences, dependent: :destroy
  ├── has_many :users, dependent: :nullify (o destroy)
  ├── has_many :electronic_invoices, foreign_key: :rnc_emisor (por RNC) — o has_many por empresa
  └── has_many :audit_logs

Certificate      belongs_to :empresa (nullable durante migración)
NcfSequence      belongs_to :empresa (nullable durante migración)
User             belongs_to :empresa (nullable durante migración)
ElectronicInvoice belongs_to :empresa (opcional, por RNC)
```

### Compatibilidad hacia atrás

- Mantener columnas `rnc` en `certificates`, `ncf_sequences`, `users` durante la transición.
- Los servicios actuales buscan por `rnc`; se adaptarán a buscar por `empresa` (con fallback por `rnc`).

---

## 2. Fases detalladas

### Fase 0 — Análisis y diseño del modelo ✅ COMPLETADA

**Inventario de uso de `rnc` como clave de negocio (hallazgos):**

Modelos con columna `rnc`/`rnc_emisor`/`rnc_comprador`:
- `User` (rnc; uniqueness username scope rnc)
- `Certificate` (rnc)
- `NcfSequence` (rnc)
- `NcfUsage` (rnc)
- `NcfAnnulation` (rnc_emisor)
- `NcfAnnulledRange` (rnc)
- `ElectronicInvoice` (rnc_emisor)
- `AuthToken` (rnc)
- `AuthSeed` (rnc)
- `InvoiceSummary` (rnc_emisor)
- `CommercialApproval` (rnc_emisor, rnc_comprador)
- `AuditLog` (actor vía User)

Servicios que consultan por `rnc`:
- `Auth::TokenService` → `User.find_by(rnc:, username:)`
- `Auth::SeedValidationService` → `registered_cert.rnc`
- `Ecfs::ValidateXmlService` → `Certificate.active.find_by(rnc:)`
- `Ecfs::ReceiveService` → `NcfSequence.where(rnc:)`, `NcfUsage.where(rnc:)`, `ElectronicInvoice.exists?(rnc_emisor:)`, `NcfUsage.create!(rnc:)`
- `Ecfs::ReceiveSummaryService` → `registered_cert.rnc` vs `rnc_emisor`, `NcfSequence.where(rnc:)`
- `Ecfs::ReceiveAnnulationService` → `registered_cert.rnc` vs `rnc_emisor`, `NcfSequence.where(rnc:)`, `NcfUsage.where(rnc:)`, `NcfAnnulledRange.where(rnc:)`
- `Ecfs::ReceiveCommercialApprovalService` → `registered_cert.rnc` vs `rnc_comprador`, por `rnc_emisor`/`rnc_comprador`
- `Ecfs::StatusQueryService` → `ElectronicInvoice.find_by(rnc_emisor:, encf:)`

Controladores:
- `Api::EmpresasController` → `ElectronicInvoice.group(:rnc_emisor)`
- `Api::UsuariosController` → param `rnc`
- `Api::MeController` → `user.rnc`
- `Api::NcfSequencesController` → param `rnc`
- `Api::Dgii::RecepcionController` → `current_rnc` vs `validation.rnc_emisor`

Decisiones confirmadas en Fase 0:
- [x] `Empresa` **convive** con `rnc` en Fase 1 (nullable FK); reemplazo gradual en Fase 3+. No rompe el flujo actual.
- [x] Soft-delete con **paranoia** (`deleted_at`) para `Empresa`, igual que el resto de modelos.
- [x] Onboarding self-service requiere rol **`admin`** existente (no crear rol nuevo en Fase 1).
- [x] Formato de RNC validado como 9 u 11 dígitos (ya en `ValidateXmlService` E022); se reutiliza en `Empresa`.
- [x] El certificado público se asocia a `Empresa`; la clave privada **nunca** se almacena.
- [x] Los rake tasks (`certificates:register`, `ncf_sequences:register`) se mantienen para bootstrap/deploy y pasarán a crear/actualizar `Empresa` (Fase 2).

### Fase 1 — Modelo `Empresa` + migraciones + relaciones ✅ COMPLETADA

- [x] Migración: `create_companies` (rnc unique, razon_social, nombre_comercial, email, telefono, activa, deleted_at).
- [x] Migración: `add_company_id_to_certificates` (nullable FK).
- [x] Migración: `add_company_id_to_ncf_sequences` (nullable FK).
- [x] Migración: `add_company_id_to_users` (nullable FK).
- [x] Migración: `add_company_id_to_electronic_invoices` (nullable FK, por rnc_emisor).
- [x] Modelo `Company` con validaciones (presence rnc, uniqueness rnc, formato 9/11 dígitos).
- [x] Relaciones `has_many`/`belongs_to` en `Company` y modelos existentes.
- [x] Specs de modelo (validaciones, relaciones, soft-delete).

### Fase 2 — Servicios y controladores adaptados ✅ COMPLETADA

- [x] `Ecfs::CryptoService`: sin cambios (la búsqueda de certificado registrado se hace en ValidateXmlService por rnc, con fallback natural).
- [x] `Ecfs::ReceiveService`: resuelve `Company` por rnc y asocia `company_id` a `ElectronicInvoice` (nullable). Secuencias/rangos siguen filtrando por rnc con fallback por company cuando existe. Delegación se mantiene por rnc (token RNC vs rncEmisor).
- [x] `Auth::TokenService`: sin migración nueva; `company` se resuelve vía `user.company` (User pertenece a Company).
- [x] `Ecfs::StatusQueryService`: sin cambios (usa rnc/encf).
- [x] Controladores DGII (`api/dgii/*`): `BaseController` expone `current_company` (resuelto por rnc del JWT).
- [x] Rake tasks (`certificates:register`, `ncf_sequences:register`): crean/actualizan `Company` y asocian el registro.

### Fase 3 — Endpoints + UI del portal (self-service)

- [ ] Endpoints REST:
  - `GET/POST/PATCH/DELETE /api/empresas` (CRUD).
  - `POST /api/empresas/:id/certificados` (upload de certificado).
  - `POST /api/empresas/:id/ncf_sequences` (registro de rango).
  - `GET /api/empresas/:id/estado-onboarding` (certificado vigente, rangos activos, e-CF recibidos).
- [ ] Portal React:
  - Pantalla "Empresas" con alta/edición.
  - Upload de certificado (`.crt`/`.cer`/`.p12`).
  - Formulario de registro de rango de e-NCF.
  - Indicador de estado de onboarding por empresa.
- [ ] Validaciones de upload (tamaño, formato, vigencia, thumbprint).
- [ ] Auditoría de acciones (PaperTrail + AuditLog).

### Fase 4 — Migración de datos existentes

- [ ] Script/rake `companies:migrate_from_rncs` que:
  - Recorra RNCs distintos en `certificates`, `ncf_sequences`, `users`, `electronic_invoices`.
  - Cree `Empresa` por cada RNC (si no existe).
  - Asigne `company_id` en los registros existentes.
- [ ] Idempotente y con dry-run (`DRY_RUN=true`).
- [ ] Verificación post-migración (counts por empresa, sin huérfanos).

### Fase 5 — Documentación y onboarding

- [ ] Actualizar `docs/ONBOARDING_CLIENTE.md`:
  - Reemplazar pasos de rake por alta desde el portal.
  - Mantener rake como "bootstrap/admin" en anexo.
- [ ] Actualizar `README.md` (sección de certificados y rangos).
- [ ] Actualizar `docs/admin-portal.md` (nuevos endpoints de empresa).

### Fase 6 — Retiro del flujo normal por rake

- [ ] Marcar rake tasks como "solo bootstrap/admin" en la documentación.
- [ ] (Opcional) Agregar warning en rake tasks indicando que el flujo normal es vía portal.
- [ ] No eliminar los rake tasks (se usan en deploy/bootstrap).

---

## 3. Riesgos y mitigaciones

| Riesgo | Mitigación |
|---|---|
| Romper el flujo actual por RNC | Convivencia nullable en Fase 1; fallback por rnc en servicios |
| Datos huérfanos en migración | Script idempotente con dry-run + verificación |
| Upload de certificado inseguro | Validación de formato/vigencia/tamaño; no almacenar clave privada |
| Cambio en autenticación por semilla | Resolver `empresa` desde el certificado registrado (por thumbprint) |
| Tests existentes fallan | Mantener rake tasks y columnas rnc; agregar tests nuevos sin quitar los existentes |

---

## 4. Decisiones confirmadas

- La entidad se llama `Empresa` (no `Company`) para alinearse con el dominio DGII.
- Convivencia nullable en Fase 1 (no romper).
- rake tasks se mantienen para bootstrap/deploy.
- Upload de certificado solo acepta público (`.crt`/`.cer`); la clave privada nunca se sube.

---

## 5. Orden de implementación sugerido

1. Fase 0 (análisis) → Fase 1 (modelo) → tests.
2. Fase 2 (servicios) → tests de integración.
3. Fase 3 (portal + endpoints) → pruebas manuales.
4. Fase 4 (migración) → verificación.
5. Fase 5 (docs) → Fase 6 (retiro).

---

## 6. Tracking de progreso

Marcar cada checkbox conforme se complete. Actualizar "Estado general" y "Última actualización" al cerrar cada fase.