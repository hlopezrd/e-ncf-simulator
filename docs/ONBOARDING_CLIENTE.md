# Onboarding de Cliente — Simulador e-CF (DGII RD)

> **Aviso:** Este es un **simulador**. No se conecta a la DGII real y sus respuestas **no tienen validez fiscal**. Úsalo para desarrollar, probar y certificar tu integración antes de ir a producción con la DGII.

Este documento guía a un **nuevo cliente (contribuyente/emisor)** paso a paso para que pueda autenticarse, registrar su certificado, recibir rangos de e-NCF, emitir su primer e-CF y consultar su estado.

---

## 0. Antes de empezar

- **¿Quién eres?** El **emisor** (vendedor/proveedor) es quien genera y firma la factura. El **comprador/receptor** es quien la recibe y la aprueba ante la DGII. Si no hay RNC comprador, no hay aprobación comercial.
- **Ambientes del simulador** (mismo contrato, distinto host/prefijo):

| Ambiente | Prefijo | Uso |
|---|---|---|
| Pre-certificación | `/testecf/...` | Pruebas iniciales |
| Certificación | `/certecf/...` | Pruebas formales |
| Producción simulada | `/ecf/...` (o sin prefijo) | Demos finales |

- **Host base (producción simulada):** `https://sim.ecfgateway.com`

> La DGII real usa los mismos contratos cambiando solo el host. Si tu integración funciona aquí, funcionará con la DGII (cambiando host y certificado).

---

## 1. Requisitos previos

1. **RNC** de la empresa emisora (9 u 11 dígitos).
2. **Certificado digital** (X.509) emitido a nombre del RNC. Debe incluir la clave privada para firmar. Formatos aceptados: `.pem`, `.crt`, `.cer`.
3. **Rangos de e-NCF autorizados** por la DGII (en el simulador se registran manualmente — ver paso 3).
4. Un **cliente HTTP** capaz de enviar `multipart/form-data` y manejar Bearer tokens (Postman, curl, o tu SDK).
5. (Opcional) **XML de e-CF** de prueba. Puedes usar los fixtures del repo o generarlos desde tu sistema.

---

## 1.5 Alta de empresa (self-service desde el portal)

A partir de la Fase 3, el onboarding se realiza desde el **portal admin**:

1. Ingresa al portal admin con un usuario `admin`.
2. Ve a **Empresas** → "Crear empresa" (RNC + razón social).
3. En la fila de la empresa: **Cert** para subir el certificado (`.crt`/`.cer`/`.pem`) y **Rango** para registrar un rango de e-NCF.

Los rake tasks (`certificates:register`, `ncf_sequences:register`, `companies:migrate_from_rncs`) se mantienen para **bootstrap/deploy y migración de datos**, no para el flujo normal.

## 2. Paso 1 — Registrar tu certificado en el simulador

El simulador verifica la firma de cada e-CF contra el certificado registrado para tu RNC. **Sin certificado registrado, la recepción responde `E016`.**

### 2.1 Si eres administrador del simulador (acceso al servidor)

```bash
bin/rails certificates:register RNC=<tu RNC> FILE=storage/certs/tu_empresa.crt ALIAS=tu_empresa
```

Salida esperada:

```
Registered certificate #N for RNC 101234567
  thumbprint: <SHA-256>
  vigente:    true (2026-01-01 -> 2027-12-31)
```

### 2.2 Si no tienes acceso al servidor

Contacta al administrador del simulador y envíale:

- Tu RNC.
- El archivo de certificado público (`.crt`/`.cer`).
- El alias deseado.

El administrador lo registrará con el comando anterior. **No compartas tu clave privada.**

### 2.3 Verificar que tu certificado está vigente

- `vigente: true` → OK.
- Si es `false` (expirado o aún no válido), la recepción fallará con `E017`/`E018`.

---

## 2.4 Cómo obtener o generar tu certificado digital (paso opcional)

