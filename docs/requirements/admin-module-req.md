## 🛠 Módulo Admin QVITAL – Gestión de Productos (Backend + Frontend)

### 🎯 Objetivo

Definir el módulo de administración de productos para QVITAL, siguiendo las **reglas generales del proyecto**:

- Controllers minimalistas  
- Lógica en interactors  
- Uso de Blueprinter para serializar las respuestas  
- DRY, SOLID, desacoplado  
- Documentar cada endpoint en `docs/endpoints`  
- MVP listo para escalar a SaaS multi-tenant

---

## 🔧 BACKEND (Rails API) — Fase Admin Productos

### 1️⃣ Rutas y estructura de namespaces

- [ ] Definir namespace admin para API:

```ruby
# config/routes.rb
namespace :api do
  namespace :v1 do
    namespace :admin do
      resources :products
    end
  end
end
```

**Rutas resultantes:**

- `GET    /api/v1/admin/products`       → index
- `GET    /api/v1/admin/products/:id`   → show
- `POST   /api/v1/admin/products`       → create
- `PUT    /api/v1/admin/products/:id`   → update
- `PATCH  /api/v1/admin/products/:id`   → update
- `DELETE /api/v1/admin/products/:id`   → destroy

> Regla: estos endpoints son para **gestión interna (admin)**, no para el marketplace público.

---

### 2️⃣ Autenticación y autorización (admin)

- [ ] Reutilizar `Authenticatable` para validar JWT y popular `current_user`
- [ ] Crear helper/concern de autorización:

```ruby
def authorize_admin!
  unless current_user&.admin?
    render json: { error: "Forbidden" }, status: :forbidden and return
  end
end
```

- [ ] Aplicar en el controller admin:
  - [ ] `before_action :authenticate_user!`
  - [ ] `before_action :authorize_admin!`

---

### 3️⃣ Controllers minimalistas (Admin::ProductsController)

- [ ] Crear `Api::V1::Admin::ProductsController` heredando de `Api::V1::BaseController`
- [ ] Acciones:
  - [ ] `index` → lista paginada de productos
  - [ ] `show` → detalle de un producto
  - [ ] `create` → crear producto + precios por nivel
  - [ ] `update` → actualizar producto + precios por nivel
  - [ ] `destroy` → desactivar / borrar producto (soft-delete recomendado con `active = false`)

**Regla:**  
Cada acción del controller debe:

- Recibir params
- Llamar a un **interactor**
- Renderizar respuesta con **Blueprinter**

Ejemplo (esquema):

```ruby
def create
  result = Admin::Products::Create.call(params: product_params, current_user: current_user)

  if result.success?
    render json: ProductBlueprint.render_as_hash(result.product, view: :admin), status: :created
  else
    render json: { error: result.error, details: result.errors }, status: :unprocessable_entity
  end
end
```

---

### 4️⃣ Interactors (casos de uso admin)

- [ ] Crear namespace `app/interactors/admin/products/`

Interactores sugeridos:

- [ ] `Admin::Products::List`
  - Filtros: categoría, texto (nombre/sku), estado (activo/inactivo)
- [ ] `Admin::Products::Show`
- [ ] `Admin::Products::Create`
  - Crea:
    - `Product`
    - `ProductPrice` para cada nivel configurado
- [ ] `Admin::Products::Update`
  - Actualiza producto y precios
- [ ] `Admin::Products::Destroy` (o `Archive`)
  - Marca `active = false` (en lugar de borrar)

**Contrato de entrada/salida (ejemplo Create):**

- Input:
  - `params` con:
    - `name`, `description`, `sku`, `pv`, `category_id`, `active`
    - `prices` (hash `{ level_id => price }` o `{ level_name => price }`)
  - `current_user` (para auditoría futura, opcional)
- Output:
  - `product`
  - `error` / `errors`
  - `success?`

---

### 5️⃣ Serialización (Blueprinter) para admin

- [ ] Reutilizar `ProductBlueprint` y `CategoryBlueprint`
- [ ] Crear vista admin en `ProductBlueprint` si se requieren campos extra:

```ruby
class ProductBlueprint < Blueprinter::Base
  # view :default ya usada en frontend

  view :admin do
    include_view :default
    fields :active, :created_at, :updated_at
  end
end
```

