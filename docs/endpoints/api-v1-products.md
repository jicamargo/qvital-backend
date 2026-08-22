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

Todos opcionales:

- `health_goal_key` (opcional) — filtra el catálogo por objetivo de salud (ver `GET /api/v1/health_goals`), ej. `bajar_peso`. Si se omite, devuelve todo el catálogo (equivalente a seleccionar "Comprar por mi cuenta" en el CTA rápido del marketplace).
- `category_id` (pendiente, no implementado aún)
- `search` (pendiente — ver `docs/requirements/busqueda-full-text.md`, sub-fase 3.8)

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
      "flavor": "Vainilla",
      "disclaimer": null,
      "category": {
        "id": 2,
        "name": "Proteínas"
      },
      "health_goals": [
        { "id": 1, "key": "bajar_peso", "name": "Bajar de peso", "description": "...", "icon": "TrendingDown", "color": "#3d7ea3", "position": 1 }
      ],
      "price": 850.0,
      "currency": "COP",
      "level_id": 3
    }
  ]
}
```

`flavor` puede ser `null` (no todos los productos tienen sabor). `disclaimer` puede ser `null` (si es así, el frontend debe mostrar el texto genérico de `MedicalDisclaimer`, no ocultar el aviso). `health_goals` puede ser un array vacío si el producto no ha sido taggeado todavía (la asignación desde el panel admin llega en la sub-fase 3.2).

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
  - Recibe `user:` y `health_goal_key:` (opcional)
  - Valida que el usuario tenga `level_id`
  - Carga productos activos con precio para ese nivel, filtrando por objetivo si se pasa `health_goal_key` (`Product.by_health_goal_key`)

- Blueprints:
  - `ProductBlueprint` (incluye `flavor` y `health_goals`)
  - `CategoryBlueprint`
  - `HealthGoalBlueprint`

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

