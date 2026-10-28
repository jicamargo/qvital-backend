# Etapa 2 — Modelo de negocio Premium: diseño

_Aprobado en el chat el 2026-10-28. Corresponde a la etapa 2 de [`ruta-a-produccion.md`](ruta-a-produccion.md)._

## Objetivo

Que Premium sea el motivo para recomprar cada mes: los días se acumulan, existe un "Plan Premium x 1 mes" para quien no compra productos, un correo avisa antes del vencimiento con "Repetir mi último pedido", y los correos de pedido le sirven al admin (pedir en Herbalife) y a la clienta (saber que su pedido va en camino).

## Decisiones de Jorge

- No se pide cédula: Herbalife no la exige para enviar. Se quita del alcance.
- "Repetir mi último pedido" **llena el carrito** (no salta al pago). Si el carrito tenía productos, se suman (tope 10 por producto). Precios de hoy.
- Plan + productos sobre el umbral en el mismo pedido: **se suman los días** (30 + 30). El plan no cuenta para el umbral.
- El "Plan Premium x 1 mes" se crea solo: migración idempotente + seed.

## 1. Reglas de Premium

Al confirmarse una compra (`Marketplace::Orders::Complete`, ya idempotente):

| Origen | Días |
|---|---|
| Subtotal de productos **físicos** ≥ `AppSetting.premium_purchase_threshold` | +30 |
| Cada unidad de un producto con `premium_days` | + `premium_days` × cantidad |

- Acumulación: `premium_expires_at = max(ahora, premium_expires_at) + días`. Si días = 0, no cambia nada.
- `purchase.premium_granted = true` si días > 0.
- Lógica en un objeto propio, `Premium::GrantForPurchase` (puro: recibe la compra, calcula días y actualiza el usuario). `Complete` lo llama dentro de su transacción en lugar de `grant_premium_if_qualifies!`.

### Producto digital

- Columna nueva `products.premium_days` (integer, null, > 0). Un producto con `premium_days` es **digital** (`Product#digital?`). No se agrega otro flag.
- Admin de productos: campo "Días de Premium (solo para planes)".

### Plan Premium x 1 mes

- SKU fijo `QVITAL-PREMIUM-1M`, `premium_days: 30`, precio COP 30.000 en todos los niveles, activo, sin categoría física.
- **Migración de datos** con SQL propio (no usa los modelos): `INSERT ... ON CONFLICT (sku) DO NOTHING` y precios solo para los niveles que no tengan uno. Si el producto ya existe no se toca (el admin pudo cambiar precio o texto).
- **Seed** con `find_or_create_by!(sku:)` y los mismos valores, para bases nuevas.

### Checkout sin dirección

- `Marketplace::Orders::Prepare`: si **todos** los ítems son digitales, la dirección es opcional; siguen siendo obligatorios nombre y teléfono de quien compra.
- Con al menos un producto físico, la dirección se exige como hoy.
- Al confirmar una compra solo digital, la orden pasa directo a `delivered` (no hay nada que enviar).
- Frontend: el checkout oculta la sección de dirección cuando el carrito es solo digital (el esquema Zod se vuelve condicional).

### Textos de `/premium`

"Se reinicia la ventana" → "los días se suman a los que te quedan", más la opción "o compra el Plan Premium por $30.000" con enlace al producto.

## 2. Recordatorio y "Repetir mi último pedido"

### Recordatorio

- `PremiumReminderJob`, recurrente en `config/recurring.yml`: todos los días a las 9:00 `America/Bogota` (producción y desarrollo).
- Selecciona usuarias con `premium_active`, `premium_expires_at` entre ahora y ahora + 5 días, y `premium_reminder_sent_for IS DISTINCT FROM premium_expires_at` (columna nueva `users.premium_reminder_sent_for`, datetime).
- Por cada una: `PremiumMailer.reminder(user).deliver_now` y, si no falla, `premium_reminder_sent_for = premium_expires_at`. Un fallo se registra y se reintenta al día siguiente (mientras siga en la ventana).
- Si vuelve a comprar, `premium_expires_at` cambia y el próximo vencimiento tendrá su propio recordatorio.
- Correo: asunto "Tu Premium vence el {fecha}"; saludo con nombre; qué incluye Premium; lista de su último pedido pagado y botón **"Repetir mi último pedido"** → `{FRONTEND_URL}/marketplace/repetir`; enlace secundario al Plan Premium. Si su último pedido pagado solo trae productos digitales, el botón principal es "Comprar el Plan Premium".

### Repetir el pedido

