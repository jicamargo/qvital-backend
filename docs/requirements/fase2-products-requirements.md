
QVITAL ya tiene:

- Auth moderna (ES256 + JWKS)
- Sync desacoplado con interactor
- Roles + niveles (`User`, `Level`)
- Sistema de productos base (`Product`, `ProductPrice`, `Category`)
- Frontend integrado (Next.js + Supabase)
- Uso de **Blueprinter** para serializar respuestas

Con esto, la fase técnica mínima está lista.
Ahora entramos en **Fase 2: Producto / Marketplace básico (MVP real)**.

El foco ya no es seguir mejorando auth, sino **construir el primer flujo de valor completo**:

> Usuario entra → ve productos con su precio personalizado → compra → tú recibes el pedido.

---

## 📋 Visión de la Fase 2

### Objetivo

Conectar:

- `products`
- `product_prices`
- `level` del usuario autenticado

Para mostrar un **Marketplace** donde **cada usuario ve el precio que corresponde a su nivel**, siguiendo las reglas:

- **Controllers minimalistas**
- **Lógica en interactors**
- **Blueprinter** como única capa de serialización
- Código **DRY, SOLID y desacoplado**
- Diseño listo para escalar a SaaS multi-tenant más adelante (añadiendo `store_id`, etc.)

---

## 🧠 Concepto clave de negocio

Tu marketplace **NO** debe mostrar el mismo precio a todos.

Regla central:

```text
user.level → determina precio → mostrar precio correcto
```

Eso es el corazón del modelo de negocio y debe estar explícito en la arquitectura.

---

## 🔧 BACKEND (Rails API)

### 1️⃣ Middleware / Concern de Autenticación Global

Reutilizar la validación JWT ya implementada en `/auth/sync` para proteger otros endpoints.

- [X] **Crear concern** `Authenticatable` (en `app/controllers/concerns/authenticatable.rb`)
  - [X] Extraer lógica de:
    - [X] Extracción de token (`Authorization: Bearer <jwt>`)
    - [X] Llamada a `Auth::SyncUser` para validar y sincronizar usuario
  - [X] Definir método `current_user`
  - [X] Definir `before_action :authenticate_user!`

- [X] **Aplicar concern** a los controllers API v1
  - [X] `Api::V1::BaseController` creado e incluye `Authenticatable`
  - [X] `AuthController#sync` se mantiene accesible (hereda directamente de `ApplicationController`, no de `BaseController`)

> Regla: **los controllers solo orquestan**, nunca contienen lógica de negocio o de dominio.

---

### 2️⃣ Endpoint: `GET /api/v1/products`

Este endpoint devuelve **solo los productos visibles para el usuario actual**, con **el precio correspondiente a su nivel**.

#### 2.1 Requisitos funcionales

- [X] Solo accesible para usuario autenticado (JWT válido)
- [X] Usa `current_user` para:
  - [X] Determinar `current_user.level`
  - [X] Calcular el precio según `product_prices`
- [X] Devuelve:
  - [X] Lista de productos **activos**
  - [X] Un solo precio por producto (el del nivel del usuario)
  - [X] Información básica necesaria para el marketplace