El simulador (y la DGII real) exige que cada e-CF esté **firmado digitalmente** con un certificado X.509 asociado al RNC emisor. A continuación los escenarios más comunes para obtenerlo, qué necesitas en cada caso y qué se espera al final.

> **Importante:** la DGII real **solo acepta certificados emitidos por una CA reconocida** (Indotel, Cámara de Comercio, CamaraDigital, etc.). Los certificados autogenerados (self-signed) **solo sirven para el simulador** y entornos de prueba. No los uses en producción con la DGII.

### Escenario A — Certificado comprado a una CA autorizada (producción real)

**Cuándo aplica:** vas a facturar electrónicamente ante la DGII real.

**Qué necesitas:**
- RNC de la empresa.
- Documentos legales de la empresa (acta constitutiva, cédula del representante, etc.).
- Correo corporativo y teléfono.
- Elegir una CA autorizada por la DGII (Indotel, Cámara de Comercio y Producción de Santo Domingo, CamaraDigital, entre otras).

**Proceso típico:**
1. Solicitas el certificado en el portal de la CA (clase de certificado "Contribuyente" / "Firma Digital").
2. La CA valida tu identidad (presencial o en línea).
3. La CA emite un archivo (`.p12`/`.pfx` o `.crt`+`.key`) con vigencia típica de 1 a 3 años.
4. Guardas el archivo y su contraseña en un lugar seguro.

**Lo esperado al final:**
- Un archivo de certificado **público** (`.crt`/`.cer`) que puedes compartir.
- Un archivo de **clave privada** (`.key`) que **nunca** compartes.
- (Opcional) Un contenedor `.p12`/`.pfx` que une ambos.

**Para registrar en el simulador:**
```bash
# Extraer el certificado público si solo tienes el .p12
openssl pkcs12 -in tu_certificado.p12 -clcerts -nokeys -out tu_certificado.crt
# Registrar
bin/rails certificates:register RNC=<tu RNC> FILE=tu_certificado.crt ALIAS=empresa_real
```

### Escenario B — Certificado autogenerado (self-signed) para pruebas/desarrollo

**Cuándo aplica:** desarrollo, pruebas locales, integración con el simulador.

**Qué necesitas:** solo `openssl` instalado (viene por defecto en macOS/Linux).

**Generar clave privada + certificado self-signed (válido 365 días):**
```bash
# 1. Generar clave privada RSA 2048
openssl genrsa -out empresa.key 2048

# 2. Generar certificado self-signed
openssl req -new -x509 -key empresa.key -out empresa.crt -days 365 \
  -subj "/C=DO/ST=Santo Domingo/L=Santo Domingo/O=Mi Empresa SRL/CN=<tu RNC>/emailAddress=contacto@miempresa.com"

# 3. (Opcional) Empaquetar en .p12 para usarlo en tu aplicación
openssl pkcs12 -export -out empresa.p12 -inkey empresa.key -in empresa.crt -name "mi-empresa"
```

**Lo esperado al final:**
- `empresa.key` — **clave privada**, guárdala segura, no la compartas.
- `empresa.crt` — **certificado público**, este es el que registras en el simulador.
- `empresa.p12` (opcional) — contenedor con ambos, útil para tu app.

**Para registrar en el simulador:**
```bash
bin/rails certificates:register RNC=<tu RNC> FILE=empresa.crt ALIAS=empresa_prueba
```

**Limitaciones:**
- Solo válido para el simulador y entornos de prueba.
- La DGII real lo rechazará (`E017`/`E018`/firma inválida).
- Úsalo únicamente para desarrollar y probar tu integración.

### Escenario C — Reutilizar un certificado existente

**Cuándo aplica:** ya tienes un certificado (comprado o autogenerado) y quieres usarlo para otro RNC o en otro ambiente.

**Qué necesitas:**
- El archivo `.crt`/`.cer` (público) del certificado.
- Verificar que el certificado esté vigente y que su `CN`/`subject` corresponda al RNC.

