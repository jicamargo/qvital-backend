# Plan de lanzamiento: de develop a ventas reales con bajo presupuesto

_Creado: 2026-10-19 · Estado: propuesto, pendiente de aprobación_

Objetivo: salir rápido a producción con dominio propio, hacer publicidad, vender por la app y mejorarla con datos reales. El costo fijo tiene que ser bajo para que la app se pague sola desde las primeras ventas.

Este plan cubre el negocio y el orden de las cosas. Los pasos técnicos del deploy siguen en [`deploy-produccion-plan.md`](deploy-produccion-plan.md). La Entrega 3 de la Brújula (retención) queda **después** del lanzamiento, para diseñarla con datos de usuarias reales.

---

## Modelo de negocio (confirmado por Jorge el 2026-10-19)

El objetivo principal es **vender productos Herbalife en el marketplace**. Brújula, Coach y el resto son valor agregado para retener y convertir. Premium se gana comprando: toda compra de al menos el umbral da 30 días. Quien quiera Premium sin comprar productos compra un producto "Plan Premium x 1 mes" en el mismo marketplace. No hay suscripción ni cobros automáticos.

**Por qué funciona:** los 30 días coinciden con el ciclo de consumo (un tarro de batido rinde ~1 mes). Premium se vuelve el motivo para recomprar cada mes, sin sistema de suscripciones.

**Ajustes necesarios para que el ciclo funcione:**
1. **Acumular días en vez de reiniciar.** Hoy, comprar el día 25 descarta los 5 días restantes, lo que castiga a quien recompra temprano. Cambiar a `premium_expires_at = max(ahora, vencimiento actual) + 30 días`.
2. **Recordatorio de recompra:** un correo (Resend + Solid Queue) unos 5 días antes del vencimiento, con un botón **"Repetir mi último pedido"**. Es el motor de ventas recurrentes.
3. **Umbral** (hoy COP 200.000 por defecto) ≈ la compra mensual típica de una clienta (el combo básico). Si queda por encima, las clientas recurrentes pierden Premium.
4. **Producto "Plan Premium x 1 mes":** un producto digital marcado con `premium_days: 30`. No pide dirección ni cobra envío si el carrito solo trae productos digitales, y otorga Premium siempre, sin importar el umbral. Su precio debe hacer que comprar producto sea la mejor opción ("o Premium gratis con tu compra del mes").

**Decisiones del 2026-10-19:**
- **Herbalife permite vender en un sitio propio si las páginas de venta requieren login.** Hoy se cumple: el marketplace, el carrito, el checkout y la API `/products` exigen sesión, y la landing y `/evaluacion` no muestran productos ni precios. Mantenerlo así: los anuncios y las imágenes OG nunca muestran productos ni precios.
- **"Plan Premium x 1 mes" = COP 30.000.** Con tarjeta, Wompi deja ~COP 28.000 netos.
- **El envío siempre es gratis.** Jorge hace el pedido en Herbalife a nombre de la clienta, y Herbalife lo envía sin costo. El backend fija `shipping_cost = 0` e ignora lo que mande el frontend, lo que cierra también el hueco de seguridad.

## 0. Política de Herbalife (resuelta el 2026-10-19: se permite con login)

