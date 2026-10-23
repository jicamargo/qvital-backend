# Ruta a producción: plan maestro

_Creado: 2026-10-23 · Fuente única de verdad: aquí se marca el avance._

Este archivo es **la lista de chequeo oficial**. Los documentos anteriores quedan como referencia:
- [`lanzamiento-plan.md`](lanzamiento-plan.md): modelo de negocio, costos y estrategia de publicidad.
- [`deploy-produccion-plan.md`](deploy-produccion-plan.md): detalle técnico de Supabase, Render y Wompi.

**Convenciones:**
- `[x]` hecho, `[ ]` pendiente.
- **(J)** lo hace Jorge, **(C)** Claude, **(J+C)** ambos.
- 🔴 bloqueante: sin esto no se cobra dinero real. 🟠 antes del lanzamiento público y de los anuncios. 🟢 después del lanzamiento.

---

## Evaluación (2026-10-23)

Revisión completa de los dos repos y del flujo de dinero, hecha en paralelo. Resumen:

| Área | Estado | Comentario |
|---|---|---|
| Pruebas del backend | ✅ 118 pasan, 0 fallas | Pero el flujo de pagos casi no tiene pruebas |
| Build del frontend | ✅ build y tsc limpios | Lint: 34 errores, no bloquean el deploy |
| Regla de Herbalife (login) | ✅ cumple | Productos y precios solo con sesión |
| **Flujo de dinero** | 🔴 **no apto** | El precio, el envío y la cantidad llegan del navegador; una orden pagada se puede alterar; los correos y el Premium se duplican |
| **Privacidad (Ley 1581)** | 🔴 **no apto** | Guarda datos de salud sin consentimiento; no hay páginas legales |
| Configuración de producción | 🔴 incompleta | `database.yml`, el arranque de Docker, CORS, hosts, mailer |
| Experiencia para el público | 🟠 | Sin páginas de error en español, botones pequeños, sin menú móvil, sin vista previa al compartir |

**Conclusión:** no se puede cobrar dinero real hasta cerrar las etapas 1 a 4 y pasar la prueba de la etapa 6.

---

## Etapa 0: Decisiones y trámites (sin código)

- [x] (J) Modelo de negocio: vender Herbalife en el marketplace; Premium se gana comprando. _2026-10-19_
- [x] (J) Política de Herbalife: se permite vender en un sitio propio si las páginas de venta requieren login. _2026-10-19_
- [x] (J) Precio del "Plan Premium x 1 mes": COP 30.000. _2026-10-19_
- [x] (J) Envío: siempre gratis, porque Herbalife lo envía directo. _2026-10-19_
- [x] (J) Hosting: Render para el FE y el BE; Supabase Free al inicio. _2026-10-23_
- [x] (J) Cuenta de comercio en Wompi registrada. _2026-10-23_ — las llaves de **producción** solo se ponen en Render (etapa 8). En local y en el ensayo general se sigue con sandbox, para no generar cobros reales por error.
- [ ] (J) 🔴 Elegir y comprar el dominio en Cloudflare Registrar. Sugerido: `miqvital.com`.
- [ ] (J) 🔴 Consultar al contador: régimen tributario, facturación electrónica DIAN y revisión de los textos legales.
- [ ] (J) Confirmar el umbral de Premium (hoy COP 200.000) frente a la compra mensual típica.
- [ ] (J) Número de WhatsApp de atención para el botón.
- [ ] (J) Crear las cuentas: Render, Resend, Sentry y PostHog (todas gratis), y el proyecto Supabase de producción.

## Etapa 1: Seguridad del dinero (backend) 🔴

Todo con pruebas automáticas. Rama `feature/checkout-seguro`.