**Pasos:**
1. Inspecciona el certificado:
   ```bash
   openssl x509 -in empresa.crt -noout -subject -dates -fingerprint -sha256
   ```
2. Confirma que `notBefore`/`notAfter` cubren la fecha actual (`vigente: true`).
3. Regístralo para el RNC correspondiente:
   ```bash
   bin/rails certificates:register RNC=<tu RNC> FILE=empresa.crt ALIAS=empresa_reutilizado
   ```

**Lo esperado al final:** mismo que el escenario A/B — un certificado registrado y vigente para tu RNC, con thumbprint coincidente.

### Recomendaciones de seguridad (todos los escenarios)

- **Nunca** compartas tu clave privada (`.key` o `.p12` sin protección).
- Protege los archivos con permisos restrictivos: `chmod 600 empresa.key`.
- Guarda una copia de respaldo del `.p12` en un lugar seguro (fuera del repositorio).
- Agrega `*.key`, `*.p12`, `*.pfx` al `.gitignore` de tu proyecto.
- Renueva el certificado **antes** de su vencimiento para evitar `E017`.
- En producción, usa certificados emitidos por CA autorizada por la DGII.

### Verificación final (todos los escenarios)

Tras registrar, ejecuta:
```bash
bin/rails certificates:register RNC=<tu RNC> FILE=<tu_certificado.crt> ALIAS=<alias>
```
(o consulta el portal admin) y confirma:
- `vigente: true`
- Thumbprint coincide con el que tu aplicación usa para firmar.
- Fecha de vencimiento (`notAfter`) posterior a hoy.

Si falta alguno de estos puntos, la recepción responderá `E016`, `E017` o `E018`.

## 3. Paso 2 — Registrar tus rangos de e-NCF

La DGII autoriza bloques de e-NCF por **RNC y por tipo de comprobante**. El simulador valida que el e-NCF que envíes pertenezca a un rango activo y vigente (`E020`/`E021` si no).

### 3.1 Anatomía del e-NCF

```
E  31  0000000001
│  │   └────────── secuencia (10 dígitos)
│  └────────────── tipo de comprobante (2 dígitos)
└───────────────── prefijo electrónico
```

Ejemplo: `E310000000001` = electrónico, tipo **31**, secuencia **1**.

### 3.2 Registrar un rango

```bash
bin/rails ncf_sequences:register RNC=101234567 TIPO=31 DESDE=1 HASTA=1000 VENCIMIENTO=2027-12-31
```

- `TIPO`: tipo de comprobante (31, 32, 33, 34, 41, 43, 44, 45, 46, 47).
- Cada tipo tiene **su propio rango**. No reutilices un e-NCF de tipo 31 para una factura tipo 32.
- `VENCIMIENTO`: fecha de vencimiento del rango (formato `YYYY-MM-DD`).

### 3.3 Reglas importantes

- **Por RNC + tipo**: el rango pertenece a un RNC y a un tipo específico.
- **Consumo**: cada e-CF **aceptado** consume un e-NCF (se registra en `NcfUsage`).
- **Rechazo**: si la DGII rechaza el e-CF, el e-NCF **no se consume**; puedes corregir y reenviar con el mismo número.
- **Duplicado**: un e-NCF ya aceptado no se puede reutilizar (el simulador responde `E010`).
- **Anulación de rangos no usados**: usa ANECF para anular rangos completos no consumidos (no facturas individuales; para eso usa Nota de Crédito, tipo 34).

---

## 4. Paso 3 — Autenticación (semilla)

La autenticación con la DGII se hace con tu **certificado digital**, no con usuario/contraseña.

### 4.1 Flujo

