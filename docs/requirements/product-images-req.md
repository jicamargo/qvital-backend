## Requerimientos – Imágenes de Productos (Supabase Storage + Rails API)

### 1. Objetivo

Definir la estrategia oficial para gestionar **imágenes de productos** en QVITAL, alineada con:

- Rails como **API stateless** (sin manejo de archivos binarios).
- Supabase como **Storage + CDN**.
- Frontend responsable de la subida directa.
- Backend solo almacena referencias (`image_url` / `image_path`) y aplica reglas de negocio.

Decisión arquitectónica para el MVP:

- **Frontend sube la imagen directamente a Supabase Storage.**
- **Frontend obtiene la URL pública.**
- **Frontend envía esa URL a Rails.**
- **Rails la guarda en `products.image_url` (y opcionalmente `image_path`).**

Rails **no** manejará archivos binarios ni usará ActiveStorage en el MVP.

---

## 2. Backend (Rails API)

### 2.1 Modelo y base de datos

- [X] Asegurar que el modelo `Product` tenga los siguientes campos:
  - [X] `image_url` (`string`, puede ser `NULL` en MVP).
  - [X] `image_path` (`string`, pensado para gestión futura de borrado en Storage).

Recomendación de migración (si no existe):

```ruby
change_table :products, bulk: true do |t|
  t.string :image_url
  t.string :image_path
end
```

### 2.2 Validaciones y reglas de negocio

- [X] No validar presencia de `image_url` en MVP (imagen opcional).
- [ ] (Opcional futuro) Validar formato básico de URL (`https://` y dominio Supabase).

Ejemplo opcional:

```ruby
validates :image_url,
          format: { with: /\Ahttps:\/\/.+\z/ },
          allow_nil: true
```

### 2.3 Endpoints que deben soportar `image_url`

Backend ya tiene:

- `Api::V1::ProductsController#index` (lectura pública/autenticada).
- `Api::V1::Admin::ProductsController` (CRUD admin).

Requerimientos:

- [X] **Crear producto (admin)**:
  - Endpoint: `POST /api/v1/admin/products`
  - Debe aceptar `image_url` y opcionalmente `image_path` en el payload.
- [X] **Actualizar producto (admin)**:
  - Endpoint: `PUT/PATCH /api/v1/admin/products/:id`
  - Debe permitir actualizar `image_url` (reemplazo) y opcionalmente `image_path`.
- [X] **Listar productos (frontend / marketplace)**:
  - Endpoint: `GET /api/v1/products`
  - Debe devolver `image_url` en el blueprint `ProductBlueprint`.

Ejemplo de body esperado en admin:

```json
{
  "product": {
    "name": "Proteína Herbal",
    "sku": "HBL-123",
    "pv": 230.85,
    "category_id": 2,
    "active": true,
    "image_url": "https://<project>.supabase.co/storage/v1/object/public/products/abc123.webp"
  }
}
```

### 2.4 Borrado y limpieza (futuro)

Para el MVP:

- [X] Al hacer `DELETE /api/v1/admin/products/:id` (soft delete actual), **no** es obligatorio borrar el archivo en Supabase.

Para una fase posterior:

- [ ] Guardar también `image_path` (ruta interna en el bucket).
- [ ] Crear un servicio para, al archivar/eliminar un producto, llamar a Supabase Storage y eliminar la imagen correspondiente.

Pseudocódigo futuro:

```ruby
SupabaseStorageClient.delete("products", product.image_path) if product.image_path.present?
```

---

## 3. Frontend (Next.js / Admin Panel / Marketplace)

### 3.1 Flujo en el panel admin (creación/edición de producto)

Requerimientos de alto nivel:

- [ ] El panel admin (`/admin/products/new` y `/admin/products/[id]/edit`) debe:
  - [ ] Permitir seleccionar un archivo de imagen (`<input type="file">`).
  - [ ] Subir la imagen a Supabase Storage (bucket `products`) usando el SDK de Supabase.
  - [ ] Obtener la URL pública de la imagen.
  - [ ] Enviar esa `image_url` (y opcionalmente `image_path`) al backend Rails en el payload del producto.

Ejemplo de flujo en frontend (simplificado):