- [ ] (C) **El precio lo pone el servidor.** `orders/prepare` arma los ítems desde el carrito del servidor (o desde `product_id` + cantidad) y saca el precio de `product_prices` según el nivel de la usuaria. Ignora cualquier `price` del request. _(prepare.rb:95,155; orders_controller.rb:39,109)_
- [ ] (C) **Envío = 0 fijo** en el servidor; se ignora `shipping_cost`. _(orders_controller.rb:43; prepare.rb:35,60)_
- [ ] (C) **Validar los productos:** cantidad entre 1 y un máximo razonable, producto `active`, monto mínimo mayor que 0. _(prepare.rb:12,57,95,140-146)_
- [ ] (C) **Una orden pagada no se modifica:** `orders/prepare` y `checkout/prepare` rechazan un intent o una compra ya confirmada. _(prepare.rb:101-116; checkout/prepare.rb:52-61)_
- [ ] (C) **Pertenencia:** `checkout/prepare` y `checkout/status` solo actúan sobre intents y transacciones de la usuaria actual. _(checkout/prepare.rb:35; checkout_controller.rb:54-101; status.rb:191-201)_
- [ ] (C) **`Complete` idempotente:** con lock y `return if confirmed?`, para que el webhook, el polling, los reintentos y la conciliación del admin no dupliquen correos ni Premium. Índice único en `payments(provider, provider_payment_id)` y en `orders.purchase_id`. _(complete.rb:20-45; reconcile_transaction.rb:63)_
- [ ] (C) **El webhook verifica el monto y la moneda:** `amount_in_cents == total*100` y COP. Si no coinciden, no se aprueba y se alerta. _(reconcile_transaction.rb:56-57)_
- [ ] (C) **Transiciones de estado:** un evento PENDING o DECLINED tardío no puede bajar un pago ya aprobado. _(reconcile_transaction.rb:104-112)_
- [ ] (C) **El carrito correcto:** `Complete` cierra el carrito de esa compra, no "el último abierto". _(complete.rb:90-94)_
- [ ] (C) **Pagos pendientes:** `Status` vuelve a consultar a Wompi si el pago lleva rato en pending. _(status.rb:28-39)_
- [ ] (C) Quitar `MARKETPLACE_MOCK_AUTO_APPROVE` del camino de producción. _(complete.rb:60-88)_
- [ ] (C) Wompi falla al arrancar si faltan variables en producción, en vez de caer en sandbox. _(wompi/config.rb:6,14)_
- [ ] (C) Admin: no permitir marcar `confirmed` una orden sin pago aprobado. _(admin/orders/update.rb:22-29)_
- [ ] (C) Número de compra sin colisiones (hoy se genera por segundo). _(prepare.rb:245-248)_
- [ ] (C) Quitar los `puts` de depuración. _(add_item.rb:21-55)_
- [ ] (C) Frontend: dejar de enviar precio y envío; quitar el texto "pago simulado (proveedor mock)" y el `console.log` del checkout. _(MarketplaceCheckoutContext.tsx:99,118,160-165; checkout/page.tsx:139)_
- [ ] (C) Frontend: el resultado del checkout muestra el número de compra (hoy la API no lo devuelve). _(checkout_controller.rb:66-74)_

## Etapa 2: Modelo de negocio Premium 🔴

Se diseña y se aprueba antes de programar.

- [ ] (C) Premium **acumula días:** `max(ahora, vencimiento) + 30 días`. _(complete.rb:101-110)_
- [ ] (C) El umbral de Premium se calcula sobre el subtotal de productos, no sobre el total con envío.
- [ ] (C) Producto **"Plan Premium x 1 mes"** (COP 30.000): marca `premium_days`, siempre otorga Premium y el carrito solo digital no pide dirección.
- [ ] (C) **Recordatorio de recompra** por correo ~5 días antes del vencimiento (Solid Queue recurrente + Resend).
- [ ] (C) Botón **"Repetir mi último pedido"** (en el correo y en Mis pedidos).
- [ ] (C) Correo al admin con lo necesario para pedir en Herbalife: SKU, sabor, cantidad, dirección ordenada, teléfono, cédula, ID de Wompi y enlace a `/admin/orders/:id`. _(order_mailer/_summary.text.erb:2,12)_
- [ ] (C) Correo a la clienta cuando el pedido se marca "enviado", con la guía. El campo de guía en el admin pasa a ser un formulario simple en vez de JSON. _(admin/orders/[id]/page.tsx:409-416)_

