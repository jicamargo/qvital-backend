# GET /api/v1/health_goals

## Descripción

Endpoint para obtener la lista de **objetivos de salud** activos (Fase 3 — ver `docs/requirements/fase3-personalizacion-objetivos-salud.md`), usados para:

- El selector rápido "¿Qué buscas?" en `/marketplace` (CTA de objetivos).
- Etiquetar productos por objetivo (`product.health_goals`, ver `GET /api/v1/products`).
- Poblar el selector de objetivos en el formulario admin de productos.

---

## Autenticación

- Requiere JWT válido en el header `Authorization`.

```http
Authorization: Bearer <access_token>
```

---

## Request

### Método y URL

```http
GET /api/v1/health_goals
```

### Query params

Ninguno por ahora. La lista siempre devuelve solo objetivos `active: true`, ordenados por `position`.

---

## Response

### 200 OK

```json
{
  "health_goals": [
    {
      "id": 1,
      "key": "bajar_peso",
      "name": "Bajar de peso",
      "description": "Productos y recetas pensados para perder peso de forma saludable.",
      "icon": "TrendingDown",
      "color": "#3d7ea3",
      "position": 1
    },
    {
      "id": 8,
      "key": "comprar_por_mi_cuenta",
      "name": "Comprar por mi cuenta",
      "description": "Omite el filtro por objetivo y muestra todo el catálogo.",
      "icon": "ShoppingBag",
      "color": "#475569",
      "position": 8
    }
  ]
}
```

`icon` es un nombre de icono de `lucide-react` (el frontend ya usa esa librería exclusivamente). `color` es un hex, pensado para usarse en el fondo/acento de la tarjeta del selector rápido.

### 401 Unauthorized

```json
{ "error": "Unauthorized" }
```

### 500 Internal Server Error

```json
{ "error": "Internal server error" }
```

---

## Notas de implementación (Backend)

- Controller: `Api::V1::HealthGoalsController#index`
- Interactor: `HealthGoals::List` → `HealthGoal.active.ordered`
- Blueprint: `HealthGoalBlueprint`
- Gestión (crear/editar/desactivar objetivos con icono y color) llega en la sub-fase 3.2 (`Api::V1::Admin::HealthGoalsController`, aún no implementado).

---

## Notas de uso (Frontend)

```ts
const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/v1/health_goals`, {
  method: "GET",
  headers: {
    "Content-Type": "application/json",
    Authorization: `Bearer ${token}`,
  },
});

const { health_goals } = await response.json();
```

Para filtrar el catálogo por objetivo, pasar `health_goal_key` a `GET /api/v1/products` (ver `docs/endpoints/api-v1-products.md`). El objetivo `comprar_por_mi_cuenta` es un comodín: seleccionarlo equivale a **no** enviar `health_goal_key` (muestra todo el catálogo).
