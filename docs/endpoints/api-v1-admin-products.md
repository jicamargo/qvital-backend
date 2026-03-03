# Admin – Productos (`/api/v1/admin/products`)

## 📋 Descripción general

Endpoints para la **gestión interna (admin)** de productos en QVITAL:

- CRUD completo de productos
- Gestión de precios por nivel
- Solo accesible para usuarios con rol `admin`

Autenticación y autorización:

- JWT Supabase (mismo flujo que el resto de la API)
- `current_user.role == "admin"`

---

## 🔐 Autenticación y autorización

- Header obligatorio:

```http
Authorization: Bearer <access_token>
Content-Type: application/json
```

- Requisitos:
  - El token debe ser válido (validado vía `Auth::SyncUser`)
  - El usuario debe tener `role = "admin"`

Respuestas de error comunes:

- `401 Unauthorized` → token ausente o inválido
- `403 Forbidden` → usuario autenticado pero no admin

---

## 1️⃣ GET /api/v1/admin/products

Lista de productos para el panel admin.

### Request

```http
GET /api/v1/admin/products
Authorization: Bearer <token_admin>
Content-Type: application/json
```

### Query params (opcionales)

- `category_id` (integer) → filtra por categoría
- `search` (string) → busca por `name` o `sku` (ILIKE)
- `active` (boolean: `true`/`false`) → filtra por estado

### Response 200 OK

```json
[
  {
    "id": 1,
    "name": "Fórmula 1 - Banana Caramelo",
    "description": "Fórmula 1 - Banana Caramelo",
    "image_url": "https://<project>.supabase.co/storage/v1/object/public/products/abc123.webp",
    "pv": 25.75,
    "sku": "1522",
    "category": {
      "id": 1,
      "name": "Fórmula 1 - Batido Nutricional"
    },
    "price": null,
    "level_id": null,
    "currency": "MXN",
    "active": true,
    "created_at": "2026-02-13T15:00:00Z",
    "updated_at": "2026-02-13T15:05:00Z"
  }
]
```

> Nota: en admin **no se calcula precio por nivel**, pero el blueprint mantiene los campos (`price`, `level_id`) para consistencia. En el panel admin normalmente no se pasa `level_id` en las opciones del blueprint.

### Notas de implementación (Backend)

- Controller: `Api::V1::Admin::ProductsController#index`
  - Hereda de `Api::V1::BaseController`
  - `before_action :authenticate_user!`
  - `before_action :authorize_admin!`
  - Orquesta:
    - `result = ::Admin::Products::List.call(params: index_params)`
    - `ProductBlueprint.render(result.products, view: :admin)`

- Interactor: `Admin::Products::List`
  - Filtros:
    - `active`
    - `category_id`
    - `search` (ILIKE name/sku)

---

## 2️⃣ GET /api/v1/admin/products/:id

Detalle de un producto para el panel admin.

### Request

```http
GET /api/v1/admin/products/:id
Authorization: Bearer <token_admin>
Content-Type: application/json
```

### Response 200 OK

```json
{
  "id": 1,
  "name": "Fórmula 1 - Banana Caramelo",
  "description": "Fórmula 1 - Banana Caramelo",
  "image_url": "https://<project>.supabase.co/storage/v1/object/public/products/abc123.webp",
  "pv": 25.75,
  "sku": "1522",
  "category": {
    "id": 1,
    "name": "Fórmula 1 - Batido Nutricional"
  },
  "price": null,
  "level_id": null,
  "currency": "MXN",
  "active": true,
  "created_at": "2026-02-13T15:00:00Z",
  "updated_at": "2026-02-13T15:05:00Z"
}
```

### Response 404 Not Found

```json
{
  "error": "Product not found"
}
```

### Notas de implementación (Backend)

- Controller: `Api::V1::Admin::ProductsController#show`
- Interactor: `Admin::Products::Show`
  - `Product.includes(:category, :product_prices).find_by(id: params[:id])`

---

## 3️⃣ POST /api/v1/admin/products

Crear un nuevo producto con sus precios por nivel.

### Request

