# GET /api/v1/products

## Descripción

Endpoint para obtener la lista de productos activos visibles para el **usuario autenticado**, mostrando **solo el precio correspondiente a su nivel**.

Esto implementa la regla de negocio:

```text
user.level → determina precio → mostrar precio correcto
```

---

## Autenticación

- Requiere JWT válido en el header `Authorization`.
- El usuario debe estar sincronizado vía `/api/v1/auth/sync`.

```http
Authorization: Bearer <access_token>
```

---

## Request

### Método y URL

```http
GET /api/v1/products
```

### Headers

- `Authorization: Bearer <access_token>`
- `Content-Type: application/json`

### Query params

Por ahora **no** hay filtros obligatorios. Más adelante se pueden agregar:

- `category_id` (opcional)
- `search` (opcional)

---

## Response

### 200 OK

```json
{
  "products": [
    {
      "id": 1,
      "name": "Proteína Herbal",
      "description": "Descripción corta opcional",
      "image_url": "https://...",
      "pv": 230.85,
      "sku": "HBL-123",
      "category": {
        "id": 2,
        "name": "Proteínas"
      },
      "price": 850.0,
      "currency": "COP",
      "level_id": 3
    }
  ]
}
```

### 401 Unauthorized

```json
{
  "error": "No token"
}
```

o

```json
{
  "error": "Unauthorized"
}
```

### 422 Unprocessable Entity

```json
{
  "error": "User level is required to calculate prices"
}
```

---

## Notas de implementación (Backend)

- Controller: `Api::V1::ProductsController#index`
  - Hereda de `Api::V1::BaseController`
  - Usa `authenticate_user!` y `current_user` del concern `Authenticatable`
  - Orquesta:
    - `result = Products::ListForUser.call(user: current_user)`
    - `ProductBlueprint.render(result.products, level_id: current_user.level_id)`

- Interactor: `Products::ListForUser`
  - Recibe `user`
  - Valida que el usuario tenga `level_id`
  - Carga productos activos con precio para ese nivel

- Blueprints:
  - `ProductBlueprint`
  - `CategoryBlueprint`

---

## Notas de uso (Frontend)

Ejemplo de uso en Next.js:

```ts
const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/v1/products`, {
  method: "GET",
  headers: {
    "Content-Type": "application/json",
    Authorization: `Bearer ${token}`,
  },
});

if (!response.ok) {
  // manejar error
}

const data = await response.json();
const products = data.products;
```

