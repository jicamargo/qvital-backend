# Requerimientos de Integración Wompi Checkout (Web Checkout)

## Estado del documento

- [X] Documento técnico de Wompi analizado y plan inicial definido.
- [ ] Integración implementada y validada end-to-end en Sandbox.
- [ ] Integración implementada y validada end-to-end en Producción.

---

## 1) Objetivo

Implementar pagos en el marketplace de QVITAL usando **Wompi Web Checkout** (redirección a `checkout.wompi.co/p/`), **sin usar Widget**.

Este plan separa responsabilidades de:

- **Frontend** (Next.js, este repositorio).
- **Backend** (Rails API).

---

## 2) Alcance y decisiones

- Se usará **Checkout Web por formulario HTML** con método `GET` hacia Wompi.
- La lógica sensible (firma de integridad, validaciones de monto/referencia, verificación de eventos) se ejecuta en **backend**.
- La redirección de Wompi se usa solo para UX/información; la confirmación oficial del pago se hace por **webhook** (`transaction.updated`).
- Moneda única: **COP**.

No incluye:

- Integración vía Widget.
- Recurrentes/tokenización avanzada.

---

## 3) Flujos funcionales

## 3.1 Flujo de pago (alto nivel)

1. Frontend prepara pedido (`/orders/prepare`) y obtiene `external_reference`, `purchase`, `orders`.
2. Frontend llama backend (`/checkout/prepare`) para obtener parámetros de Wompi Checkout Web.
3. Frontend construye formulario oculto y redirige al usuario a `https://checkout.wompi.co/p/`.
4. Usuario paga en Wompi.
5. Wompi:
   - Redirige al frontend con `?id=<transaction_id>` (informativo).
   - Envía webhook al backend con el estado final (`transaction.updated`).
6. Backend valida firma del evento, actualiza pago interno y confirma orden (`orders/complete`) cuando aplique.
7. Frontend consulta backend para estado final y muestra confirmación/rechazo/pending.

## 3.2 Flujo de verificación de seguridad

- Firma de integridad checkout:
  - SHA256 de `reference + amount_in_cents + currency + [expiration_time opcional] + integrity_secret`.
- Firma de webhook:
  - SHA256 concatenando:
    1. valores de `signature.properties` (tomados dinámicamente del payload),
    2. `timestamp`,
    3. `events_secret`.
  - Comparar contra `signature.checksum` o header `X-Event-Checksum`.

---

## 4) Variables de entorno

## 4.1 Frontend (Next.js)

Archivo sugerido: `.env.local`

- [X] `NEXT_PUBLIC_API_URL=http://localhost:3001`
- [X] `NEXT_PUBLIC_APP_URL=http://localhost:3000`
- [X] `NEXT_PUBLIC_WOMPI_CHECKOUT_URL=https://checkout.wompi.co/p/`  
  (Opcional si la URL viene siempre desde backend).
- [X] `NEXT_PUBLIC_WOMPI_ENV=sandbox`  
  (`sandbox` o `production`, solo para comportamiento visual/logs en FE).

## 4.2 Backend (Rails API)

Archivo sugerido: `.env` / credenciales seguras por ambiente.

- [X] `WOMPI_ENV=sandbox`  
  (`sandbox` o `production`).
- [X] `WOMPI_PUBLIC_KEY=pub_test_XXXXXXXXXXXXXXXXXXXXXXXX`
- [X] `WOMPI_PRIVATE_KEY=prv_test_XXXXXXXXXXXXXXXXXXXXXXXX`  
  (recomendado para operaciones de API y futuros casos).
- [X] `WOMPI_INTEGRITY_SECRET=test_integrity_XXXXXXXXXXXXXXXXXXXXXXXX`
- [X] `WOMPI_EVENTS_SECRET=test_events_XXXXXXXXXXXXXXXXXXXXXXXX`
- [X] `WOMPI_CHECKOUT_URL=https://checkout.wompi.co/p/`
- [X] `WOMPI_API_BASE_URL=https://sandbox.wompi.co/v1`
- [X] `WOMPI_REDIRECT_URL=http://localhost:3000/marketplace/checkout/result`
- [X] `WOMPI_WEBHOOK_URL=https://api.tudominio.com/api/v1/marketplace/checkout/webhook`

Notas:

- En producción, cambiar a prefijos `pub_prod_`, `prv_prod_`, `prod_integrity_`, `prod_events_`.
- `WOMPI_WEBHOOK_URL` debe ser HTTPS público y configurado en dashboard de Wompi.

---

## 5) Contratos sugeridos de backend (Rails)

## 5.1 `POST /api/v1/marketplace/checkout/prepare`

Entrada:

- `external_reference` (de `orders/prepare`).
- opcional: `expiration_time`.

Salida:

- `checkout_url` (`https://checkout.wompi.co/p/`).
- `fields` para form:
  - `public-key`
  - `currency` (`COP`)
  - `amount-in-cents`
  - `reference`
  - `signature:integrity`
  - `redirect-url`
  - opcionales:
    - `expiration-time`
    - `customer-data:*`
    - `shipping-address:*`
    - `collect-shipping`

