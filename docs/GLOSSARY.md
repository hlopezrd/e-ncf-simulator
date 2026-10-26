# Glosario e-CF (DGII RD)

Glosario de términos, actores y tipos de comprobante usados por el simulador. Sirve para evitar confusiones entre **emisor**, **comprador/receptor** y los documentos que los acompañan (ARECF, ACECF, ANECF, RFCE).

> **Aviso:** simulador sin validez fiscal. No se conecta a la DGII real.

## Actores

| Término | Quién es | Dónde aparece en el XML | Firma con su certificado |
|---|---|---|---|
| **Emisor** | El **vendedor/proveedor**: el RNC que **emite** la factura y es dueño de la secuencia de e-NCF | `rncEmisor` | e-CF, ANECF, RFCE |
| **Comprador / Receptor** | El **cliente**: el RNC **a quien se factura** (el "facturar a") | `rncComprador` | ARECF, ACECF |
| **Contribuyente** | Cualquier RNC registrado ante la DGII | — | — |
| **Consumidor Final** | Comprador sin RNC (factura de consumo, tipo 32) | — | No aplica |

## Documentos que acompañan al e-CF

| Sigla | Nombre | Quién lo emite | Quién lo recibe | ¿Servicio DGII? | Para qué |
|---|---|---|---|---|---|
| **ARECF** | Acuse de Recibo | Comprador | **Emisor** (peer-to-peer) | ❌ No | Evidencia de que el comprador recibió la factura. Puede indicar "conforme" o "rechazado". |
| **ACECF** | Aprobación Comercial | Comprador | **DGII** | ✅ Sí | Decisión fiscal del comprador: aprueba o rechaza la factura. Sin aprobación, el comprador no puede usar el crédito fiscal. Si rechaza, el emisor debe emitir Nota de Crédito (tipo 34). |
| **ANECF** | Anulación de rango de e-NCF | Emisor | **DGII** | ✅ Sí | Pide anular un **rango de e-NCF no usados** (no una factura individual). |
| **RFCE** | Resumen de Facturación de Consumo | Emisor | **DGII** | ✅ Sí | Modalidad alterna para facturas de consumo (tipo 32): envía un **resumen** con rangos y totales en vez de facturas individuales. |

### Acuse de Recibo vs. Aprobación Comercial

- **Acuse (ARECF)** = cortesía/evidencia. Va del comprador al **emisor**. La DGII no participa.
- **Aprobación (ACECF)** = decisión fiscal. Va del comprador a la **DGII**. La DGII la registra y el emisor puede consultar el estado.

## Términos clave

| Término | Significado |
|---|---|
| **e-CF** | Comprobante Fiscal Electrónico: la factura electrónica firmada digitalmente. La genera y firma el **emisor**, no la DGII. |
| **e-NCF** | Número de Comprobante Fiscal Electrónico: el número autorizado por la DGII para un rango de secuencia. Lo consume el emisor. |
| **trackId** | Acuse de recibo que la DGII devuelve al emisor al recibir el e-CF. Identifica la transacción para consultas posteriores. |
| **Contribuyente** | RNC registrado ante la DGII. Puede ser emisor y/o comprador. |
| **Secuencia** | Rango de e-NCF autorizado por la DGII para un tipo de comprobante y un RNC. |

## Flujo completo

```
1. DGII autoriza un rango de e-NCF al emisor.
2. Emisor genera el e-CF firmado con su certificado.
3. Emisor ──► DGII recepción ──► trackId.
4. Emisor ──► Comprador (XML/PDF).
5. Comprador ──► Emisor:  ARECF  (opcional, peer-to-peer).
6. Comprador ──► DGII:    ACECF  (obligatorio para crédito fiscal).
7. Emisor consulta estado en DGII (consultaestado / consultaresultado).
```

En paralelo, cuando aplica:

- **ANECF**: el emisor anula rangos no usados.
- **RFCE**: el emisor envía resúmenes de consumo en vez de facturas individuales.

## Tipos de e-NCF (DGII)

Roles de ejemplo: **Empresa A** = emisor (vendedor, RNC `101234567`), **Empresa B** = comprador (cliente, RNC `131111111`), opcional según el tipo.