**Ejemplo de respuesta esperada:**

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
      "currency": "MXN",
      "level_id": 3
    }
  ]
}
```

> Nota: **no** devolver todos los precios de todos los niveles, solo el que aplica al usuario actual.

#### 2.2 Diseño de Arquitectura (siguiendo reglas generales)

- [X] **Controller** minimalista: `Api::V1::ProductsController`
  - [X] Acción `index` solo orquesta:
    - [X] Llama a `Products::ListForUser.call(user: current_user)`
    - [X] Usa `ProductBlueprint` para serializar

- [X] **Interactor**: `app/interactors/products/list_for_user.rb`
  - [X] Entradas:
    - [X] `user:` (instancia de `User`)
  - [X] Responsabilidades:
    - [X] Validar que el usuario tenga `level`
    - [X] Buscar productos activos
    - [X] Hacer join con `product_prices` filtrando por `level_id`
    - [X] Preparar una colección de `Product` con el precio correcto cargado

- [X] **Modelo / Scope** en `Product`
  - [X] Scope `active`
  - [X] Helper `price_for_level` para cargar precio por nivel

- [X] **Blueprinter**: `ProductBlueprint` + `CategoryBlueprint`
  - [X] Estructura JSON consistente en toda la API

---

### 3️⃣ Serialización (Blueprinter)

Respetando la regla de **“uso de blueprinter para serializar las respuestas”**:

- [X] Crear `ProductBlueprint`
  - [X] Campos:
    - [X] `id`, `name`, `description`, `image_url`, `pv`, `sku`
  - [X] Campo calculado `price`
    - [X] Tomado del `ProductPrice` correspondiente al nivel del usuario (`price_for_level`)
  - [X] Campo `level_id` (nivel usado para calcular el precio)
  - [X] Asociación `category` usando `CategoryBlueprint`

- [X] Crear `CategoryBlueprint`
  - [X] Campos: `id`, `name`

- [ ] (Opcional interno) `ProductPriceBlueprint` si en algún momento se expone en endpoints administrativos.

> Regla: **ningún controller devuelve ActiveRecord directo**, siempre Blueprinter.

---

### 4️⃣ Estructura de Código Sugerida (Backend)

- [X] `app/controllers/api/v1/base_controller.rb`
  - [X] Incluye concern de autenticación
  - [X] Base para otros controllers API v1

- [X] `app/controllers/concerns/authenticatable.rb`
  - [X] Concern reutilizable para autenticación JWT
  - [X] Métodos `authenticate_user!` y `current_user`

- [ ] `app/controllers/api/v1/products_controller.rb`
  - [ ] Hereda de `Api::V1::BaseController`
  - [ ] Acción `index`

- [ ] `app/interactors/products/list_for_user.rb`
  - [ ] Contiene la lógica de negocio

- [ ] `app/blueprints/product_blueprint.rb`
- [ ] `app/blueprints/category_blueprint.rb`

---

## 🎨 FRONTEND (Next.js / React)

### 1️⃣ Página de Marketplace

Ruta sugerida:

```text
/app/marketplace
```

- [ ] Crear página `Marketplace`
  - [ ] Protegida (requiere usuario autenticado)
  - [ ] Usa el contexto de auth existente (usuario ya sincronizado con backend)

- [ ] Data fetching:
  - [ ] Usar `fetch` o `react-query`/`SWR` para llamar a:
    - [ ] `GET ${NEXT_PUBLIC_API_URL}/api/v1/products`
  - [ ] Enviar `Authorization: Bearer <access_token>` igual que en `/auth/sync`

- [ ] Render:
  - [ ] Mapear `products` a componentes `ProductCard`
  - [ ] Mostrar:
    - [ ] Nombre
    - [ ] Imagen
    - [ ] Precio calculado
    - [ ] PV (puntos de volumen)
    - [ ] Categoría

---

### 2️⃣ Componente `ProductCard`

- [ ] Props mínimas:
  - [ ] `name`
  - [ ] `image_url`
  - [ ] `price`
  - [ ] `currency`
  - [ ] `pv`
  - [ ] `categoryName`

- [ ] Diseño:
  - [ ] Consistente con el design system actual
  - [ ] Listo para evolucionar a:
    - [ ] Botón “Agregar al carrito” (Fase futura)
    - [ ] Badges según nivel/descuento

---

### 3️⃣ Flujo de Usuario (End-to-End)

1. Usuario hace login/signup con Supabase
2. Frontend obtiene `access_token`
3. Frontend llama a `/api/v1/auth/sync`
4. Backend sincroniza usuario y nivel
5. Usuario navega a `/marketplace`
6. Frontend llama a `GET /api/v1/products` con el mismo JWT
7. Backend:
   - Identifica `current_user`
   - Determina `user.level`
   - Calcula el precio correcto por producto
   - Devuelve lista de productos serializada con Blueprinter
8. Frontend renderiza productos con precios personalizados

---

## 🔥 Momento clave de QVITAL

Cuando el usuario logueado vea:

- Su **precio personalizado**
- Productos reales
- Un layout profesional

QVITAL deja de ser solo infraestructura y empieza a ser **producto real**.

---

## 🧠 Arquitectura mental correcta ahora

Cadena conceptual que debemos construir:

```text
Auth → Usuario → Nivel → Precio → Compra → Pedido
```

En esta fase, nos enfocamos en cerrar la parte:

```text
Auth → Usuario → Nivel → Precio → (vista de productos)
```

La parte de **Compra → Pedido** vendrá en la siguiente fase (carrito + Mercado Pago).

---

## 🎯 Recomendación de Sprint (en orden)

1. [ ] Middleware / concern global JWT (`authenticate_user!`, `current_user`)
2. [ ] Endpoint `GET /api/v1/products` con:
   - [ ] Interactor `Products::ListForUser`
   - [ ] Serialización con `ProductBlueprint`
3. [ ] Página `/marketplace` mostrando productos con precio por nivel

Nada más en este sprint:

- ❌ Sin carrito todavía  
- ❌ Sin Mercado Pago todavía  

✅ Objetivo del sprint: **ver precio dinámico funcionando de punta a punta**.