```
1. GET  .../autenticacion/api/autenticacion/semilla      → XML <SemillaModel> firmado por el simulador
2. Validar la firma del XML con el certificado público del simulador (GET .../autenticacion/api/autenticacion/certificado)
3. Firmar la semilla (sin la firma del simulador) con TU certificado
4. POST .../autenticacion/api/autenticacion/validarsemilla  (multipart xml) → { token, expira, expedido }
5. Usar el token en Authorization: Bearer <token> (válido 1 hora)
```

### 4.2 Ejemplo con curl

```bash
BASE=https://sim.ecfgateway.com/testecf

# 1. Obtener semilla
curl -s "$BASE/autenticacion/api/autenticacion/semilla" -o semilla.xml

# 2. Obtener certificado del simulador
curl -s "$BASE/autenticacion/api/autenticacion/certificado" -o simulator.crt

# 3. (En tu código) validar firma del simulador, firmar la semilla con tu certificado y enviarla
curl -X POST "$BASE/autenticacion/api/autenticacion/validarsemilla" \
  -F "xml=@semilla_firmada.xml" \
  -o token.json

cat token.json   # { "token": "...", "expira": "...", "expedido": "..." }
```

### 4.3 Errores comunes en autenticación

| Código | Causa | Solución |
|---|---|---|
| `E016` | No hay certificado registrado para tu RNC | Registrar certificado (paso 2) |
| `E017` | Certificado expirado | Renovar certificado y re-registrar |
| `E018` | Thumbprint no coincide | Verificar que envías el certificado correcto |
| `E019` | No delegado (token RNC ≠ rncEmisor) | Autentícate con el RNC emisor del e-CF |

---

## 5. Paso 4 — Enviar tu primer e-CF (recepción)

### 5.1 Endpoint

```
POST {prefijo}/recepcion/api/facturaselectronicas
Content-Type: multipart/form-data
Authorization: Bearer <token>
Body: xml=<tu e-CF firmado>
```

### 5.2 Ejemplo con curl

```bash
TOKEN=$(jq -r .token token.json)
curl -X POST "$BASE/recepcion/api/facturaselectronicas" \
  -H "Authorization: Bearer $TOKEN" \
  -F "xml=@mi_factura.xml" \
  -o recepcion.json
cat recepcion.json
```

### 5.3 Respuesta exitosa

```json
{
  "trackId": "uuid-generado",
  "codigo": 1,
  "estado": "Aceptado",
  "rnc": "101234567",
  "encf": "E310000000001",
  "secuenciaUtilizada": true,
  "fechaRecepcion": "2026-10-26T12:00:00Z",
  "mensajes": []
}
```

- `trackId`: guárdalo; lo usarás para consultar el estado.
- `codigo`: `1` Aceptado, `2` Rechazado, `3` En Proceso, `4` Aceptado Condicional, `0` No encontrado.
- `secuenciaUtilizada`: `true` solo si el e-CF fue aceptado (consume el e-NCF).

### 5.4 Si el e-CF es rechazado

```json
{
  "trackId": "uuid-generado",
  "codigo": 2,
  "estado": "Rechazado",
  "mensajes": [
    { "valor": "RNC emisor inválido o ausente", "codigo": "E004" }
  ]
}
```

El simulador **siempre devuelve un `trackId`**, incluso si rechaza. Corrige el XML y reenvía con el **mismo e-NCF** (no se consumió).

### 5.5 Checklist del XML de e-CF

- [ ] Bien formado (XML válido).
- [ ] Nodo raíz `<ECF>` presente.
- [ ] `RNCEmisor` presente y con certificado registrado.
- [ ] `eNCF` presente, empieza con `E`, pertenece a un rango autorizado y vigente, y coincide con el tipo del XML.
- [ ] `TipoeCF` presente (31, 32, …).
- [ ] `FechaEmision` presente.
- [ ] `Totales` / `MontoTotal` presentes.
- [ ] Firmado digitalmente con tu certificado (RSA-SHA256).
- [ ] Si el tipo requiere RNC comprador (31, 33, 34, 44, 45), incluir `RNCComprador`.
- [ ] El RNC del token JWT debe coincidir con `RNCEmisor` (si no → `E019`).