```ts
const fileExt = file.name.split(".").pop();
const fileName = `${crypto.randomUUID()}.${fileExt}`;

const { error: uploadError } = await supabase.storage
  .from("products")
  .upload(fileName, file);

if (uploadError) throw uploadError;

const { data: publicUrlData } = supabase.storage
  .from("products")
  .getPublicUrl(fileName);

const imageUrl = publicUrlData.publicUrl;

await fetch(`${API_URL}/api/v1/admin/products`, {
  method: "POST",
  headers: {
    "Content-Type": "application/json",
    Authorization: `Bearer ${token}`,
  },
  body: JSON.stringify({
    product: {
      name,
      sku,
      pv,
      category_id,
      active: true,
      image_url: imageUrl,
    },
  }),
});
```

### 3.2 Renderizado en el marketplace (frontend público/autenticado)

- [ ] En la UI de productos (por ejemplo, `ProductCard` en el marketplace), usar `product.image_url`:
  - [ ] Mostrar la imagen si existe.
  - [ ] Usar placeholder si `image_url` es `null`.

Ejemplo:

```tsx
<Image
  src={product.image_url ?? "/images/product-placeholder.webp"}
  alt={product.name}
  width={300}
  height={300}
/>
```

---

## 4. Supabase Storage – Configuración y Policies

### 4.1 Bucket `products`

- [ ] Crear bucket `products` en Supabase Storage.
- [ ] Configuración mínima para MVP:
  - [ ] Bucket **público**.
  - [ ] Limitar MIME types a `image/jpeg`, `image/png`, `image/webp`.
  - [ ] Limitar tamaño de archivo (ej. `<= 5MB`).

### 4.2 Seguridad de subida (solo admins)

Requerimiento funcional:

- Solo **usuarios admin** autenticados pueden subir imágenes al bucket `products`.
- Cualquier usuario (o público) puede **leer** las imágenes (por ser bucket público).

Estrategia recomendada:

- Incluir el `role` del usuario en el JWT de Supabase (via `user_metadata` u otro mecanismo).
- Crear policy en `storage.objects` que use `auth.jwt()` para filtrar por `role = 'admin'`.

Ejemplo de policy (conceptual) para `INSERT`:

```sql
auth.jwt() ->> 'role' = 'admin'
```

Requerimientos:

- [ ] Definir claramente cómo se sincroniza/establece el `role` en el JWT de Supabase (`admin` vs `cliente`).
- [ ] Crear policy en:
  - Tabla: `storage.objects`
  - Bucket: `products`
  - Operación: `INSERT`
  - Condición: `auth.jwt() ->> 'role' = 'admin'`
- [ ] Permitir `SELECT` público explícitamente (opcional pero recomendado):

```sql
true
```

### 4.3 Uso del cliente de Supabase en frontend

- [ ] El frontend debe crear el cliente con `anonPublicKey` (NUNCA `service_role`).

```ts
const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
```

- [ ] Asegurar que el usuario esté autenticado (Supabase Auth) antes de subir.

---

## 5. Resumen de tareas

### Backend (Rails)

- [X] Agregar campos `image_url` (y opcional `image_path`) a `products` si no existen.
- [X] Asegurar que:
  - [X] `POST /api/v1/admin/products` acepte y persista `image_url`.
  - [X] `PUT/PATCH /api/v1/admin/products/:id` permitan actualizar `image_url`.
  - [X] `GET /api/v1/products` devuelva `image_url` en `ProductBlueprint`.
- [ ] (Futuro) Implementar limpieza de imágenes en Supabase cuando se archiva/elimina un producto.

### Frontend

- [ ] Implementar subida de imágenes en el formulario de producto del panel admin:
  - [ ] Selección de archivo.
  - [ ] Subida a Supabase Storage (bucket `products`).
  - [ ] Obtención de `image_url`.
  - [ ] Envío de `image_url` al backend.
- [ ] Usar `image_url` en las cards de productos del marketplace (con placeholder si falta).

### Supabase

- [ ] Crear y configurar bucket `products`.
- [ ] Definir y aplicar policies de `INSERT` solo para admins (via `auth.jwt()`).
- [ ] Verificar que el JWT de Supabase incluya el rol (`role = 'admin'`) para los usuarios administradores.

---
