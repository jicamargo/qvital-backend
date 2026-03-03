### [ ] Endpoint: POST /api/v1/marketplace/checkout/webhook

---

### 1. Descripción (Backend)

Webhook/callback que recibe las notificaciones del proveedor de pagos sobre el estado de una transacción.  
Conecta el evento de pago con:

- `Payment` interno
- `PurchaseIntent` / `Purchase`
- `Order` (vía interactor de `orders/complete` cuando el pago es aprobado)

> En este MVP, el endpoint acepta un payload genérico; cuando se integre un proveedor real se adaptará el mapeo.

- **Método**: `POST`
- **URL**: `/api/v1/marketplace/checkout/webhook`
- **Auth**: No requiere JWT (`skip_before_action :authenticate_user!`), pensado para ser consumido por el proveedor de pagos.

---

### 2. Request

#### Headers

- `Content-Type: application/json`

#### Body (JSON genérico)

```json
{
  "external_reference": "c3d7e8c4-9c22-4e7f-9e22-8b3c7d0a1234",
  "provider": "mock_provider",
  "status": "approved",
  "provider_payment_id": "pay_123",
  "amount": "1850.00",
  "other_fields_from_provider": {}
}
```

---

### 3. Responses (Backend)

#### 200 OK

Señal de que el webhook fue procesado correctamente. Respuesta vacía:

```http
HTTP/1.1 200 OK
```

#### 422 Unprocessable Entity

```json
{
  "error": "Unexpected error processing payment webhook"
}
```

---

### 4. Implementación (Backend)

- **Controller**: `Api::V1::Marketplace::CheckoutController#webhook`
  - No requiere JWT.
  - Llama a `Marketplace::Checkout::Webhook.call(...)` pasando todo el payload como `raw_payload`.

- **Interactor**: `Marketplace::Checkout::Webhook`
  - Entradas:
    - `external_reference`
    - `provider`
    - `status` (string del proveedor)
    - `provider_payment_id`
    - `amount` (opcional)
    - `raw_payload` (JSON completo recibido)
  - Lógica:
    - Busca o crea `Payment` por `external_reference` + `provider`.
    - Actualiza:
      - `provider_payment_id`
      - `amount` (si viene)
      - `status` interno mapeado:
        - `"approved"`, `"succeeded"` → `approved`
        - `"rejected"`, `"failed"` → `rejected`
        - otro → `pending`
      - `raw_payload` (merge con payload previo).
    - Si el pago queda en estado `approved`:
      - Obtiene la `Purchase` (`payment.purchase`) y su `Order`.
      - Llama internamente a `Marketplace::Orders::Complete.call(...)` para marcar la orden como `confirmed`.

---

### 5. Notas para integración futura con proveedor real

- Adaptar el mapeo de `status` según los valores reales del proveedor (ej. `approved`, `in_process`, `rejected` en Mercado Pago).
- Ajustar los campos esperados en el body (`id` de pago, tipo de evento, etc.).
- Agregar validación de firma/hmac si el proveedor lo soporta.