```http
POST /api/v1/admin/products
Authorization: Bearer <token_admin>
Content-Type: application/json

{
  "product": {
    "name": "Fórmula 1 - Banana Caramelo",
    "description": "Fórmula 1 - Banana Caramelo",
    "sku": "1522",
    "pv": 25.75,
    "category_id": 1,
    "active": true,
    "image_url": "https://<project>.supabase.co/storage/v1/object/public/products/abc123.webp",
    "image_path": "products/abc123.webp",
    "prices": {
      "Cliente": 137468,
      "Cliente VIP": 132939,
      "Distribuidor": 128410,
      "Distrib VIP": 114340,
      "Constructor del Éxito": 104490,
      "Mayorista": 93230
    }
  }
}
```

> `prices` puede usar **nombre de nivel** (`"Cliente"`) o **id de nivel** (`"1"`).

### Response 201 Created

```json
{
  "id": 1,
  "name": "Fórmula 1 - Banana Caramelo",
  "description": "Fórmula 1 - Banana Caramelo",
  "image_url": null,
  "pv": 25.75,
  "sku": "1522",
  "category": {
    "id": 1,
    "name": "Fórmula 1 - Batido Nutricional"
  },
  "price": null,
  "level_id": null,
  "currency": "MXN",
  "active": true,
  "created_at": "2026-02-13T15:00:00Z",
  "updated_at": "2026-02-13T15:00:00Z"
}
```

### Response 422 Unprocessable Entity

```json
{
  "error": "Error creating product: Validation failed",
  "details": {
    "name": ["can't be blank"],
    "sku": ["has already been taken"],
    "product_prices": [
      {
        "price": ["must be greater than 0"]
      }
    ]
  }
}
```

### Notas de implementación (Backend)

- Controller: `Api::V1::Admin::ProductsController#create`
- Interactor: `Admin::Products::Create`
  - Transacción:
    - Crea `Product`
    - Crea `ProductPrice` por cada entrada en `prices`

---

## 4️⃣ PUT/PATCH /api/v1/admin/products/:id

Actualizar un producto y sus precios por nivel.

### Request

```http
PUT /api/v1/admin/products/:id
Authorization: Bearer <token_admin>
Content-Type: application/json

{
  "product": {
    "name": "Fórmula 1 - Banana Caramelo (Nuevo nombre)",
    "description": "Otro texto",
    "pv": 26.00,
    "category_id": 2,
    "active": true,
    "prices": {
      "Cliente": 140000,
      "Distribuidor": 130000,
      "Mayorista": 95000
    }
  }
}
```

- Si `prices` incluye un nivel con `null` o `""`, se puede interpretar como eliminación del precio para ese nivel (según la lógica de `Update`).

### Response 200 OK

```json
{
  "id": 1,
  "name": "Fórmula 1 - Banana Caramelo (Nuevo nombre)",
  "description": "Otro texto",
  "image_url": "https://<project>.supabase.co/storage/v1/object/public/products/abc123-new.webp",
  "pv": 26.0,
  "sku": "1522",
  "category": {
    "id": 2,
    "name": "Otra categoría"
  },
  "price": null,
  "level_id": null,
  "currency": "MXN",
  "active": true,
  "created_at": "2026-02-13T15:00:00Z",
  "updated_at": "2026-02-13T16:00:00Z"
}
```

### Response 422 Unprocessable Entity

Mismo formato que en `create`.

### Notas de implementación (Backend)

- Controller: `Api::V1::Admin::ProductsController#update`
- Interactor: `Admin::Products::Update`
  - Actualiza `Product`
  - Crea/actualiza/elimina `ProductPrice` según `prices`

---

## 5️⃣ DELETE /api/v1/admin/products/:id

Soft-delete de un producto (marca `active = false`).

### Request

```http
DELETE /api/v1/admin/products/:id
Authorization: Bearer <token_admin>
Content-Type: application/json
```

### Response 204 No Content

Sin cuerpo.

### Response 404 Not Found

```json
{
  "error": "Product not found"
}
```

### Notas de implementación (Backend)

- Controller: `Api::V1::Admin::ProductsController#destroy`
- Interactor: `Admin::Products::Destroy`
  - `product.update(active: false)`

---

## 🔎 Resumen técnico (Backend)

- **Namespace**: `Api::V1::Admin`
- **Controller**: `Api::V1::Admin::ProductsController`
  - Autenticación: `authenticate_user!`
  - Autorización: `authorize_admin!` (solo `user.role == "admin"`)
  - Lógica en interactors:
    - `Admin::Products::List`
    - `Admin::Products::Show`
    - `Admin::Products::Create`
    - `Admin::Products::Update`
    - `Admin::Products::Destroy`
- **Serialización**:
  - `ProductBlueprint` con `view: :admin`

