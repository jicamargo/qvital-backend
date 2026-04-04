# Pedidos: visibilidad cliente vs administrador — recomendaciones

## Contexto

- **No multi-compañía por ahora**: un solo catálogo y un solo “tenant” lógico; los campos `company_id` en `purchase_intents` / `purchases` pueden quedar en `NULL` hasta que exista un modelo B2B real.
- **Cliente** (`role: cliente`): debe ver **solo** las órdenes ligadas a su usuario (`purchases.user_id`).
- **Administrador de la app** (`role: admin`): debe **listar, ver y actualizar** el ciclo operativo de **todas** las órdenes de todos los clientes (fulfillment: estado, fechas, tracking, notas si aplica).

El modelo de datos actual ya separa bien **pago** (`purchases`, `payments`) de **orden operativa** (`orders`, `order_items`). No hace falta una tabla nueva solo por “ser admin”; hace falta **autorización y endpoints** distintos.

---

## Principios de diseño

### 1. Dos superficies de API, misma tabla `orders`

| Audiencia | Ruta sugerida | Alcance |
|-----------|---------------|---------|
| Cliente | `GET /api/v1/marketplace/orders` (existente) | `Order` donde `purchase.user_id == current_user.id` |
| Admin | `GET /api/v1/admin/orders` (nuevo) | Todas las `Order` (con paginación y filtros) |

Ventaja: una sola fuente de verdad; el admin no “duplica” pedidos en otra tabla.

### 2. Autorización explícita en admin

Reutilizar el patrón ya usado en `Api::V1::Admin::ProductsController`:

- `authenticate_user!` (JWT).
- `authorize_admin!` → `current_user.admin?` (basado en `users.role`, alineado con `auth-requirements` / Supabase).

Nunca exponer un parámetro `user_id` en marketplace para “ver órdenes de otro”; el cliente solo ve las suyas por `current_user`.

### 3. Qué puede hacer el admin (MVP razonable)

- **Listar** órdenes con paginación (`page`, `per_page` con tope).
- **Filtrar** por `status`, opcionalmente por rango de fechas y búsqueda simple (email del comprador, `purchase_number`, `external_reference` del intent) según necesidad de producto.
- **Ver detalle** de una orden: misma información rica que el cliente (ítems, purchase, payments, intent) pero sin restricción de `user_id`.
- **Actualizar** campos operativos en `orders`: `status`, `shipping_date_real`, `tracking_info` (JSON), y en el futuro notas internas si se agrega columna.

Evitar en MVP que el admin cree órdenes “a mano” salvo que sea requisito explícito: reduce superficie de fraude y complejidad contable.

### 4. Rendimiento y consistencia

- En listados admin, usar el mismo criterio que `Marketplace::Orders::List`: `includes` / `preload` de `order_items`, `product`, `category`, `purchase`, `purchase_intent`, `payments` para no incurrir en N+1.
- Para conteos y listas grandes, índices útiles: `orders(status, created_at)`, `purchases(user_id)`, y los que ya existan por `external_reference` en intents/payments.

### 5. Multi-compañía futura (sin implementarla ahora)

Cuando exista:

- Asignar `company_id` en intención/compra y **filtrar el listado admin por compañía** o por “organización del admin”.
- Hasta entonces, **un admin ve todo** el universo de órdenes del despliegue (coherente con “una sola app QVITAL”).

### 6. Frontend / producto

- Panel admin: consume solo rutas `/api/v1/admin/orders*`.
- App cliente: sigue usando marketplace; no mezclar permisos en un solo endpoint con flags.

---

## Riesgos y mitigación

| Riesgo | Mitigación |
|--------|------------|
| Fuga de datos entre clientes | Marketplace siempre filtra por `current_user`; tests de request que un cliente no vea `id` ajeno. |
| Admin sin rol bien sincronizado | Mantener `role` en BD como fuente para API; documentar que cambios de rol deben reflejarse en Supabase/FE según flujo actual. |
| Listados lentos | Paginación obligatoria, índices, evitar serializar payloads enormes en index. |

---

## Documentación y contrato

- Añadir especificación en `docs/endpoints/` para cada ruta admin nueva (cuerpo, query params, códigos HTTP), siguiendo `general-rules.md`.
- Opcional: actualizar `admin-module-req.md` con una sección “Pedidos (fase 2 admin)” para no dispersar requisitos.