### 5.6 Tipos de comprobante

| Tipo | Nombre | ¿Requiere RNC comprador? | Flujo adicional |
|---|---|---|---|
| 31 | Factura de Crédito Fiscal | ✅ Sí | ACECF (aprobación comercial) |
| 32 | Factura de Consumo | ❌ No | RFCE (resumen, si alto volumen) |
| 33 | Nota de Débito | ✅ Sí | ACECF |
| 34 | Nota de Crédito | ✅ Sí | ACECF |
| 41 | Comprobante de Compras | ⚠️ Roles invertidos | (comprador es emisor) |
| 43 | Gastos Menores | ❌ No | — |
| 44 | Regímenes Especiales | ✅ Sí | ACECF |
| 45 | Comprobante Gubernamental | ✅ Sí | ACECF |
| 46 | Exportaciones | ❌ No | — |
| 47 | Pagos al Exterior | ❌ No | — |

---

## 6. Paso 5 — Consultar el estado

### 6.1 Por trackId

```
GET {prefijo}/consultaresultado/api/Consultas/Estado?trackId=<trackId>
Authorization: Bearer <token>
```

```bash
curl -s "$BASE/consultaresultado/api/Consultas/Estado?trackId=$TRACKID" \
  -H "Authorization: Bearer $TOKEN"
```

Respuesta:

```json
{
  "trackId": "uuid",
  "codigo": 1,
  "estado": "Aceptado",
  "rnc": "101234567",
  "encf": "E310000000001",
  "secuenciaUtilizada": true,
  "fechaRecepcion": "2026-10-26T12:00:00Z",
  "mensajes": []
}
```

### 6.2 Por RNC + e-NCF (+ comprador + código de seguridad)

```
GET {prefijo}/consultaestado/api/Consultas/Estado?rncEmisor=...&ncfElectronico=...&rncComprador=...&codigoSeguridad=...
```

Útil cuando no tienes el trackId pero sí el número de factura.

### 6.3 Listar trackIds de un emisor

```
GET {prefijo}/consultatrackids/api/TrackIds/Consulta?rncEmisor=...&encf=...
```

Devuelve un array `[{ trackId, estado, fechaRecepcion }]`.

### 6.4 Estados posibles

| Código | Estado |
|---|---|
| 0 | No encontrado |
| 1 | Aceptado |
| 2 | Rechazado |
| 3 | En Proceso |
| 4 | Aceptado Condicional |

---

## 7. Paso 6 — Aprobación Comercial (ACECF) — solo si hay RNC comprador

La aprobación comercial es la **decisión fiscal del comprador** ante la DGII. Sin ella, el comprador no puede usar el crédito fiscal. Si rechaza, el emisor debe emitir Nota de Crédito (tipo 34).

### 7.1 Endpoint

```
POST {prefijo}/aprobacioncomercial/api/AprobacionComercial
Content-Type: multipart/form-data
Authorization: Bearer <token del comprador>
Body: xml=<ACECF firmado por el comprador>
```

### 7.2 Flujo

1. El comprador recibe el e-CF del emisor.
2. El comprador genera un **ACECF** (XML) aprobando o rechazando.
3. Firma el ACECF con **su** certificado.
4. Envía el ACECF a la DGII (endpoint anterior).
5. El emisor puede consultar el estado del e-CF para ver la aprobación.

> El ACECF se firma con el certificado del **comprador**, no del emisor.

---

## 8. Otros documentos (cuando aplique)

| Documento | Cuándo | Endpoint |
|---|---|---|
| **ARECF** (Acuse de Recibo) | Evidencia peer-to-peer de recepción. Opcional. | No es servicio DGII (va emisor↔comprador) |
| **ANECF** (Anulación de rangos) | Anular rangos de e-NCF no usados | `POST .../anulacionrangos/api/operaciones/anularrango` |
| **RFCE** (Resumen de Consumo) | Facturas de consumo de alto volumen (tipo 32) | `POST .../recepcionfc/api/recepcion/ecf` |