| Tipo | Nombre | ¿Requiere RNC comprador (B)? | Ejemplo |
|---|---|---|---|
| **31** | Factura de Crédito Fiscal Electrónica | ✅ Sí (obligatorio) | A vende a B → B usa el crédito fiscal. B envía ACECF a la DGII. |
| **32** | Factura de Consumo Electrónica | ❌ No (consumidor final) | A vende al público. Sin RNC comprador; si hay alto volumen, A usa RFCE. |
| **33** | Nota de Débito Electrónica | ✅ Sí (el mismo comprador original) | A emite a B una nota de débito por un ajuste al alza. |
| **34** | Nota de Crédito Electrónica | ✅ Sí (el mismo comprador original) | A emite a B una nota de crédito (devolución/anulación parcial). |
| **41** | Comprobante de Compras | ⚠️ Roles invertidos | B (comprador) emite a A (proveedor informal) para documentar la compra. Aquí el emisor es el comprador. |
| **43** | Gastos Menores | ❌ No | Gastos menores sin RNC comprador. |
| **44** | Regímenes Especiales | ✅ Sí | Operaciones bajo regímenes especiales con RNC comprador. |
| **45** | Comprobante Gubernamental | ✅ Sí | Venta a entidad gubernamental (RNC comprador). |
| **46** | Comprobante para Exportaciones | ❌ No (comprador extranjero) | A exporta; el comprador no tiene RNC dominicano. |
| **47** | Comprobante para Pagos al Exterior | ❌ No | Pagos a proveedores del exterior. |

### Regla práctica

- Si el tipo **requiere RNC comprador** (31, 33, 34, 44, 45): el flujo incluye **ACECF** (aprobación comercial a la DGII) y posiblemente **ARECF** (acuse al emisor).
- Si el tipo **no requiere RNC comprador** (32, 43, 46, 47): no hay aprobación comercial; para consumo de alto volumen se usa **RFCE**.
- **Tipo 41** es el caso especial: los roles se invierten (el comprador es el emisor del comprobante).

## Mapeo en el simulador

| Acción | Endpoint | Certificado que se verifica |
|---|---|---|
| Recepción de e-CF | `POST /testecf/recepcion/api/facturaselectronicas` | Certificado del **RNC emisor** (token JWT debe coincidir con `rncEmisor`, si no → `E019`) |
| Aprobación Comercial | `POST /testecf/aprobacioncomercial/api/AprobacionComercial` | Certificado del **RNC comprador** |
| Anulación de rangos | `POST /testecf/anulacionrangos/api/operaciones/anularrango` | Certificado del **RNC emisor** |
| Resumen de Consumo (RFCE) | `POST /testecf/recepcionfc/api/recepcion/ecf` | Certificado del **RNC emisor** |
| Autenticación (semilla) | `GET/POST /testecf/autenticacion/api/autenticacion/...` | Certificado del RNC que se autentica |

## Códigos de error frecuentes

| Código | Significado |
|---|---|
| `E002` | XML malformado |
| `E004` | RNC emisor inválido o ausente |
| `E005` | e-NCF inválido |
| `E006` | RNC comprador inválido |
| `E009` | Totales no cuadran |
| `E010` | Duplicado |
| `E012–E015` | Problemas de firma digital |
| `E016` | Sin certificado registrado para el RNC |
| `E017` | Certificado expirado |
| `E018` | Thumbprint no coincide |
| `E019` | No delegado (token RNC ≠ rncEmisor) |
| `E020` | Secuencia no autorizada |
| `E021` | Tipo de comprobante no coincide con la secuencia |
| `E022` | Formato de RNC inválido |
| `X001` | Error de validación XSD |

## Estados del e-CF (consulta)

| Código | Estado |
|---|---|
| 0 | No encontrado |
| 1 | Aceptado |
| 2 | Rechazado |
| 3 | En Proceso |
| 4 | Aceptado Condicional |

---

**Regla de oro:** el emisor es quien **vende y genera** la factura; el comprador es quien **la recibe y puede aprobarla** ante la DGII. Si no hay RNC comprador, no hay aprobación comercial.