- [ ] Endpoints admin usan `ProductBlueprint.render(products, view: :admin)`

---

### 6️⃣ Documentación de endpoints (regla general)

Por cada endpoint admin, crear archivo en `docs/endpoints`:

- [ ] `docs/endpoints/api-v1-admin-products-index.md`
- [ ] `docs/endpoints/api-v1-admin-products-show.md`
- [ ] `docs/endpoints/api-v1-admin-products-create.md`
- [ ] `docs/endpoints/api-v1-admin-products-update.md`
- [ ] `docs/endpoints/api-v1-admin-products-destroy.md`

Cada archivo debe incluir:

- Método + URL  
- Auth requerida (JWT + rol admin)  
- Request body (para create/update)  
- Response (200/201/4xx)  

---

## 🎨 FRONTEND (Next.js / React) — Panel Admin

### 1️⃣ Rutas admin

- [ ] Definir sección `/admin` en el frontend:
  - [ ] `/admin/products` → listado
  - [ ] `/admin/products/new` → creación
  - [ ] `/admin/products/[id]/edit` → edición

> Regla: layout propio para admin (sidebar + topbar distinta).

---

### 2️⃣ Layout Admin

- [ ] Crear `admin/layout.tsx`:
  - [ ] Sidebar con navegación:
    - Productos
    - Usuarios (futuro)
    - Settings (futuro)
  - [ ] Topbar con info de usuario admin + logout

---

### 3️⃣ Protección de rutas (Frontend)

- [ ] Crear `ProtectedRoute` / hook de auth admin:
  - [ ] Verificar sesión Supabase
  - [ ] Llamar a `/api/v1/auth/sync` si es necesario
  - [ ] Verificar `user.role` en la respuesta:
    - Solo permitir acceso si `role` ∈ `{ 'admin' }` (luego se puede extender a `staff`)

- [ ] Middleware de Next (opcional pero recomendado):
  - [ ] En `middleware.ts`, redirigir `/admin/*` a `/login` si:
    - No hay sesión
    - O el usuario no es admin

---

### 4️⃣ UI de gestión de productos

- [ ] Página `/admin/products`:
  - [ ] Tabla con:
    - SKU
    - Nombre
    - Categoría
    - Activo (sí/no)
    - Acciones: Editar, Desactivar
  - [ ] Filtros:
    - Categoría
    - Texto (sku/nombre)
    - Estado (activo/inactivo)

- [ ] Formularios:
  - [ ] Crear producto:
    - Nombre, descripción, sku, pv, categoría, activo
    - Precios por nivel (inputs por cada nivel)
  - [ ] Editar producto:
    - Mismos campos, precargados desde API admin

---

## 📌 Notas de diseño y escalabilidad

- El panel admin es **solo para el owner actual del MVP** (tú), pero la arquitectura:
  - Está lista para:
    - Añadir roles extra (`staff`, `owner`, etc.)
    - Añadir `store_id` en productos y precios para multi-tenant en Fase SaaS
- Los endpoints admin deben ser:
  - Claros, bien documentados
  - No usados por el frontend público

---

## ✅ Checklist de implementación (Backend Admin Productos)

- [ ] Namespace `api/v1/admin` en rutas  
- [ ] Controller `Api::V1::Admin::ProductsController`  
- [ ] Helper/concern `authorize_admin!`  
- [ ] Interactors:
  - [ ] `Admin::Products::List`
  - [ ] `Admin::Products::Show`
  - [ ] `Admin::Products::Create`
  - [ ] `Admin::Products::Update`
  - [ ] `Admin::Products::Destroy` (o `Archive`)
- [ ] Vista `:admin` en `ProductBlueprint`  
- [ ] Endpoints documentados en `docs/endpoints`

---

## ✅ Checklist de implementación (Frontend Admin Productos)

- [ ] Layout admin (`admin/layout.tsx`)  
- [ ] Rutas:
  - [ ] `/admin/products`
  - [ ] `/admin/products/new`
  - [ ] `/admin/products/[id]/edit`
- [ ] Protección:
  - [ ] Hook / HOC de `ProtectedRoute` para admin
  - [ ] Middleware (opcional) para `/admin/*`
- [ ] UI:
  - [ ] Tabla de productos
  - [ ] Formularios de creación/edición conectados a `/api/v1/admin/products`

