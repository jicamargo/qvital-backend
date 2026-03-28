### [X] Endpoint: GET /api/v1/marketplace/orders

---

### 1. Descripción (Backend)

Retorna el listado de pedidos del usuario autenticado para la vista **Mis pedidos**.

- **Método**: `GET`
- **URL**: `/api/v1/marketplace/orders`
- **Auth**: Requiere JWT válido.

---

### 2. Request

#### Headers

- `Authorization: Bearer <access_token>`

#### Query params (opcionales)

- `status`: filtra por estado de orden (`pending`, `confirmed`, `shipped`, `delivered`, `cancelled`)
- `page`: página (default `1`)
- `per_page`: cantidad por página (default `20`, máximo `50`)

Ejemplo:

`GET /api/v1/marketplace/orders?status=confirmed&page=1&per_page=10`

---

### 3. Responses (Backend)

#### 200 OK

```json
{
  "orders": [
    {
      "id": 15,
      "status": "confirmed",
      "total_amount": "425410.0",
      "shipping_date_estimated": "2026-03-24T00:00:00.000Z",
      "shipping_date_real": null,
      "tracking_info": {},
      "created_at": "2026-03-23T22:14:25.949Z",
      "updated_at": "2026-03-23T22:39:17.813Z",
      "order_items": [],
      "purchase": {
        "id": 15,
        "purchase_number": "PUR-20260323221424-1",
        "status": "confirmed",
        "total_amount": "425410.0",
        "external_reference": "f8711087-3708-4c28-ba3e-1871d986445e"
      },
      "latest_payment": {
        "provider": "wompi",
        "status": "approved",
        "provider_payment_id": "12045125-1774305546-82671",
        "amount": "425410.0",
        "currency": "COP",
        "updated_at": "2026-03-23T22:39:16.692Z"
      }
    }
  ],
  "pagination": {
    "page": 1,
    "per_page": 20,
    "total": 1
  }
}
```

#### 422 Unprocessable Entity

```json
{
  "error": "Invalid status filter"
}
```

---

### 4. Implementación (Backend)

- **Controller**: `Api::V1::Marketplace::OrdersController#index`
  - Llama a `Marketplace::Orders::List.call(...)`.
  - Devuelve `orders` + `pagination`.

- **Interactor**: `Marketplace::Orders::List`
  - Filtra por `user_id` (solo pedidos del usuario autenticado).
  - Soporta filtro opcional por `status`.
  - Aplica paginación (`page`, `per_page`).
  - Precarga asociaciones para evitar N+1:
    - `order_items -> product -> category`
    - `purchase -> purchase_intent`
    - `purchase -> payments`

---
