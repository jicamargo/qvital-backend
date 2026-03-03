### [ ] Endpoint: POST /api/v1/marketplace/cart/clear

---

### 1. Descripción (Backend)

Vacía el carrito abierto del usuario autenticado, eliminando todos los `cart_items` asociados.  
El carrito permanece con `status = open`.

- **Método**: `POST`
- **URL**: `/api/v1/marketplace/cart/clear`
- **Auth**: Requiere JWT válido.

---

### 2. Request

#### Headers

- `Authorization: Bearer <access_token>`
- `Content-Type: application/json`

#### Body

No requiere body.

---

### 3. Responses (Backend)

#### 200 OK – Carrito vaciado

```json
{
  "cart": {
    "id": 1,
    "status": "open",
    "cart_items": []
  }
}
```

#### 422 Unprocessable Entity

```json
{
  "error": "Open cart not found"
}
```

---

### 4. Implementación (Backend)

- **Controller**: `Api::V1::Marketplace::CartsClearController#create`
  - Hereda de `Api::V1::BaseController`
  - Llama a `Marketplace::Carts::Clear.call(user: current_user)`
  - Serializa con `CartBlueprint`

- **Interactor**: `Marketplace::Carts::Clear`
  - Entrada: `user`
  - Lógica:
    - Busca el carrito abierto más reciente del usuario.
    - Elimina todos sus `cart_items`.

---

### 5. Uso (Frontend)

```ts
await fetch(
  `${process.env.NEXT_PUBLIC_API_URL}/api/v1/marketplace/cart/clear`,
  {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${token}`,
    },
  }
);
```