## 5.2 `POST /api/v1/marketplace/checkout/webhook`

Responsabilidades:

- Validar checksum de evento.
- Procesar solo eventos válidos de ambiente correcto.
- Manejo idempotente por `transaction.id`.
- Actualizar `payments` y estado de `purchase/orders`.
- Si estado final aprobado: ejecutar lógica de `orders/complete`.

## 5.3 `GET /api/v1/marketplace/checkout/status`

Entrada:

- `transaction_id` o `external_reference`.

Salida:

- Estado normalizado interno: `pending | approved | declined | voided | error`.
- Datos mínimos para UI de resultado.

---

## 6) Plan de ejecución (checklist)

## 6.1 FRONTEND (Next.js)

- [ ] Crear página/flujo de resultado de checkout (`/marketplace/checkout/result`) para leer `id` de transacción desde querystring.
- [ ] Conectar llamada actual `checkout/prepare` para consumir estructura real de Wompi checkout web (`checkout_url + fields`).
- [ ] Construir formulario HTML oculto con `method="GET"` y `action=checkout_url` y hacer submit programático.
- [ ] Enviar solo datos provenientes de backend (evitar cálculo de firma en frontend).
- [ ] Mostrar estados UX:
  - [ ] redireccionando a Wompi,
  - [ ] verificando pago,
  - [ ] aprobado,
  - [ ] rechazado/error.
- [ ] Implementar polling corto (si aplica) en pantalla de resultado contra endpoint de estado backend.
- [ ] Mantener modal/confirmación visual consistente con diseño actual.
- [ ] Manejar reintentos de pago desde UI (botón reintentar con nueva referencia si negocio lo define).
- [ ] Agregar tracking/logs frontend para diagnóstico (sin exponer secretos).
- [ ] Pruebas manuales FE en Sandbox (aprobado/declinado/error).

## 6.2 BACKEND (Rails API)

- [X] Implementar servicio `Wompi::CheckoutPrepare` para:
  - [X] cargar compra por `external_reference`,
  - [X] calcular `amount_in_cents`,
  - [X] generar `reference` única idempotente,
  - [X] calcular `signature:integrity` con `WOMPI_INTEGRITY_SECRET`,
  - [X] devolver `checkout_url + fields`.
- [X] Ajustar `Marketplace::Checkout::Prepare` para usar `Wompi::CheckoutPrepare` real (reemplazar mock).
- [X] Persistir intento de pago (`payments`) con estado `pending` antes de redirección.
- [X] Implementar verificación de webhook:
  - [X] extraer `signature.properties`,
  - [X] concatenar valores + `timestamp` + `WOMPI_EVENTS_SECRET`,
  - [X] calcular SHA256 y comparar checksum.
- [X] Rechazar eventos con firma inválida o ambiente no esperado.
- [X] Implementar idempotencia estricta para eventos repetidos/reintentos de notificación.
- [X] Mapear estado Wompi a estado interno:
  - [X] `APPROVED` -> pago aprobado / completar orden,
  - [X] `DECLINED` -> pago rechazado,
  - [X] `VOIDED` -> pago anulado,
  - [X] `ERROR` -> error de pago.
- [X] Invocar `orders/complete` solo en estado aprobado y de forma idempotente.
- [X] Exponer endpoint de consulta de estado para FE.
- [X] Registrar auditoría (`raw_payload`, `transaction_id`, `reference`, timestamps).
- [x] Configurar URL webhook por ambiente en dashboard Wompi.
- [ ] Pruebas manuales BE en Sandbox (firma válida/ inválida, estados finales, duplicidad de eventos).

## 6.3 Integración end-to-end

- [ ] Probar flujo completo: carrito -> checkout -> redirección Wompi -> webhook -> confirmación de orden.
- [ ] Validar que no se confirmen órdenes por redirección sin webhook válido.
- [ ] Validar comportamiento con latencia y reintentos de webhook.
- [ ] Validar consistencia de referencia única por intento de pago.
- [ ] Validar transición de estados en `purchase`, `order`, `payment` y `cart`.

---

## 7) Criterios de aceptación

- [ ] El frontend redirige a Wompi Web Checkout usando parámetros firmados por backend.
- [ ] El backend valida firma de webhook y procesa solo eventos auténticos.
- [ ] La orden se confirma únicamente con evento de pago aprobado.
- [ ] El usuario ve resultado claro (aprobado/rechazado/pendiente) en frontend.
- [ ] La integración funciona en Sandbox y luego en Producción cambiando llaves/URLs por ambiente.

---

## 8) Riesgos y mitigaciones

- [ ] **Riesgo:** usar redirección como verdad de pago.  
      **Mitigación:** usar webhook + validación de firma como fuente oficial.
- [ ] **Riesgo:** duplicación por reintentos de webhook o reintentos de pago.  
      **Mitigación:** idempotencia por `transaction.id` y `reference`.
- [ ] **Riesgo:** exposición de secretos en frontend.  
      **Mitigación:** firma y verificación solo en backend.
- [ ] **Riesgo:** mezcla de sandbox/prod.  
      **Mitigación:** variables separadas por ambiente y validaciones de `environment` en webhook.

