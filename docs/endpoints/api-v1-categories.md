# GET /api/v1/categories

## Descripción

Endpoint para obtener la lista de **categorías de productos** disponibles en QVITAL.

Este endpoint está pensado para:

- Poblar filtros de categorías en el marketplace.
- Usarse en formularios del panel admin (selector de categoría para productos).

---

## Autenticación

- Requiere JWT válido en el header `Authorization`.
- El usuario debe estar sincronizado vía `/api/v1/auth/sync`.

```http
Authorization: Bearer <access_token>
```

Usa el mismo concern `Authenticatable` que el resto de la API v1.

---

## Request

### Método y URL

```http
GET /api/v1/categories
```

### Headers

- `Authorization: Bearer <access_token>`
- `Content-Type: application/json`

### Query params

Por ahora **no** hay filtros para categorías.  
Si en el futuro se requieren (por ejemplo, filtrar solo categorías con productos activos), se puede extender el interactor `Categories::List`.

---

## Response

### 200 OK

```json
{
  "categories": [
    {
      "id": 1,
      "name": "Fórmula 1 - Batido Nutricional"
    },
    {
      "id": 2,
      "name": "Proteína"
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
  "error": "Unable to load categories"
}
```

### 500 Internal Server Error

```json
{
  "error": "Internal server error"
}
```

---

## Notas de implementación (Backend)

- Controller: `Api::V1::CategoriesController#index`
  - Hereda de `Api::V1::BaseController`
  - Usa `authenticate_user!` y `current_user` del concern `Authenticatable`
  - Orquesta:
    - `result = ::Categories::List.call`
    - `CategoryBlueprint.render(result.categories)`

- Interactor: `Categories::List`
  - Carga todas las categorías ordenadas por `name`:
    - `Category.order(:name)`

- Blueprints:
  - `CategoryBlueprint`
    - Campos: `id`, `name`

---

## Notas de uso (Frontend)

Ejemplo de uso en Next.js:

```ts
const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/v1/categories`, {
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
const categories = data.categories;
```

