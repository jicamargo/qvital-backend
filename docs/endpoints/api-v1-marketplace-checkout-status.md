### [X] Endpoint: GET /api/v1/marketplace/checkout/status

---

### 1. Descripcion (Backend)

Consulta el estado de una transaccion de checkout para que frontend muestre el resultado final del pago.

- **Metodo**: `GET`
- **URL**: `/api/v1/marketplace/checkout/status`
- **Auth**: Requiere JWT valido.

---

### 2. Request

#### Query params

Se debe enviar al menos uno:

- `transaction_id` (id Wompi)
- `external_reference` (referencia interna de compra)

Ejemplos:

- `/api/v1/marketplace/checkout/status?transaction_id=1234-1610641025-49201`
- `/api/v1/marketplace/checkout/status?external_reference=c3d7e8c4-9c22-4e7f-9e22-8b3c7d0a1234`

---

### 3. Responses (Backend)

#### 200 OK

```json
{
  "status": "approved",
  "provider_status": "APPROVED",
  "transaction_id": "1234-1610641025-49201",
  "external_reference": "c3d7e8c4-9c22-4e7f-9e22-8b3c7d0a1234",
  "amount": "1850.0",
  "currency": "COP"
}
```

Estados normalizados posibles:

- `pending`
- `approved`
- `declined`
- `voided`
- `error`

#### 422 Unprocessable Entity

```json
{
  "error": "transaction_id or external_reference is required"
}
```

o

```json
{
  "error": "Payment not found"
}
```

---

### 4. Implementacion (Backend)

- **Controller**: `Api::V1::Marketplace::CheckoutController#status`
  - Llama a `Marketplace::Checkout::Status.call(...)`.

- **Interactor**: `Marketplace::Checkout::Status`
  - Busca primero `Payment` local (`provider = wompi`) por `transaction_id` o `external_reference`.
  - Si no existe local y viene `transaction_id`, consulta Wompi API (`GET /v1/transactions/:id`) usando `Wompi::Client`.
  - Normaliza estados de proveedor a contrato frontend.

---
