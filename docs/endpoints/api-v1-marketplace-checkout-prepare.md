### [ ] Endpoint: POST /api/v1/marketplace/checkout/prepare

---

### 1. Descripción (Backend)

Prepara el checkout con el **proveedor de pagos** usando la `external_reference` generada en `/orders/prepare`.  
En este MVP:

- No se llama todavía a un proveedor real.
- Se simula la creación de una preferencia de pago (`preference_id`, `init_point`).
- Se registra/actualiza un `Payment` interno con estado `pending`.

- **Método**: `POST`
- **URL**: `/api/v1/marketplace/checkout/prepare`
- **Auth**: Requiere JWT válido.

---

### 2. Request

#### Headers

- `Authorization: Bearer <access_token>`
- `Content-Type: application/json`

#### Body (JSON)

```json
{
  "external_reference": "c3d7e8c4-9c22-4e7f-9e22-8b3c7d0a1234",
  "payer": {
    "name": "Nombre Cliente",
    "email": "cliente@example.com",
    "phone": "+52 55 0000 0000",
    "document": "CURP/ID"
  },
  "order": {
    "amount": "1850.00",
    "currency": "MXN",
    "provider": "mock_provider"
  }
}
```

---

### 3. Responses (Backend)

#### 200 OK

```json
{
  "payment": {
    "id": 1,
    "external_reference": "c3d7e8c4-9c22-4e7f-9e22-8b3c7d0a1234",
    "provider": "mock_provider",
    "provider_payment_id": null,
    "provider_preference_id": "88c11dd0-5a9f-4e53-8da1-2a0b9b31b999",
    "status": "pending",
    "amount": "1850.00",
    "currency": "MXN",
    "raw_payload": {
      "payer": {
        "name": "Nombre Cliente",
        "email": "cliente@example.com"
      },
      "order": {
        "amount": "1850.00",
        "currency": "MXN",
        "provider": "mock_provider"
      }
    }
  },
  "preference_id": "88c11dd0-5a9f-4e53-8da1-2a0b9b31b999",
  "init_point": "https://payments.qvital.local/checkout/88c11dd0-5a9f-4e53-8da1-2a0b9b31b999"
}
```

#### 422 Unprocessable Entity

```json
{
  "error": "Purchase intent not found for external_reference"
}
```

---

### 4. Implementación (Backend)

- **Controller**: `Api::V1::Marketplace::CheckoutController#prepare`
  - Llama a `Marketplace::Checkout::Prepare.call(...)`
  - Serializa el `Payment` con `PaymentBlueprint`.

- **Interactor**: `Marketplace::Checkout::Prepare`
  - Entradas:
    - `external_reference`
    - `payer` (nombre, email, teléfono, documento)
    - `order` (monto, moneda, proveedor)
  - Lógica:
    - Busca `PurchaseIntent` por `external_reference`.
    - Obtiene su `Purchase` y extrae `total_amount`.
    - Genera `preference_id` e `init_point` simulados.
    - Crea o actualiza `Payment` con estado `pending`.

---

### 5. Uso (Frontend)

Ejemplo tras recibir la respuesta de `/orders/prepare`:

```ts
const response = await fetch(
  `${process.env.NEXT_PUBLIC_API_URL}/api/v1/marketplace/checkout/prepare`,
  {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({
      external_reference,
      payer,
      order: {
        amount: purchase.total_amount,
        currency: "MXN",
        provider: "mock_provider",
      },
    }),
  }
);

const data = await response.json();
// data.init_point → usar para redirigir / inicializar SDK de pago
```