## Etapa 3: Legal y privacidad (Ley 1581) 🔴

- [ ] (C) Página **Política de tratamiento de datos.** Borrador hecho por Claude, revisado por el contador o un abogado (J).
- [ ] (C) Página **Términos y condiciones:** retracto de 5 días hábiles, envíos por Herbalife, qué incluye Premium, devoluciones.
- [ ] (C) **Aviso de salud** general: no reemplaza atención médica. Va en el pie de página, la Brújula y `/evaluacion`.
- [ ] (C) **Casilla de autorización explícita** de datos sensibles en el registro y en `/evaluacion`, guardada con fecha y versión en la DB. _(SignupForm.tsx:71-140; evaluacion/page.tsx:124-134; evaluation_leads_controller.rb:24)_
- [ ] (C) Enlaces legales en el pie de página de todas las páginas.
- [ ] (C) Filtrar los datos sensibles de los logs: peso, cintura, estado de ánimo, `user_input`, teléfono, dirección, cédula y `tx.inspect` de Wompi. _(filter_parameter_logging.rb:6-8; status.rb:145)_
- [ ] (C) Derecho de supresión: mínimo un proceso documentado ("escríbenos a…") y un borrado desde el admin que funcione con compras (anonimizar) y elimine también el usuario de Supabase Auth. _(admin/users/destroy.rb:27-31)_
- [ ] (C) Quitar o proteger como solo-admin el endpoint de depuración `POST auth/update_metadata`. _(routes.rb:12)_
- [ ] (C) Límite de solicitudes (Rails 8 `rate_limit`) en `/evaluation_leads`, el webhook y el auth sync.

## Etapa 4: Código listo para producción 🔴

Rama `feature/production-readiness`.

**Backend:**
- [ ] (C) `database.yml` de producción con `url: ENV["DATABASE_URL"]`; Queue y Cache en la misma DB; quitar Cable. _(database.yml:83-100; production.rb:47,51)_
- [ ] (C) Quitar ActiveStorage, ActionCable, Mailbox y ActionText de `application.rb` (no se usan y ahorran RAM). _(application.rb:8-14)_
- [ ] (C) **Arranque de Docker:** quitar `db:prepare` del entrypoint; en Render el pre-deploy es `bin/rails db:migrate`. _(bin/docker-entrypoint:10-12)_
- [ ] (C) Puerto en Render: `PORT`/`HTTP_PORT` y Thruster verificados. _(Dockerfile:62,68-69; puma.rb:31)_
- [ ] (C) `SOLID_QUEUE_IN_PUMA=1` y `JOB_CONCURRENCY=1` para caber en 512 MB. _(puma.rb:27,37)_
- [ ] (C) `production.rb`: el host del mailer al dominio real, `config.hosts`, SSL. _(production.rb:58,79-85)_
- [ ] (C) CORS sin el fallback `"*"`: exigir `FRONTEND_URL`. _(cors.rb:19)_
- [ ] (C) Correo: sin `RESEND_API_KEY` usar `:test`, no SMTP local; `from` y el correo del admin con el dominio verificado. _(application.rb:44-52; application_mailer.rb:2; order_mailer.rb:29)_
- [ ] (C) **Cachear las JWKS** de Supabase (~10 min) en vez de pedirlas en cada request. _(sync_user.rb:117-151)_
- [ ] (C) Sentry en el backend (plan gratis).
- [ ] (C) Arreglar `bin/brakeman` (`--ensure-latest` lo rompe) para que CI quede verde. _(bin/brakeman:5)_

