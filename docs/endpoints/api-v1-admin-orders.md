# Admin – Pedidos (`/api/v1/admin/orders`)

## Descripción general

Endpoints para que un **administrador** liste, consulte y actualice **todas** las órdenes del marketplace (`orders` ligadas a `purchases`). Los clientes siguen usando solo `GET /api/v1/marketplace/orders` (solo sus pedidos); estos endpoints **no** sustituyen el marketplace.

- **Autenticación**: JWT Supabase (mismo flujo que el resto de la API).
- **Autorización**: `current_user.role == "admin"`.

---

## Autenticación y autorización

Headers obligatorios:

```http
Authorization: Bearer <access_token>
Content-Type: application/json
```

Errores habituales:

| Código | Significado |
|--------|-------------|
| `401 Unauthorized` | Token ausente o inválido |
| `403 Forbidden` | Usuario autenticado pero no es `admin` |

---

## 1. GET /api/v1/admin/orders

Listado paginado de todas las órdenes.

### Query params (opcionales)

| Parámetro | Tipo | Descripción |
|-----------|------|-------------|
| `status` | string | Filtro por estado de la orden: `pending`, `confirmed`, `shipped`, `delivered`, `cancelled` |
| `page` | integer | Página (default `1`) |
| `per_page` | integer | Tamaño de página (default `20`, máximo `50`) |
| `search` | string | Busca en `users.email`, `purchases.purchase_number` y `purchase_intents.external_reference` (ILIKE, subcadena) |
| `from` | string (ISO 8601 / fecha parseable) | Inicio inclusive del rango por `orders.created_at` |
| `to` | string (ISO 8601 / fecha parseable) | Fin inclusive del rango por `orders.created_at` (se usa fin del día en la zona horaria de la app) |

Ejemplo:

```http
GET /api/v1/admin/orders?status=shipped&page=1&per_page=20&search=PUR-2026
Authorization: Bearer <token_admin>
```

### Response 200 OK

Misma forma base que el listado de marketplace, más el bloque `customer` cuando la compra tiene usuario asociado:

```json
{
  "orders": [
    {
      "id": 19,
      "status": "pending",
      "total_amount": "210460.0",
      "shipping_date_estimated": "2026-03-24T00:00:00.000Z",
      "shipping_date_real": null,
      "tracking_info": {},
      "created_at": "2026-03-23T23:10:48.624Z",
      "updated_at": "2026-03-23T23:10:48.624Z",
      "order_items": [],
      "customer": {
        "id": 1,
        "email": "cliente@example.com",
        "name": "Nombre cliente"
      },
      "purchase": {
        "id": 19,
        "purchase_number": "PUR-20260323231045-1",
        "status": "pending",
        "total_amount": "210460.0",
        "external_reference": "24605567-9199-4aae-bff0-75064af4c06c"
      },
      "latest_payment": {
        "provider": "wompi",
        "status": "pending",
        "provider_payment_id": null,
        "amount": "210460.0",
        "currency": "COP",
        "updated_at": "2026-03-23T23:11:00.662Z"
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

Si la compra no tiene `user_id`, `customer` puede ser `null`.

### Response 422 Unprocessable Entity

Filtro de estado inválido o fechas `from` / `to` no parseables:

```json
{
  "error": "Invalid status filter"
}
```

---

## 2. GET /api/v1/admin/orders/:id

Detalle de una orden para operación / soporte.

### Response 200 OK

```json
{
  "order": {
    "id": 19,
    "status": "pending",
    "total_amount": "210460.0",
    "shipping_date_estimated": "2026-03-24T00:00:00.000Z",
    "shipping_date_real": null,
    "tracking_info": {},
    "created_at": "2026-03-23T23:10:48.624Z",
    "updated_at": "2026-03-23T23:10:48.624Z",
    "order_items": []
  },
  "customer": {
    "id": 1,
    "email": "cliente@example.com",
    "supabase_uid": "…",
    "role": "cliente",
    "name": "Nombre cliente",
    "hlf_id": null,
    "level_id": 1,
    "level": {},
    "app_metadata": { "role": "cliente" }
  },
  "purchase": {
    "id": 19,
    "total_amount": "210460.0",
    "subtotal_amount": "210460.0",
    "tax_amount": "0.0",
    "shipping_cost": "0.0",
    "status": "pending",
    "purchase_number": "PUR-20260323231045-1",
    "shipping_address": {},
    "recipient_name": "…",
    "recipient_phone": "…",
    "created_at": "…",
    "updated_at": "…",
    "purchase_items": []
  },
  "purchase_intent": {
    "id": 19,
    "external_reference": "24605567-9199-4aae-bff0-75064af4c06c",
    "status": "pending",
    "total_amount": "210460.0",
    "created_at": "…",
    "updated_at": "…"
  },
  "payments": []
}
```

`payments` usa el blueprint de pagos (incluye `raw_payload` tal como se persistió).

### Response 404 Not Found

```json
{
  "error": "Order not found"
}
```

---

## 3. PATCH /api/v1/admin/orders/:id

Actualización parcial de campos operativos de la orden. El cuerpo debe incluir la clave raíz `order` (mismo criterio que admin productos).

### Request body

Campos permitidos (todos opcionales en un mismo PATCH):

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `status` | string | Uno de: `pending`, `confirmed`, `shipped`, `delivered`, `cancelled` |
| `shipping_date_estimated` | string (ISO 8601) o `null` | Fecha estimada de envío |
| `shipping_date_real` | string (ISO 8601) o `null` | Fecha real de envío |
| `tracking_info` | object JSON | Reemplaza por completo el JSON de seguimiento almacenado en la orden |

Ejemplo:

```http
PATCH /api/v1/admin/orders/19
Authorization: Bearer <token_admin>
Content-Type: application/json

