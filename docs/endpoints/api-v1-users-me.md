### [X] Endpoint: PATCH /api/v1/users/me

---

### 1. Descripcion (Backend)

Actualiza los datos de perfil del usuario autenticado: nombre, apellido, telefono y direccion.

- **Metodo**: `PATCH`
- **URL**: `/api/v1/users/me`
- **Auth**: Requiere JWT valido.

---

### 2. Request

#### Body

Todos los campos son opcionales; solo se actualizan los presentes en el body.

```json
{
  "name": "Jorge",
  "last_name": "Camargo",
  "phone": "3001234567",
  "address": {
    "street": "Calle 1 # 2-34",
    "city": "Bogota",
    "state": "Cundinamarca",
    "zipCode": "110111"
  }
}
```

---

### 3. Responses (Backend)

#### 200 OK

```json
{
  "user": {
    "id": 1,
    "email": "user@example.com",
    "supabase_uid": "...",
    "role": "cliente",
    "name": "Jorge",
    "last_name": "Camargo",
    "hlf_id": null,
    "phone": "3001234567",
    "address": { "street": "Calle 1 # 2-34", "city": "Bogota", "state": "Cundinamarca", "zipCode": "110111" },
    "level_id": 1,
    "level": { "id": 1, "name": "Cliente", "priority": 1 },
    "app_metadata": { "role": "cliente" }
  }
}
```

#### 422 Unprocessable Entity

```json
{
  "error": "Validation error message"
}
```

---

### 4. Implementacion (Backend)

- **Controller**: `Api::V1::UsersController#update_me`
  - Permite `:name, :last_name, :phone, address: [:street, :city, :state, :zipCode]`.
  - Llama a `Users::UpdateProfile.call(user:, attributes:)`.

- **Interactor**: `Users::UpdateProfile`
  - Solo asigna los atributos presentes (permite updates parciales).
  - Serializa con `UserBlueprint` (incluye `last_name`, `phone`, `address`).

---