**Frontend:**
- [ ] (C) Verificar que todas las `NEXT_PUBLIC_*` estén definidas en el build; si falta alguna, el build falla en vez de usar `placeholder.supabase.co`. _(lib/supabase/client.ts:16-17)_
- [ ] (C) `next.config.ts`: el host de imágenes de Supabase por variable de entorno; quitar `via.placeholder.com`. _(next.config.ts:6-15)_
- [ ] (C) Headers de seguridad: HSTS, X-Frame-Options y CSP básica.
- [ ] (C) Quitar los `console.log` de `productImages.ts`. _(productImages.ts:43-85)_
- [ ] (C) Sentry en el frontend.
- [ ] (C) Actualizar el `CLAUDE.md` del FE: Render, no Vercel; quitar las variables que no se usan.

## Etapa 5: Experiencia mínima para el público 🟠

- [ ] (C) Renombrar el acceso rápido del dashboard "Coach IA" a "Brújula Corporal". _(dashboard/page.tsx:43)_
- [ ] (C) Páginas de error y 404 en español, con un botón grande para volver. Mensaje claro si el servidor no responde.
- [ ] (C) **Menú móvil:** hoy Premium y Dashboard se ocultan en el celular. _(Navbar.tsx:114)_
- [ ] (C) Botones de mínimo 44–48 px y texto base más grande para el público mayor. _(Button.tsx:34-35; globals.css:259-263)_
- [ ] (C) Checkout: el texto de la casilla y la casilla más grandes; el código postal opcional. _(checkout/page.tsx:325,334; checkoutSchema.ts:7)_
- [ ] (C) **Botón flotante de WhatsApp.**
- [ ] (C) Vista previa al compartir: `metadataBase`, OpenGraph con imagen de marca (sin productos ni precios), favicon y apple-icon propios, robots.txt. Borrar los SVG por defecto de Next. _(layout.tsx:20-23; public/)_
- [ ] (C) Analítica: PostHog o GA4 + Meta Pixel, con eventos de evaluación, registro y compra.
- [ ] (C) Quitar `/admin/system-design` y "Opciones de configuración próximamente". _(perfil/page.tsx:340)_

## Etapa 6: Prueba integral local con Wompi sandbox 🔴

Requiere ngrok para recibir el webhook de Wompi. **No se pasa a la etapa 7 sin esto en verde.**

- [ ] (J+C) Ataque: llamar `orders/prepare` con `price:1`, cantidad `-1`, envío `-5000` y un producto inactivo → debe rechazarse o ignorarse.
- [ ] (J+C) Compra feliz con la tarjeta 4242 4242 4242 4242: el monto en Wompi es igual al de la DB, el pago queda aprobado, la orden confirmada, Premium a +30 días, y llegan **exactamente** 1 correo a la clienta y 1 al admin.
- [ ] (J+C) Reenviar el mismo webhook y recargar el resultado → sin correos nuevos y el Premium sin cambios.
- [ ] (J+C) Tarjeta rechazada (4111…) → muestra "no aprobado", el carrito se conserva y no salen correos.
- [ ] (J+C) PSE o Nequi pendiente → "en proceso", y luego se aprueba con el webhook; probar los botones del admin "verificar" y "conciliar".
- [ ] (J+C) Compra por debajo del umbral → orden confirmada, sin Premium.
- [ ] (J+C) "Plan Premium x 1 mes" → sin pedir dirección, y suma 30 días a un Premium activo.
- [ ] (J+C) Dos pestañas: lo cobrado coincide con lo pedido.
- [ ] (J+C) Reintentar `prepare` sobre una orden pagada → no cambia nada.
- [ ] (J+C) Admin: marcar enviado con guía (llega el correo), entregado, y cancelar otra orden.
- [ ] (J) **Recorrido completo desde el celular:** registro, evaluación, Brújula, recetas y compra.