{
  "order": {
    "status": "shipped",
    "shipping_date_real": "2026-03-25T15:00:00Z",
    "tracking_info": {
      "carrier": "COORDINADORA",
      "tracking_number": "123456789"
    }
  }
}
```

### Response 200 OK

Devuelve el mismo shape que `GET /api/v1/admin/orders/:id` (detalle completo recargado).

### Response 404 Not Found

Orden inexistente.

### Response 422 Unprocessable Entity

Estado inválido o error de validación al guardar:

```json
{
  "error": "Invalid status",
  "details": {}
}
```

```json
{
  "error": "Validation failed",
  "details": { "status": ["…"] }
}
```

### Response 400 Bad Request

Falta la clave `order` en el JSON:

```json
{
  "error": "param is missing or the value is empty: order"
}
```

---

## 4. POST /api/v1/admin/orders/:id/check_wompi_status

Consulta en Wompi (por `reference`, usando `GET /v1/transactions?reference=...`) el estado real de la transacción asociada a la `purchase_intent.external_reference` de la orden, y lo compara contra el pago local. No modifica nada — solo informa.

### Response 200 OK

```json
{
  "external_reference": "1ad5b213-6dde-4188-b7c1-0b28e09436c8",
  "local_status": "pending",
  "wompi_transaction": {
    "id": "12045125-1785004870-29542",
    "status": "APPROVED",
    "amount_in_cents": 25056400,
    "currency": "COP",
    "created_at": "2026-07-25T18:41:11.289Z"
  },
  "mismatch": true
}
```

- `local_status`: estado de la `purchase` en la app (`pending`, `confirmed`, `cancelled`).
- `wompi_transaction`: la transacción aprobada si existe alguna con esa referencia; si no, la más reciente. `null` si Wompi no tiene ninguna transacción con esa referencia.
- `mismatch`: `true` cuando Wompi tiene una transacción `APPROVED` pero localmente no hay un pago aprobado.

### Response 422 Unprocessable Entity

```json
{ "error": "Order not found" }
```

```json
{ "error": "Purchase has no external_reference" }
```

---

## 5. POST /api/v1/admin/orders/:id/reconcile_wompi_payment

Cuando `check_wompi_status` reporta `mismatch: true`, este endpoint aplica la corrección: busca la transacción `APPROVED` en Wompi para la misma referencia y reproduce localmente el mismo efecto que produce el webhook (upsert de `Payment` como aprobado + confirmar `purchase`/`order` + marcar el carrito abierto del usuario como `completed`). Es la misma lógica que usa el polling de `GET /marketplace/checkout/status`, disponible aquí para reconciliación manual desde admin.

### Response 200 OK

Devuelve el mismo shape que `GET /api/v1/admin/orders/:id` (detalle recargado, ya con `purchase.status = "confirmed"` y el pago en `approved`).

### Response 422 Unprocessable Entity

```json
{ "error": "No approved transaction found in Wompi for this reference" }
```

---

## Implementación (backend)

| Ruta | Controller | Interactor |
|------|------------|------------|
| `GET /api/v1/admin/orders` | `Api::V1::Admin::OrdersController#index` | `Admin::Orders::List` |
| `GET /api/v1/admin/orders/:id` | `Api::V1::Admin::OrdersController#show` | `Admin::Orders::Show` |
| `PATCH/PUT …/:id` | `Api::V1::Admin::OrdersController#update` | `Admin::Orders::Update` |
| `POST …/:id/check_wompi_status` | `Api::V1::Admin::OrdersController#check_wompi_status` | `Admin::Orders::CheckWompiStatus` |
| `POST …/:id/reconcile_wompi_payment` | `Api::V1::Admin::OrdersController#reconcile_wompi_payment` | `Admin::Orders::ReconcileWompiPayment` |

- Listado: precarga `order_items` → `product` → `category`, y `purchase` con `user`, `purchase_intent` y `payments` para evitar N+1.
- Búsqueda `search`: unión de IDs por tres consultas (email, número de compra, referencia externa).
- Actualización: no modifica montos ni ítems; solo campos operativos de `orders`.
- `check_wompi_status` / `reconcile_wompi_payment`: la reconciliación real (upsert de `Payment` + completar orden/carrito) vive en `Marketplace::Checkout::ReconcileTransaction`, compartida con el webhook (`Marketplace::Checkout::Webhook`) y con el polling de status (`Marketplace::Checkout::Status`) para no depender solo de que el webhook de Wompi llegue.
