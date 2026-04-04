# Plan de implementación: pedidos visibles para admin y acotados para cliente

Objetivo: el **cliente** sigue viendo solo sus órdenes vía marketplace; el **admin** obtiene API dedicada para ver y gestionar **todas** las órdenes. Sin multi-compañía en esta fase.

---

## Fase 0 — Inventario (corto)

- [ ] Confirmar campos editables en `orders` (`status`, `shipping_date_estimated`, `shipping_date_real`, `tracking_info`, `total_amount`).
- [ ] Revisar `Marketplace::Orders::List` y serialización en `OrdersController` para **reutilizar** estructura JSON en admin (DRY: blueprint/helper compartido o interactor admin que delegue en presentadores).

---

## Fase 1 — Rutas y autorización

- [ ] En `config/routes.rb`, bajo `namespace :admin`, añadir recursos de órdenes, por ejemplo:
  - `GET /api/v1/admin/orders` → `index`
  - `GET /api/v1/admin/orders/:id` → `show`
  - `PATCH /api/v1/admin/orders/:id` → `update` (solo campos operativos)
- [ ] Crear `Api::V1::Admin::OrdersController` con `before_action :authenticate_user!` y `before_action :authorize_admin!` (mismo patrón que productos admin).

---

## Fase 2 — Casos de uso (interactors)

- [ ] `Admin::Orders::List` — scope base `Order.all` (o `Order.includes(...)`), paginación, filtros:
  - `status` (enum válido),
  - opcional: `from` / `to` sobre `orders.created_at`,
  - opcional: búsqueda por `purchase.purchase_number`, `purchase_intent.external_reference`, `user.email` (joins cuidadosos).
- [ ] `Admin::Orders::Show` — carga por `id` con las mismas asociaciones que el detalle necesite.
- [ ] `Admin::Orders::Update` — actualización transaccional de `order` con strong params permitidos; validar transiciones de `status` si se define una máquina de estados mínima.

---

## Fase 3 — Serialización y contrato HTTP

- [ ] Definir blueprint(s) para listado y detalle admin (pueden extender los de marketplace o compartir partials).
- [ ] Incluir en detalle admin identidad del comprador: `user.id`, `email`, nombre si existe (desde `users`), más `purchase`, `purchase_intent`, `payments` resumidos.
- [ ] Documentar en `docs/endpoints/api-v1-admin-orders-*.md` request/response y errores (`403`, `404`, `422`).

---

## Fase 4 — Marketplace sin regresiones

- [ ] Verificar que `GET /api/v1/marketplace/orders` **no** cambie su semántica: sigue filtrando por `purchases.user_id = current_user.id`.
- [ ] Añadir test de request: usuario `cliente` no puede acceder a `GET /api/v1/admin/orders` (403).
- [ ] Añadir test: usuario `cliente` no puede ver `GET /api/v1/admin/orders/:id` de otro usuario (403 en ruta admin; opcionalmente 404 para no filtrar existencia).

---

## Fase 5 — Calidad y observabilidad

- [ ] Tests de integración para list paginado, filtros y update.
- [ ] Revisar logs en staging: tiempo total, tiempo ActiveRecord, número de queries; corregir N+1 si aparece.
- [ ] Si el webhook de pago actualiza `Order` / `Purchase`, documentar en el mismo doc de endpoints cómo queda el estado respecto a lo que el admin puede editar manualmente (evitar pisar sin criterio).

---

## Fase 6 — Mejoras opcionales (post-MVP)

- [ ] Auditoría: `paper_trail` o tabla `order_admin_events` (quién cambió qué y cuándo).
- [ ] Export CSV para operaciones.
- [ ] Notificaciones al cliente cuando el admin cambia `status` o tracking.
- [ ] Cuando exista multi-compañía: filtro `company_id` en list admin y asignación en `prepare`.

---

## Criterios de aceptación

1. Un usuario con `role: admin` lista y ve cualquier orden del sistema vía API admin.
2. Un usuario con `role: cliente` solo ve sus órdenes en marketplace y recibe 403 en rutas admin de órdenes.
3. Sin duplicar filas de negocio: una fila en `orders` por compra como hoy.
4. Documentación de endpoints actualizada y tests mínimos verdes.
