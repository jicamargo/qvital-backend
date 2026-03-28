### [X] Endpoint: POST /api/v1/marketplace/checkout/prepare

---

### 1. Descripción (Backend)

Prepara el checkout de Wompi (Web Checkout) usando la `external_reference` generada en `/orders/prepare`.
El backend:

- Construye los campos firmados para `https://checkout.wompi.co/p/`.
- Calcula firma de integridad (`signature:integrity`) en servidor.
- Persiste/actualiza un `Payment` interno en estado `pending`.

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
    "currency": "COP",
    "provider": "wompi"
  },
  "shipping_address": {
    "street": "Calle 123 #45-67",
    "city": "Bogota",
    "state": "Cundinamarca",
    "zipCode": "110111",
    "phone": "3001112233"
  },
  "recipient_info": {
    "name": "Nombre Receptor",
    "phone": "3001112233"
  },
  "expiration_time": "2026-03-31T23:59:59.000Z"
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
    "provider": "wompi",
    "provider_payment_id": null,
    "provider_preference_id": "c3d7e8c4-9c22-4e7f-9e22-8b3c7d0a1234",
    "status": "pending",
    "amount": "1850.00",
    "currency": "COP",
    "raw_payload": {
      "payer": {
        "name": "Nombre Cliente",
        "email": "cliente@example.com"
      },
      "order": {
        "amount": "1850.00",
        "currency": "COP",
        "provider": "wompi"
      },
      "wompi_checkout": {
        "checkout_url": "https://checkout.wompi.co/p/",
        "fields": {
          "public-key": "pub_test_xxx",
          "currency": "COP",
          "amount-in-cents": "185000",
          "reference": "c3d7e8c4-9c22-4e7f-9e22-8b3c7d0a1234",
          "signature:integrity": "sha256_hash",
          "redirect-url": "https://app.local/marketplace/checkout/result"
        }
      }
    }
  },
  "checkout_url": "https://checkout.wompi.co/p/",
  "fields": {
    "public-key": "pub_test_xxx",
    "currency": "COP",
    "amount-in-cents": "185000",
    "reference": "c3d7e8c4-9c22-4e7f-9e22-8b3c7d0a1234",
    "signature:integrity": "sha256_hash",
    "redirect-url": "https://app.local/marketplace/checkout/result"
  }
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
    - `shipping_address` (opcional)
    - `recipient_info` (opcional)
    - `expiration_time` (opcional)
  - Lógica:
    - Busca `PurchaseIntent` por `external_reference`.
    - Obtiene su `Purchase` y calcula `amount-in-cents`.
    - Construye campos de Wompi con `Wompi::CheckoutPrepare`.
    - Firma integridad con `WOMPI_INTEGRITY_SECRET`.
    - Crea o actualiza `Payment` (`provider = wompi`, `status = pending`).

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
        currency: "COP",
        provider: "wompi",
      },
    }),
  }
);

const data = await response.json();
// Crear formulario HTML con method GET y action = data.checkout_url
// Inyectar cada par key/value de data.fields como <input hidden />
// Submit programatico del formulario a Wompi Checkout Web
```

