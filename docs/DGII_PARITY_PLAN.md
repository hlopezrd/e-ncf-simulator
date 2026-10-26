# Plan: Clonar comportamiento de DGII (e-CF)

**Estado general:** En progreso — Fases 1, 2, 3 y 4 completadas.

**Última actualización:** 2026-10-26

Este documento es el tracking oficial del trabajo para que el simulador sea lo más parecido posible a la DGII real. Cada fase se marca con checkboxes.

---

## Objetivo

El simulador debe ser un **reemplazo funcional de la API DGII**: mismos endpoints, mismos contratos (request/response), mismas validaciones, mismos códigos de error, mismos estados. Solo cambia el host (y el ambiente: test/cert/prod).

## Decisiones base

- **Compatibilidad**: los endpoints `/api/*` actuales (portal/admin) se mantienen. Se agregan las rutas DGII aparte (`/testecf/...` por defecto).
- **Alcance inicial**: Fases 1–4 (núcleo). ARECF/ACECF/ANECF/RFCE en Fase 5.
- **JWT**: agregar gema `jwt` para emitir/validar tokens como DGII.
- **Prefijo de rutas**: `/testecf/...` (simula ambiente de pre-certificación).

---

## Contratos reales de DGII (referencia)

| Servicio | Método | Endpoint | Entrada | Salida |
|---|---|---|---|---|
| Semilla | GET | `/autenticacion/api/autenticacion/semilla` | — | XML `<SemillaModel><valor>…</valor><fecha>…</fecha></SemillaModel>` |
| Validar semilla | POST | `/autenticacion/api/autenticacion/validarsemilla` | multipart `xml` (semilla firmada) | `{ token, expira, expedido }` |
| Recepción e-CF | POST | `/recepcion/api/facturaselectronicas` | multipart `xml` + Bearer | `{ trackId, error?, mensajes? }` |
| Consulta resultado | GET | `/consultaresultado/api/Consultas/Estado?trackId=` | Bearer | `{ trackId, codigo, estado, rnc, encf, secuenciaUtilizada, fechaRecepcion, mensajes[] }` |
| Consulta estado | GET | `/consultaestado/api/Consultas/Estado?rncEmisor=&ncfElectronico=&rncComprador=&codigoSeguridad=` | Bearer | `{ codigo, estado, rncEmisor, ncfElectronico, montoTotal, totalITBIS, fechaEmision, fechaFirma, rncComprador, codigoSeguridad }` |
| Consulta TrackIds | GET | `/consultatrackids/api/TrackIds/Consulta?rncEmisor=&encf=` | Bearer | `[{ trackId, estado, fechaRecepcion }]` |
| Aprobación comercial | POST | `/aprobacioncomercial/api/AprobacionComercial` | multipart `xml` firmado por comprador | `{ codigo, estado, mensaje[] }` |
| Anulación de rangos | POST | `/anulacionrangos/api/operaciones/anularrango` | multipart `xml` | `{ rnc, codigo, nombre, mensajes[] }` |
| Resumen FC | POST | `/recepcionfc/api/recepcion/ecf` | multipart `xml` firmado | `{ codigo, estado, mensajes[], encf, secuenciaUtilizada }` |
| Consulta resumen FC | GET | `/consultarfce/api/Consultas/Consulta` | Bearer | estado del RFCE |
| Directorio | GET | `/consultadirectorio/api/consultas/...` | Bearer | `{ nombre, rnc, urlRecepcion, urlAceptacion, urlOpcional }` |

**Estados (`codigo`):** `0` No encontrado, `1` Aceptado, `2` Rechazado, `3` En Proceso, `4` Aceptado Condicional.

**Mensajes:** `{ valor, codigo }`.

---

## Fase 1 — Autenticación por certificado (semilla) ✅ COMPLETADA

