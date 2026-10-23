# Resumen — Formato Comprobante Fiscal Electrónico (e-CF) v1.0 (DGII RD)

Fuente: DGII, "Formato Comprobante Fiscal Electrónico (e-CF) V1.0" (Octubre 2025). Documento oficial: https://dgii.gov.do/.../Formato%20Comprobante%20Fiscal%20Electrónico%20(e-CF)%20V1.0.pdf

## 1. Tipos de e-CF

| Código | Tipo |
|--------|------|
| 31 | Factura de Crédito Fiscal Electrónica |
| 32 | Factura de Consumo Electrónica |
| 33 | Nota de Débito Electrónica |
| 34 | Nota de Crédito Electrónica |
| 41 | Compras Electrónico |
| 43 | Gastos Menores Electrónico |
| 44 | Regímenes Especiales Electrónico |
| 45 | Gubernamental Electrónico |
| 46 | Comprobante de Exportaciones Electrónico |
| 47 | Comprobante para Pagos al Exterior Electrónico |

## 2. Composición del e-CF

1. **Encabezado** — identificación, emisor, comprador, datos tributarios.
2. **Detalle de Bienes o Servicios** — una línea por ítem.
3. **Subtotales Informativos** — no modifican totales.
4. **Descuentos o Recargos** — globales.
5. **Paginación** — cantidad de páginas e ítems por página.

Todo e-CF debe contener **firma digital** (autenticidad e integridad).

## 3. Áreas del Encabezado

- **Identificación del documento** (`<IdDoc>`): Versión, Tipo e-CF (`<TipoeCF>`), e-NCF (`<eNCF>`), Fecha vencimiento secuencia, Indicador nota de crédito >30 días, Indicador envío diferido, Indicador monto gravado, Tipo de ingresos, Tipo de pago, Fecha límite de pago, Término de pago, Tabla de formas de pago, Fecha desde/hasta, Total páginas.
- **Emisor** (`<Emisor>`): RNC, razón social, nombre comercial, sucursal, dirección, municipio, provincia, teléfono, correo, web, actividad económica, fecha inicio operaciones, código vendedor.
- **Comprador** (`<Comprador>`): RNC/Cédula, razón social, contacto, correo, dirección, municipio, provincia, fecha entrega, etc. (obligatoriedad varía por tipo).
- **Informaciones adicionales** (`<InformacionesAdicionales>`): fechas, orden de compra, número interno, etc.
- **Transporte** (`<Transporte>`): datos del transportista (condicional).
- **Totales del encabezado** (`<Totales>`): subtotal, descuentos/recargos, ITBIS, impuestos adicionales, total, monto pagado, etc.
- **Otra moneda** (`<OtraMoneda>`): totales en moneda extranjera.

## 4. Detalle (sección B)

- **Ítem** (`<Item>`): número de línea, indicador facturación, nombre, indicador bien/servicio, descripción, cantidad, unidad de medida, precio unitario, descuento, recargo, monto, ITBIS, impuestos adicionales, etc.
- **Retención** (`<Retencion>`): ITBIS/ISR retenido.
- **Minería** (`<Mineria>`): datos de minería (condicional).
- **Otra moneda detalle** (`<OtraMonedaDetalle>`).

## 5. Subtotales, Descuentos/Recargos y Paginación

- **Subtotales** (`<Subtotales>` / `<Subtotal>`): informativos.
- **Descuentos o Recargos** (`<DescuentosORecargos>`): globales, con tipo, valor, monto, indicador.
- **Paginación** (`<Paginacion>`): `<TotalPaginas>`, `<PaginaNo>`, rango de ítems.

## 6. Codificaciones relevantes

- **Monedas**: tabla II (incluye Peso Colombiano, Peso Mexicano, etc.).
- **Provincias y Municipios**: tabla III.
- **Unidad de medida**: tabla IV (Bandeja, Quintal, GRT, pie cuadrado, pasajero, pulgadas, parqueo barcos, etc.).
- **Tipo de ingreso** (01–06), **Tipo de pago** (1 Contado, 2 Crédito, 3 Gratuito), **Formas de pago** (1–8).

## 7. Validaciones clave

- e-NCF: 13 caracteres, secuencia autorizada por DGII, validar vencimiento.
- RNC emisor/comprador: validar en RNC.
- Fechas en formato dd-MM-AAAA.
- Montos: hasta 16 enteros y 2 decimales, ≥ 0.
- Facturas gratuitas (tipo pago 3) no válidas para crédito fiscal.
- Notas de crédito >30 días: indicador especial.
- Envío diferido: solo contribuyentes autorizados.
- Monto gravado incluido (ITBIS incluido en precio) condicional.
- Firma digital obligatoria para autenticidad e integridad.

## 8. Modelo de operación (TrackId)

- El emisor envía el e-CF a la DGII al momento de emisión.
- La DGII valida estructura (XSD), firma y asigna **TrackId** (identificador único de recepción).
- El receptor puede aprobar/rechazar comercialmente.
- No hay validez fiscal sin validación DGII.

## 9. Relevancia para el simulador

Campos mínimos ya validados por el simulador:
- Existencia de XML, nodo raíz, RNC emisor, e-NCF (inicia con E), tipo de comprobante, fecha de emisión, totales, no duplicado.

Para endurecer la validación (futuro), se puede usar los XSD oficiales (e-CF 31..47) descargados en `lib/xsd/` con `Nokogiri::XML::Schema`, activando `XSD_VALIDATION_ENABLED = true` en `Ecfs::ValidateXmlService`.

## 10. XSD descargados

En `lib/xsd/`: e-CF 31, 32, 33, 34, 41, 43, 44, 45, 46, 47 (v1.0). Pendiente: RFCE 32, ARECF, ANECF, ACECF, Semilla (si se requieren).