- Endpoint `POST /api/v1/marketplace/cart/repeat_last_order` → interactor `Marketplace::Cart::RepeatLastOrder`.
- Toma la última compra `confirmed` de la usuaria y suma sus ítems al carrito abierto (lo crea si no existe), con tope `CartItem::MAX_QUANTITY` y el precio actual de su nivel.
- Omite productos inactivos o sin precio para su nivel. Responde el carrito y `skipped` (nombres omitidos). Sin compras previas → 422 "Aún no tienes pedidos para repetir".
- Frontend:
  - Página `/marketplace/repetir` (protegida): llama al endpoint y lleva a `/marketplace/cart`, con el aviso "N producto(s) de tu pedido anterior ya no están disponibles" si hubo omitidos.
  - Botón "Repetir este pedido" en el pedido pagado más reciente de "Mis pedidos".

### Volver a la página original después de iniciar sesión

- `ProtectedRoute` redirige a `/login?next=<ruta actual>`; `LoginForm` (y el registro con sesión) vuelven a `next`.
- Solo se acepta `next` que empiece con `/` y no con `//` (evita redirecciones a otros sitios). Si no es válido, va a `/`.

## 3. Correos de pedido

### Correo al admin (nuevo pedido)

Se reescribe `admin_notification` (texto y HTML):

1. **Productos a pedir** (solo físicos): `SKU · nombre · sabor · xN`.
2. **Envío:** quién recibe, teléfono y dirección en líneas (calle, detalle, localidad/comuna, ciudad, departamento, código postal si existe).
3. **Pago:** total, ID de la transacción de Wompi (`payments.approved.last.provider_payment_id`) y fecha.
4. **Botón "Ver en el admin"** → `{FRONTEND_URL}/admin/orders/{order.id}`.

Compra solo digital: asunto "Nuevo pedido … (Plan Premium, sin envío)" y sin sección de envío.

### Correo a la clienta: pedido enviado

- Admin: el textarea JSON de seguimiento se reemplaza por **Transportadora**, **Número de guía** y **Enlace de rastreo** (opcional). Se guardan en `orders.tracking_info` con las claves `carrier`, `tracking_number`, `tracking_url`. `normalize_tracking` acepta solo esas claves; el enlace debe ser `http(s)`.
- `Admin::Orders::Update`: si la orden queda en `shipped` y `orders.shipped_notified_at` (columna nueva) es null → guarda la fecha y encola `OrderMailer.shipped(order)` después de guardar. Nunca se envía dos veces.
- Correo "¡Tu pedido va en camino!": productos, transportadora y guía (o "pronto te compartimos el número de guía"), botón "Rastrear mi pedido" si hay enlace, y "Ver mi pedido" → `/marketplace/orders/{id}`.
- "Mis pedidos" (detalle) muestra transportadora, guía y enlace.

## Datos nuevos (una migración de esquema + una de datos)

| Tabla | Columna | Tipo |
|---|---|---|
| `products` | `premium_days` | integer, null |
| `users` | `premium_reminder_sent_for` | datetime, null |
| `orders` | `shipped_notified_at` | datetime, null |

Contrato con el frontend (regla del `CLAUDE.md` del backend): documentar `repeat_last_order` y los cambios de `prepare`, productos y órdenes en `qvital-frontend/docs/endpoints/`, y copiar `db/schema.rb` a `qvital-frontend/docs/schema.rb`.

## Pruebas (TDD)

- `Premium::GrantForPurchase`: acumula sobre un Premium vigente; parte de hoy si venció; umbral solo sobre físicos; plan × cantidad; plan + umbral = 60; sin días no cambia nada.
- `Prepare`: carrito solo digital sin dirección es válido; mixto sin dirección se rechaza.
- `Complete`: compra solo digital queda `delivered`.
- Migración de datos: correrla dos veces deja un solo producto y no cambia un precio editado.
- `PremiumReminderJob`: envía a quien vence en ≤ 5 días; no a quien vence en 6; no repite para el mismo vencimiento; sí envía tras un nuevo vencimiento; un fallo no marca enviado.
- `RepeatLastOrder`: suma al carrito con tope 10; omite inactivos; 422 sin compras.
- `Admin::Orders::Update`: correo de enviado una sola vez; claves de seguimiento filtradas.
- Mailers: contenido clave del correo al admin (SKU, sabor, ID Wompi, enlace) y del de enviado.
- Frontend (vitest): validación de `next`; esquema de checkout condicional.
- Recorrido en el navegador: comprar el plan sin dirección, repetir pedido, marcar enviado con guía.

## Fuera de alcance

Cédula; correo de "entregado"; reenviar el correo de enviado a mano; cobros automáticos o suscripciones.
