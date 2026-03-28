### [X] Endpoint: POST /api/v1/marketplace/checkout/webhook

---

### 1. Descripción (Backend)

Webhook que recibe eventos de Wompi sobre cambios de estado de transacciones (`transaction.updated`).  
Conecta el evento de pago con:

- `Payment` interno
- `PurchaseIntent` / `Purchase`
- `Order` (vía interactor de `orders/complete` cuando el pago es aprobado)

- **Método**: `POST`
- **URL**: `/api/v1/marketplace/checkout/webhook`
- **Auth**: No requiere JWT (`skip_before_action :authenticate_user!`), pensado para ser consumido por el proveedor de pagos.

---

### 2. Request

#### Headers

- `Content-Type: application/json`
- `X-Event-Checksum: <checksum_sha256>` (opcional; también puede venir en `payload.signature.checksum`)

#### Body (JSON Wompi)

```json
{
  "event": "transaction.updated",
  "data": {
    "transaction": {
      "id": "1234-1610641025-49201",
      "reference": "c3d7e8c4-9c22-4e7f-9e22-8b3c7d0a1234",
      "status": "APPROVED",
      "amount_in_cents": 185000,
      "currency": "COP"
    }
  },
  "environment": "test",
  "signature": {
    "properties": [
      "transaction.id",
      "transaction.status",
      "transaction.amount_in_cents"
    ],
    "checksum": "sha256_checksum"
  },
  "timestamp": 1530291411
}
```

---

### 3. Responses (Backend)

#### 200 OK

Evento procesado correctamente. Respuesta vacía:

```http
HTTP/1.1 200 OK
```

#### 422 Unprocessable Entity

```json
{
  "error": "Invalid webhook signature"
}
```

o

```json
{
  "error": "Invalid webhook environment"
}
```

---

### 4. Implementación (Backend)

- **Controller**: `Api::V1::Marketplace::CheckoutController#webhook`
  - No requiere JWT.
  - Llama a `Marketplace::Checkout::Webhook.call(...)` pasando el payload completo y el header `X-Event-Checksum`.

- **Interactor**: `Marketplace::Checkout::Webhook`
  - Entradas:
    - `payload` (JSON completo de Wompi)
    - `header_checksum` (opcional)
  - Lógica:
    - Procesa solo `event == transaction.updated`.
    - Valida `environment` (`test`/`prod`) contra `WOMPI_ENV`.
    - Verifica firma SHA256:
      - concatena valores de `signature.properties` (resueltos dinámicamente sobre `data`),
      - concatena `timestamp`,
      - concatena `WOMPI_EVENTS_SECRET`,
      - compara con checksum del header o del payload.
    - Busca `Payment` por `provider_payment_id` (idempotencia), o por `external_reference` si aún no está enlazado.
    - Actualiza:
      - `provider_payment_id` (`transaction.id`)
      - `amount` (convierte de centavos a moneda)
      - `currency`
      - `status` interno mapeado:
        - `APPROVED` -> `approved`
        - `DECLINED`, `VOIDED`, `ERROR` -> `rejected`
        - otro → `pending`
      - `raw_payload` (merge en `wompi_event`).
    - Si el pago queda en estado `approved`:
      - ejecuta `Marketplace::Orders::Complete.call(...)`.

---

### 5. Notas de operación

- Wompi reintenta webhooks cuando no recibe `200`. Por eso el handler debe permanecer idempotente.
- No usar la redirección de frontend como fuente oficial de confirmación de pago; la fuente es webhook válido.
- Configurar URL de webhook separada por ambiente (`sandbox` y `production`) en dashboard Wompi.

