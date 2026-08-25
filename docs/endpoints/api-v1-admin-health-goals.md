# Admin – Objetivos de Salud (`/api/v1/admin/health_goals`)

## 📋 Descripción general

CRUD interno (admin) para los **objetivos de salud** (Fase 3 — `docs/requirements/fase3-personalizacion-objetivos-salud.md`, sub-fase 3.2), usados por:

- El selector rápido "¿Qué buscas?" del marketplace (`GET /api/v1/health_goals`, público).
- El selector múltiple de objetivos en el formulario admin de productos (`health_goal_ids` en `POST/PATCH /api/v1/admin/products`).

Solo accesible para `role = "admin"` (mismo flujo que `docs/endpoints/api-v1-admin-products.md`).

---

## 🔐 Autenticación y autorización

```http
Authorization: Bearer <token_admin>
Content-Type: application/json
```

- `401 Unauthorized` → token ausente o inválido
- `403 Forbidden` → usuario autenticado pero no admin

---

## 1️⃣ GET /api/v1/admin/health_goals

Lista **todos** los objetivos (activos e inactivos — a diferencia del endpoint público, que solo devuelve activos), ordenados por `position`.

### Response 200 OK

```json
[
  {
    "id": 1,
    "key": "bajar_peso",
    "name": "Bajar de peso",
    "description": "Productos y recetas pensados para perder peso de forma saludable.",
    "icon": "TrendingDown",
    "color": "#3d7ea3",
    "position": 1,
    "active": true,
    "created_at": "2026-08-22T12:00:00Z",
    "updated_at": "2026-08-22T12:00:00Z"
  }
]
```

---

## 2️⃣ GET /api/v1/admin/health_goals/:id

### Response 404 Not Found

```json
{ "error": "Health goal not found" }
```

---

## 3️⃣ POST /api/v1/admin/health_goals

### Request

```json
{
  "health_goal": {
    "key": "salud_ósea",
    "name": "Cuidar mis huesos",
    "description": "Productos orientados a la salud ósea.",
    "icon": "Bone",
    "color": "#8b5cf6",
    "position": 9,
    "active": true
  }
}
```

`icon`: nombre de icono de `lucide-react` (la app solo usa esa librería). `color`: hex.

### Response 201 Created

Mismo formato que el `GET` de arriba.

### Response 422 Unprocessable Entity

```json
{
  "error": "No se pudo crear el objetivo de salud",
  "details": {
    "key": ["has already been taken"],
    "icon": ["can't be blank"]
  }
}
```

---

## 4️⃣ PATCH /api/v1/admin/health_goals/:id

Mismo body que `create` (campos parciales permitidos).

---

## 5️⃣ DELETE /api/v1/admin/health_goals/:id

**Soft delete**: marca `active = false`, no borra el registro (para no romper productos ya taggeados con ese objetivo — sus filas en `product_health_goals` se conservan). El endpoint público (`GET /api/v1/health_goals`) deja de devolverlo inmediatamente.

Para reactivar, usar `PATCH` con `{ "health_goal": { "active": true } }`.

### Response

- `204 No Content` en éxito.
- `422 Unprocessable Entity` si el id no existe.

---

## Notas de implementación (Backend)

- Controller: `Api::V1::Admin::HealthGoalsController` (CRUD completo)
- Interactors: `Admin::HealthGoals::{List,Show,Create,Update,Destroy}`
  - `List` usa `HealthGoal.ordered` (sin `.active`, a diferencia del interactor público `HealthGoals::List`)
  - `Destroy` hace `update(active: false)`, nunca `destroy` real
- Blueprint: `HealthGoalBlueprint`, vista `:admin` (agrega `active`, `created_at`, `updated_at`)
- Params permitidos: `key, name, description, icon, color, position, active`
