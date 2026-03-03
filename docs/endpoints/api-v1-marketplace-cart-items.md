### [ ] Endpoints: Cart Items Marketplace

Incluye:

- `POST /api/v1/marketplace/cart/items`
- `PATCH /api/v1/marketplace/cart/items/:id`
- `DELETE /api/v1/marketplace/cart/items/:id`

---

### 1. POST /api/v1/marketplace/cart/items (Agregar item)

#### 1.1 Descripción (Backend)

Agrega un producto al carrito abierto del usuario.  
Si ya existe un `cart_item` para ese `product_id`, suma la cantidad.

- **Método**: `POST`
- **URL**: `/api/v1/marketplace/cart/items`
- **Auth**: Requiere JWT válido.

#### 1.2 Request

##### Headers

- `Authorization: Bearer <access_token>`
- `Content-Type: application/json`

##### Body (JSON)

```json
{
  "cart_item": {
    "product_id": 3,
    "quantity": 2,
    "price_snapshot": "850.00"
  }
}
```

#### 1.3 Responses

##### 200 OK

```json
{
  "cart": {
    "id": 1,
    "status": "open",
    "cart_items": [
      {
        "id": 10,
        "quantity": 2,
        "price_snapshot": "850.00",
        "product": {
          "id": 3,
          "name": "Proteína Herbal",
          "price": 850.0
        }
      }
    ]
  }
}
```

##### 422 Unprocessable Entity

```json
{
  "error": "Quantity must be greater than 0"
}
```

---

### 2. PATCH /api/v1/marketplace/cart/items/:id (Actualizar cantidad)

#### 2.1 Descripción (Backend)

Actualiza la cantidad de un `cart_item` existente.  
Si la cantidad es `0` o negativa, el item se elimina.

#### 2.2 Request

```http
PATCH /api/v1/marketplace/cart/items/:id
```

Body:

```json
{
  "cart_item": {
    "quantity": 3
  }
}
```

#### 2.3 Responses

- `200 OK` con el carrito actualizado.
- `422 Unprocessable Entity` si no se encuentra el item o hay errores de validación.

---

### 3. DELETE /api/v1/marketplace/cart/items/:id (Eliminar item)

#### 3.1 Descripción

Elimina un `cart_item` del carrito del usuario.

#### 3.2 Request

```http
DELETE /api/v1/marketplace/cart/items/:id
```

#### 3.3 Responses

- `200 OK` con el carrito actualizado (sin el item).
- `422 Unprocessable Entity` si el item no existe o no pertenece al usuario.

---

### 4. Implementación (Backend)

- **Controllers**:
  - `Api::V1::Marketplace::CartItemsController#create`
  - `Api::V1::Marketplace::CartItemsController#update`
  - `Api::V1::Marketplace::CartItemsController#destroy`

- **Interactors**:
  - `Marketplace::Carts::AddItem`
  - `Marketplace::Carts::UpdateItem`
  - `Marketplace::Carts::RemoveItem`

- **Blueprints**:
  - `CartBlueprint`
  - `CartItemBlueprint`
  - `ProductBlueprint`

---

### 5. Uso (Frontend)

Ejemplo de agregar item:

```ts
const response = await fetch(
  `${process.env.NEXT_PUBLIC_API_URL}/api/v1/marketplace/cart/items`,
  {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({
      cart_item: {
        product_id,
        quantity,
        price_snapshot,
      },
    }),
  }
);
```

