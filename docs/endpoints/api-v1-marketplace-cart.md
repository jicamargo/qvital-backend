### [ ] Endpoint: GET /api/v1/marketplace/cart

---

### 1. Descripción (Backend)

Obtiene el carrito abierto (`status = open`) del usuario autenticado.  
Si no existe un carrito abierto, devuelve `cart: null`.

- **Método**: `GET`
- **URL**: `/api/v1/marketplace/cart`
- **Auth**: Requiere JWT válido (`Authorization: Bearer <token>`)

#### Comportamiento

- Busca el carrito más reciente con `status = open` asociado al usuario actual.
- Incluye sus `cart_items` y la información de producto necesaria para el marketplace.

---

### 2. Request

#### Headers

- `Authorization: Bearer <access_token>`
- `Content-Type: application/json`

#### Body

No requiere body.

---

### 3. Responses (Backend)

#### 200 OK – Carrito encontrado

```json
{
  "cart": {
    "id": 1,
    "status": "open",
    "created_at": "2026-03-03T18:00:00Z",
    "updated_at": "2026-03-03T18:05:00Z",
    "cart_items": [
      {
        "id": 10,
        "quantity": 2,
        "price_snapshot": "500.00",
        "metadata": {
          "name": "Producto ejemplo",
          "category": "Proteínas"
        },
        "product": {
          "id": 3,
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
      }
    ]
  }
}
```

#### 200 OK – Sin carrito abierto

```json
{
  "cart": null
}
```

#### 401 Unauthorized

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

#### 422 Unprocessable Entity

```json
{
  "error": "User is required"
}
```

---

### 4. Implementación (Backend)

- **Controller**: `Api::V1::Marketplace::CartsController#show`
  - Hereda de `Api::V1::BaseController`
  - Usa `authenticate_user!` y `current_user` del concern `Authenticatable`
  - Orquesta:
    - `result = Marketplace::Carts::FetchOpen.call(user: current_user)`
    - `CartBlueprint.render(result.cart, level_id: current_user.level_id)`

- **Interactor**: `Marketplace::Carts::FetchOpen`
  - Entrada: `user`
  - Lógica:
    - Valida presencia de usuario.
    - Busca carrito abierto más reciente para ese usuario.

- **Blueprints**:
  - `CartBlueprint`
  - `CartItemBlueprint`
  - `ProductBlueprint`

---

### 5. Uso (Frontend)

Ejemplo en Next.js:

```ts
const response = await fetch(
  `${process.env.NEXT_PUBLIC_API_URL}/api/v1/marketplace/cart`,
  {
    method: "GET",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${token}`,
    },
  }
);

if (!response.ok) {
  // manejar error
}

const data = await response.json();
const cart = data.cart;
```