- [x] Migración: modelo `AuthSeed` (valor, fecha, expira, usado, rnc).
- [x] `GET /testecf/autenticacion/api/autenticacion/semilla` → XML `<SemillaModel>`.
- [x] `POST /testecf/autenticacion/api/autenticacion/validarsemilla` (multipart `xml`).
  - Extraer `X509Certificate`, buscar `Certificate` por thumbprint, validar vigencia.
  - Verificar firma del XML firmado con ese certificado.
  - Emitir JWT (1h) con `name`=RNC, `iss`=DGII.FE, `aud`=USUARIOS.DGII.FE.
  - Responder `{ token, expira, expedido }`.
- [x] Middleware JWT para rutas DGII (BaseController).
- [x] Tests de integración: semilla → firmar → token (4 specs).

## Fase 2 — Recepción e-CF con contrato DGII ✅ COMPLETADA

- [x] `POST /testecf/recepcion/api/facturaselectronicas` (multipart `xml`).
- [x] Validaciones: XSD, firma vs certificado registrado, vigencia, RNC válido, e-NCF autorizado, duplicado.
- [x] Siempre responder `trackId`, incluso si rechazado.
- [x] Guardar `codigoSeguridad`, `secuenciaUtilizada`, montos, fechas.
- [x] Formato de errores: `mensajes: [{ valor, codigo }]`.
- [x] Delegación: usuario autenticado debe corresponder al RNC emisor (E019).
- [ ] Portal: mostrar nuevos campos. (pendiente)

## Fase 3 — Consultas ✅ COMPLETADA

- [x] `GET /testecf/consultaresultado/api/Consultas/Estado?trackId=`.
- [x] `GET /testecf/consultaestado/api/Consultas/Estado?rncEmisor=&ncfElectronico=&rncComprador=&codigoSeguridad=`.
- [x] `GET /testecf/consultatrackids/api/TrackIds/Consulta?rncEmisor=&encf=`.
- [x] Tests por cada endpoint (4 specs).

## Fase 4 — Secuencias e-NCF ✅ COMPLETADA

- [x] Modelo `NcfSequence` (rnc, tipo, desde, hasta, vencimiento, activa).
- [x] Modelo `NcfUsage` para rastrear consumo.
- [x] Validar que el e-NCF pertenezca a un rango autorizado y vigente.
- [x] Regla de `secuenciaUtilizada` (rechazos que no consumen secuencia).
- [x] Rake task `ncf_sequences:register`.
- [x] Nuevos códigos de error `E020` (e-NCF no autorizado) y `E021` (tipo no coincide).

## Fase 5 — Documentos adicionales

- [ ] `ARECF` (acuse de recibo) — verificar con cert del RNC comprador.
- [ ] `ACECF` (aprobación comercial) — verificar con cert del RNC comprador.
- [ ] `ANECF` (anulación de rangos).
- [ ] `RFCE` (resumen de factura de consumo).
- [ ] Obtener XSD de cada formato desde DGII.
- [ ] Endpoints de consulta correspondientes.

## Fase 6 — Directorio y estatus

- [ ] Directorio de contribuyentes electrónicos.
- [ ] Estatus de servicios y ventanas de mantenimiento.

## Fase 7 — Contrato y pruebas

- [ ] OpenAPI spec de los endpoints DGII.
- [ ] Colección de Postman.
- [ ] Tests de integración por flujo completo.

---

## Decisiones confirmadas

- Prefijo de rutas: `/testecf/...`.
- Compatibilidad: mantener `/api/*` para el portal.
- Alcance inicial: Fases 1–4.
- JWT con gema `jwt`.
- `secuenciaUtilizada` según reglas DGII.

## Notas

- El certificado del contribuyente se usa para firmar e-CF (emisor), ARECF/ACECF (receptor), y la semilla (autenticación). DGII nunca firma con él.
- La respuesta de DGII no va firmada con el certificado del contribuyente.
- `config/certs/simulator.*` es la identidad del simulador, separada de los contribuyentes.