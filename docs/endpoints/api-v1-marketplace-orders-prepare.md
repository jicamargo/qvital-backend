### [ ] Endpoint: POST /api/v1/marketplace/orders/prepare

---

### 1. Descripción (Backend)

Prepara el checkout completo a partir de los items del carrito y los datos de envío.  
Crea o actualiza:

- `PurchaseIntent` (con `external_reference`)
- `Purchase`
- `PurchaseItems`
- `Order` (única, debido a un solo seller interno)

Y devuelve todo lo necesario para que el frontend inicie el flujo de pago.

- **Método**: `POST`
- **URL**: `/api/v1/marketplace/orders/prepare`
- **Auth**: Requiere JWT válido.

> Idempotencia: si se envía `purchase_intent_id`, el backend reutiliza y actualiza la misma intención/compra en lugar de crear nuevas.

---

### 2. Request

#### Headers

- `Authorization: Bearer <access_token>`
- `Content-Type: application/json`

#### Body (JSON)

```json
{
  "cart_items": [
    {
      "product_id": 3,
      "quantity": 2,
      "price": "850.00",
      "metadata": {
        "name": "Proteína Herbal",
        "category": "Proteínas"
      }
    }
  ],
  "shipping_address": {
    "street": "Calle 123",
    "city": "CDMX",
    "state": "CDMX",
    "zipCode": "01000",
    "phone": "+52 55 0000 0000"
  },
  "recipient_info": {
    "is_different": true,
    "name": "Nombre Receptor",
    "phone": "+52 55 1111 1111"
  },
  "selected_date": "2026-03-10",
  "shipping_cost": "150.00",
  "payment_method": "credit_card",
  "purchase_intent_id": null
}
```

---

### 3. Responses (Backend)

#### 200 OK

```json
{
  "purchase_intent": {
    "id": 1,
    "external_reference": "c3d7e8c4-9c22-4e7f-9e22-8b3c7d0a1234",
    "status": "pending",
    "total_amount": "1850.00",
    "created_at": "2026-03-03T18:10:00Z",
    "updated_at": "2026-03-03T18:10:00Z"
  },
  "purchase": {
    "id": 1,
    "total_amount": "1850.00",
    "subtotal_amount": "1700.00",
    "tax_amount": "0.00",
    "shipping_cost": "150.00",
    "status": "pending",
    "purchase_number": "PUR-20260303181000-1",
    "shipping_address": {
      "street": "Calle 123",
      "city": "CDMX",
      "state": "CDMX",
      "zipCode": "01000",
      "phone": "+52 55 0000 0000"
    },
    "recipient_name": "Nombre Receptor",
    "recipient_phone": "+52 55 1111 1111",
    "purchase_items": [
      {
        "id": 1,
        "quantity": 2,
        "unit_price": "850.00",
        "line_subtotal": "1700.00",
        "line_tax": "0.00",
        "line_total": "1700.00",
        "metadata": {
          "name": "Proteína Herbal"
        },
        "product": {
          "id": 3,
          "name": "Proteína Herbal",
          "price": 850.0
        }
      }
    ]
  },
  "orders": [
    {
      "id": 1,
      "status": "pending",
      "total_amount": "1850.00",
      "shipping_date_estimated": "2026-03-10T00:00:00Z",
      "shipping_date_real": null,
      "tracking_info": {},
      "order_items": []
    }
  ],
  "external_reference": "c3d7e8c4-9c22-4e7f-9e22-8b3c7d0a1234"
}
```

#### 422 Unprocessable Entity

```json
{
  "error": "Cart items are required"
}
```

---

### 4. Implementación (Backend)

- **Controller**: `Api::V1::Marketplace::OrdersController#prepare`
  - Usa `Marketplace::Orders::Prepare.call(...)`
  - Serializa con:
    - `PurchaseIntentBlueprint`
    - `PurchaseBlueprint`
    - `OrderBlueprint`

- **Interactor**: `Marketplace::Orders::Prepare`
  - Entradas:
    - `user`
    - `cart_items`
    - `shipping_address`
    - `recipient_info`
    - `selected_date`
    - `shipping_cost`
    - `payment_method` (opcional)
    - `purchase_intent_id` (opcional, para idempotencia)
  - Responsabilidades:
    - Calcular `subtotal`, `tax_amount` (por ahora `0`), `total_amount`.
    - Crear o reutilizar `PurchaseIntent` (status `pending`, `external_reference` UUID).
    - Crear o reutilizar `Purchase` y actualizar montos y datos de envío.
    - Recrear los `PurchaseItems` a partir de `cart_items`.
    - Crear o reutilizar una única `Order` asociada al `Purchase`.

- **Blueprints**:
  - `PurchaseIntentBlueprint`
  - `PurchaseBlueprint`
  - `PurchaseItemBlueprint`
  - `OrderBlueprint`

---

### 5. Uso (Frontend)

Ejemplo de llamada desde Next.js:

```ts
const response = await fetch(
  `${process.env.NEXT_PUBLIC_API_URL}/api/v1/marketplace/orders/prepare`,
  {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify(payload), // ver estructura arriba
  }
);

const data = await response.json();
const externalReference = data.external_reference;
```

