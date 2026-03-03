### [ ] Endpoint: POST /api/v1/marketplace/orders/complete

---

### 1. Descripción (Backend)

Confirma una compra y sus órdenes asociadas después de un pago exitoso.  
Actualiza los estados de:

- `PurchaseIntent` → `completed`
- `Purchase` → `confirmed`
- `Order` → `confirmed`
- `Cart` (opcional) → `completed`

Es idempotente: llamar varias veces con los mismos IDs solo re-aplica los mismos estados.

- **Método**: `POST`
- **URL**: `/api/v1/marketplace/orders/complete`
- **Auth**: Requiere JWT válido cuando es invocado desde frontend.

---

### 2. Request

#### Headers

- `Authorization: Bearer <access_token>`
- `Content-Type: application/json`

#### Body (JSON)

```json
{
  "purchase_id": 1,
  "order_ids": [1],
  "cart_id": 5
}
```

---

### 3. Responses (Backend)

#### 200 OK

```json
{
  "purchase": {
    "id": 1,
    "total_amount": "1850.00",
    "status": "confirmed",
    "purchase_number": "PUR-20260303181000-1"
  },
  "orders": [
    {
      "id": 1,
      "status": "confirmed",
      "total_amount": "1850.00"
    }
  ]
}
```

#### 422 Unprocessable Entity

```json
{
  "error": "Orders not found for purchase"
}
```

o

```json
{
  "error": "Purchase does not belong to current user"
}
```

---

### 4. Implementación (Backend)

- **Controller**: `Api::V1::Marketplace::OrdersController#complete`
  - Llama a `Marketplace::Orders::Complete.call(...)`.
  - Serializa `purchase` y `orders` con:
    - `PurchaseBlueprint`
    - `OrderBlueprint`

- **Interactor**: `Marketplace::Orders::Complete`
  - Entradas:
    - `purchase_id`
    - `order_ids`
    - `cart_id` (opcional)
    - `user` (opcional; se usa para validar propiedad cuando viene desde frontend)
  - Lógica:
    - Valida que la `Purchase` exista.
    - Si hay `user`, valida que la compra pertenezca al usuario.
    - Valida que los `Order` indicados pertenezcan a la `Purchase`.
    - Actualiza:
      - `purchase_intent.status = completed` (si existe).
      - `purchase.status = confirmed`.
      - `orders.status = confirmed`.
      - `cart.status = completed` (si se pasó `cart_id`).

---

### 5. Uso (Frontend)

Ejemplo de invocación tras recibir confirmación de pago desde el proveedor (si quieres confirmación explícita desde frontend además del webhook):

```ts
await fetch(
  `${process.env.NEXT_PUBLIC_API_URL}/api/v1/marketplace/orders/complete`,
  {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({
      purchase_id,
      order_ids: [orderId],
      cart_id,
    }),
  }
);
```