## Etapa 7: Ensayo general en internet (gratis) 🔴

- [ ] (J+C) Proyecto Supabase de **producción**: us-east-1, extensiones `unaccent` y `pg_trgm`, schema con `db:migrate` (no `schema:load`), catálogo sin usuarios de prueba.
- [ ] (J+C) Storage: crear los buckets `products` y `recipes` con sus políticas (las de `products` no están en ninguna migración y se crean a mano), copiar las imágenes y reescribir los `image_url`.
- [ ] (J+C) Seguridad de Supabase: RLS activado sin políticas en `public` (o quitar `public` de la Data API); el Security Advisor en verde.
- [ ] (J+C) Auth de Supabase: URLs del sitio, plantillas en español, SMTP con Resend.
- [ ] (J+C) Render con el **plan gratis**: BE y FE desde `main`, variables de entorno, Wompi **sandbox**.
- [ ] (C) Respaldo diario `pg_dump` por GitHub Actions (Supabase Free no hace backups).
- [ ] (J+C) Repetir los puntos clave de la etapa 6 contra el ensayo general.
- [ ] (C) Merge `develop` → `main` en los dos repos (producción siempre sale de `main`).

## Etapa 8: Salida a producción (aquí empieza el gasto) 🔴

- [ ] (J) Wompi aprobó el comercio; llaves de **producción**.
- [ ] (J) Subir los dos servicios de Render a **Starter** (~US$14/mes).
- [ ] (J+C) DNS en Cloudflare: el dominio → FE, `api.` → BE, y los registros SPF, DKIM y DMARC de Resend.
- [ ] (J+C) Wompi de producción: la URL de eventos → webhook del BE; la redirección → FE.
- [ ] (J+C) **Compra real pequeña** de punta a punta, y luego el reembolso.
- [ ] (J) Crear el usuario admin de producción.
- [ ] (J+C) Uptime check de `/up` (UptimeRobot) y alertas de Sentry al correo.

## Etapa 9: Lanzamiento comercial 🟠

- [ ] (J) Beta cerrada con 5–10 conocidas durante una semana; recoger lo que les cuesta.
- [ ] (C) Ajustes de la beta.
- [ ] (C) Actualizar Ruby (3.2 está fuera de soporte) y Rails 8.0 → 8.1 (sin parches de seguridad desde 2026-10-07).
- [ ] (J) Contenido orgánico: recetas, tips y WhatsApp → `/evaluacion`.
- [ ] (J) Prueba de Meta Ads: ~COP 20–30 mil diarios, mayores de 18, sin antes y después, sin productos ni precios.
- [ ] (J) Rutina de stock: cuando un producto se agota en Herbalife, desactivarlo en `/admin/products` (y reactivarlo al volver). Máximo 10 unidades por producto por pedido.
- [ ] (J) Revisión semanal de métricas: visitas → evaluación → registro → compra, recompra y Premium.

## Etapa 10: Después del lanzamiento 🟢

- [ ] (J) Pasar a Supabase Pro (US$25) al tener ventas reales (~50 clientas o antes si se quiere tranquilidad).
- [ ] (C) Entrega 3 de la Brújula (retención: seguimiento de la práctica + widget), con datos reales.
- [ ] (C) Pruebas automáticas del resto del flujo: mailers, admin de órdenes, frontend del checkout.
- [ ] (C) Lint del FE (34 errores), `rubocop -a` en el BE (294 autocorregibles).
- [ ] (C) `rescue_from` central y mensajes de error sin detalles internos; validar `aud`/`iss` del JWT; `/up` que verifique la DB; `Admin::BaseController`.
- [ ] (C) PWA (instalar en la pantalla de inicio).
- [ ] (J) Revisión editorial de las 26 zonas de la Brújula por profesionales.
- [ ] (J) Copy de la FAQ de "Mi Premium".