La app vende productos Herbalife desde su propio marketplace (Wompi). La FAQ global de Herbalife dice que los distribuidores **no pueden vender por sitios web propios ni marketplaces**: solo por plataformas creadas por Herbalife, como Go Herbalife ([fuente](https://www.herbalife.com/en-us/frequently-asked-questions/can-herbalife-independent-distributors-sell-on-amazon-or-ebay)). No encontré la política específica de Colombia.

Si esa regla aplica en Colombia, hacer publicidad pagada de un sitio que vende Herbalife arriesga la cuenta de distribuidor. **Antes de pagar un solo anuncio**, confirmar con el upline o con Herbalife Colombia (manual del distribuidor) qué está permitido. Hay tres escenarios:

| Escenario | Qué se vende en la app | Cambio en el código |
|---|---|---|
| **A. Está permitido** vender productos por un sitio propio | Productos (Wompi), y Premium sale como bono por compra, igual que hoy | Ninguno |
| **B. No está permitido; los productos van por Go Herbalife** | **Premium como suscripción propia** (contenido: Brújula, plan, recetas), cobrada con Wompi. Los productos se compran en la tienda Go Herbalife oficial (enlace saliente) | Producto "Premium mensual" que se compra directo. El marketplace se convierte en catálogo con botón "Comprar en mi tienda oficial" |
| **C. Mixto** (por ejemplo, permitido con restricciones de publicidad) | Según lo que diga la política | Según el caso |

El escenario B no es peor: Premium es un producto propio, con margen casi total, que no depende de inventario ni de envíos. La app queda como herramienta de captación y retención, y los productos se venden por el canal oficial.

## 1. Infraestructura con costo mínimo

Precios de octubre de 2026 tomados de fuentes de terceros. Confirmarlos en cada proveedor antes de pagar.

| Pieza | Elección para lanzar | Costo | Por qué |
|---|---|---|---|
| Base de datos, Auth y Storage | **Supabase Free** (proyecto nuevo) | US$0 | 500 MB de DB y 50k usuarios activos sobran para empezar. El riesgo es que pausa el proyecto tras 7 días sin actividad (con tráfico real no pasa) y que no tiene backups. Se mitiga con un `pg_dump` diario por GitHub Actions (gratis) |
| Backend Rails | **Render Starter** | US$7/mes | El plan gratis se duerme a los 15 min y tarda ~1 min en despertar: inaceptable para una usuaria mayor que abre la app. El Starter está siempre encendido |
| Frontend Next.js | **Render Starter**, junto al backend | US$7/mes | **Vercel Hobby prohíbe el uso comercial**, y Vercel Pro cuesta US$20/mes. Rails no corre en Vercel. Render deja todo en un solo panel y una sola región, sin riesgo de compatibilidad. Si se quiere lo nativo de Vercel, pasar a Vercel Pro cuando haya ventas |
| Dominio | Cloudflare Registrar | ~US$10–30/año | Precio de costo, DNS gratis. Disponibilidad al 2026-10-19 (RDAP): `qvital.com` **ocupado**. Libres: `qvitalapp.com`, `miqvital.com`, `qvitalbienestar.com`, `qvital.app` (~US$14/año) y `qvital.ai` (~US$80+/año, mínimo 2 años). `.co` y `.com.co` sin verificar. **`.ia` no existe** |
| Correo transaccional | **Resend Free** | US$0 | 3.000 correos/mes. Ya está integrado en el backend |
| Pagos | **Wompi** | Solo comisión por venta | Sin mensualidad. Tarjeta ~2,99% + IVA + COP 600; PSE y Nequi menos. QR bajó a 1% + IVA en sept. 2026 |
| Analítica | **PostHog Free** o GA4 + Meta Pixel | US$0 | Embudo: visita → evaluación → registro → compra |
| Monitoreo | Sentry Free + UptimeRobot Free | US$0 | |

**Costo fijo: ~US$15/mes** (unos COP 60 mil: 2 servicios Render Starter + dominio), más las comisiones por venta. Con la utilidad de una o dos ventas al mes se cubre.

**Cuándo subir de plan** (solo con ventas reales):
- **Supabase Pro (US$25/mes):** al llegar a ~50 usuarias pagando o al acercarse a 400 MB. Trae backups diarios.
- **Más RAM en el backend:** si Render muestra errores de memoria.

**Alternativa más barata, pero con más trabajo de mantenimiento:** un VPS (Hetzner, ~US$5/mes) con Kamal, que ya está en el repo, corriendo BE y FE juntos. Hoy no lo recomiendo: hay que mantener el servidor.

## 2. Requisitos para vender legalmente en Colombia

Confirmar con un contador. Esto no es asesoría legal.

- [ ] **Política de tratamiento de datos** (Ley 1581/2012, habeas data). Peso, cintura y estado emocional son **datos sensibles**: el registro necesita una casilla de autorización explícita. **Hoy la app no tiene ni la página ni la casilla.**
- [ ] **Términos y condiciones**: derecho de retracto (Ley 1480, 5 días hábiles en ventas a distancia), envíos, devoluciones y qué incluye Premium.
- [ ] **Aviso de salud**: la Brújula y el plan no reemplazan atención médica. Ya hay un `severity_flag`, pero falta un aviso visible en el pie de página y en la Brújula.
- [ ] **Registro del comercio en Wompi**: persona natural con RUT y cuenta bancaria. **Empezarlo ya**, porque la aprobación toma días.
- [ ] **Facturación electrónica DIAN**: según el régimen tributario de quien venda. Preguntarle al contador.

## 3. Lo mínimo que le falta a la app para lanzar

Hay que resistir la tentación de agregar features. Solo esto:

0. **Seguridad, bloqueante:** `Marketplace::Orders::Prepare` acepta `shipping_cost` tal como lo envía el frontend. Cualquiera puede mandar un valor negativo y bajar el total que cobra Wompi. El backend tiene que calcular el envío.
0. Los ajustes del modelo de negocio: acumular días, recordatorio de recompra con "Repetir mi último pedido" y el producto "Plan Premium x 1 mes".
1. Las páginas legales de la sección 2, enlazadas en el pie de página y en el registro.
2. **Botón de WhatsApp** flotante (wa.me con mensaje prellenado). Para el público objetivo, WhatsApp es el canal de confianza y de cierre de venta.
3. Analítica y Meta Pixel, con eventos de evaluación completada, registro y compra.
4. Metadatos para compartir: título, descripción e imagen OG para cuando se comparte el enlace por WhatsApp o Facebook. Hoy el `public/` tiene los íconos por defecto de Next.
5. Si se confirma el escenario B: el producto "Premium mensual" con compra directa.
6. **Recorrido completo en el navegador** del flujo de compra → premium → banner. Desde el 2026-09-07 nunca se verificó en un navegador real.
7. El renombre "Coach IA" → "Brújula Corporal" en el acceso rápido del dashboard (decisión del 2026-10-19).

## 4. Publicidad con poco presupuesto

**Embudo:** anuncio o publicación → `/evaluacion` (gratis, ya existe y guarda el lead) → registro → demo de la Brújula → compra. WhatsApp sirve de respaldo en cada paso.

1. **Orgánico primero (US$0):** Instagram y Facebook con recetas de la app (119, con foto), tips de la Brújula y testimonios con permiso. Grupos de Facebook y estados de WhatsApp. La red personal y de clientes actuales es el primer público.
2. **Meta Ads de prueba:** ~COP 20–30 mil diarios durante 2 semanas, 2–3 anuncios distintos, apuntando a `/evaluacion`. Reglas de Meta:
   - segmentación 18+ obligatoria en salud y peso;
   - sin fotos de antes y después;
   - sin pellizcos de grasa;
   - sin promesas de curar.
   - Ojo también con la política de Herbalife sobre usar su marca en anuncios.
3. **Google Business Profile** (gratis) si hay atención presencial.
4. **No pagar Google Ads con términos de marca Herbalife** sin confirmarlo en la política (sección 0).

**Métrica que manda:** costo por venta frente a margen por venta. Si una venta cuesta más en anuncios de lo que deja, se ajusta antes de escalar.

## 5. Mejorar con datos (después del lanzamiento)

- **Revisión semanal (15 min):** visitas, evaluaciones, registros, compras, Premium activas y demo → Premium (`coach_demo_views`).
- **Hablar con 5 usuarias reales** en el primer mes: dónde se pierden y qué no entienden.
- Con esos datos se diseña la **Entrega 3 de la Brújula** (retención: seguimiento de la práctica y widget en el dashboard). Ya está decidido el enfoque A + un poco de C.

## 6. Cronograma propuesto

| Semana | Trabajo | Quién |
|---|---|---|
| **1** | Confirmar la política de Herbalife (sección 0). Iniciar el registro en Wompi. Comprar el dominio. Pedir al contador la revisión legal y tributaria | Jorge |
| **1** | Fase 1 del deploy (código listo para prod). Páginas legales, WhatsApp, analítica, metadatos OG y el renombre | Claude + Jorge |
| **2** | Supabase prod, Render, frontend y DNS (fases 2–5 del deploy). Prueba con una compra real de bajo monto | Claude + Jorge |
| **2** | **Beta cerrada:** 5–10 conocidas usan la app una semana | Jorge |
| **3** | Ajustes de la beta. Arranca el contenido orgánico | Ambos |
| **4–5** | Prueba de Meta Ads. Primera revisión de métricas | Jorge |
| **6+** | Entrega 3 (retención) con datos reales | Claude + Jorge |

## Decisiones pendientes de Jorge

1. Qué dice la política de Herbalife: escenario A, B o C.
2. El nombre del dominio (`qvital.co`, `qvital.com.co` u otro). Hay que verificar que esté libre.
3. El precio del "Plan Premium x 1 mes", y si el umbral de COP 200.000 refleja la compra mensual típica.
5. Cómo se cobra el envío: tarifa fija, por ciudad o gratis desde cierto monto. Lo necesita el arreglo de seguridad.
4. El frontend en Cloudflare (gratis, con algo de riesgo de compatibilidad) o en Render (US$7/mes, seguro).