---

## 9. Códigos de error frecuentes

| Código | Significado |
|---|---|
| `E002` | XML malformado |
| `E004` | RNC emisor inválido o ausente |
| `E005` | e-NCF inválido |
| `E006` | RNC comprador inválido |
| `E009` | Totales no cuadran |
| `E010` | Duplicado (e-NCF ya aceptado) |
| `E012–E015` | Problemas de firma digital |
| `E016` | Sin certificado registrado para el RNC |
| `E017` | Certificado expirado |
| `E018` | Thumbprint no coincide |
| `E019` | No delegado (token RNC ≠ rncEmisor) |
| `E020` | Secuencia no autorizada (fuera de rango o vencido) |
| `E021` | Tipo de comprobante no coincide con la secuencia |
| `E022` | Formato de RNC inválido |
| `E023` | Salto de secuencia (e-NCF no sigue el orden) |
| `E024` | e-NCF anulado |
| `E025` | Rango de e-NCF agotado |
| `E026` | El rango incluye e-NCF ya utilizados |
| `X001` | Error de validación XSD |

---

## 10. Directorio y estatus de servicios

- **Directorio por RNC:** `GET .../consultadirectorio/api/consultas/obtenerdirectorioporrnc?rnc=...` → `{ nombre, rnc, urlRecepcion, urlAceptacion, urlOpcional }`
- **Listado:** `GET .../consultadirectorio/api/consultas/listado`
- **Estatus de servicios:** `GET .../api/estatusservicios/obtenerestatus`
- **Ventanas de mantenimiento:** `GET .../api/estatusservicios/obtenerventanasmantenimiento`
- **Verificar estado:** `GET .../api/estatusservicios/verificarestado`

---

## 11. Checklist de onboarding (resumen)

- [ ] Tengo mi RNC y certificado digital (con clave privada).
- [ ] Mi certificado público está registrado en el simulador (paso 2).
- [ ] Mis rangos de e-NCF están registrados (paso 3).
- [ ] Puedo obtener la semilla y validar la firma del simulador.
- [ ] Puedo firmar la semilla con mi certificado y obtener un JWT.
- [ ] Puedo enviar un e-CF firmado y recibir un `trackId`.
- [ ] Puedo consultar el estado por `trackId`.
- [ ] (Si aplica) Puedo enviar un ACECF firmado por el comprador.
- [ ] Conozco los códigos de error y cómo resolverlos.

---

## 12. Recursos adicionales

- **Glosario:** [`docs/GLOSSARY.md`](GLOSSARY.md) — términos, actores, tipos de NCF, documentos y códigos de error.
- **OpenAPI spec DGII:** [`docs/openapi-dgii.yaml`](openapi-dgii.yaml).
- **Colección Postman:** [`docs/postman-dgii.json`](postman-dgii.json).
- **README:** [`README.md`](../README.md) — instalación, endpoints legacy `/api/*`, ejemplos curl.
- **Plan de paridad DGII:** [`docs/DGII_PARITY_PLAN.md`](DGII_PARITY_PLAN.md).

---

## 13. Soporte

Si tienes problemas:

1. Revisa los **códigos de error** (sección 9) y los **mensajes** devueltos.
2. Verifica que tu certificado esté registrado y vigente (`E016`, `E017`, `E018`).
3. Verifica que tu e-NCF pertenezca a un rango autorizado y vigente (`E020`, `E021`).
4. Verifica que el RNC del token coincida con el `RNCEmisor` (`E019`).
5. Contacta al administrador del simulador adjuntando el `trackId`, el `request_id` (header `X-Request-Id`) y el `error_id` (si es 500).

> Recuerda: este simulador **no tiene validez fiscal**. Úsalo solo para desarrollo, pruebas y certificación de tu integración.