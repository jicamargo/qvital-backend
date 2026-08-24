# Fase 3 – Personalización, Objetivos de Salud, Recetas y Confianza

## 0. Contexto

Este documento incorpora un conjunto de ideas de producto recogidas por el owner (2026-08-22) y las traduce en un plan de acción técnico, siguiendo `general-rules.md`:

- Controllers minimalistas, lógica en interactors, serialización con Blueprinter.
- DRY, SOLID, desacoplado.
- Documentar cada endpoint nuevo en `docs/endpoints` cuando se implemente.
- Checklist `[ ]` / `[X]` dividido en fases y en secciones backend/frontend.
- Diseño MVP pero escalable a SaaS multi-tenant (sin añadir `store_id` todavía, pero sin bloquear su llegada).

**No se implementa nada en este documento todavía** — es la especificación y el plan de acción. Cada sub-fase se implementa y se marca cuando esté lista, generando su propio `docs/endpoints/*.md` y actualizando `docs/schema.rb` del frontend, como exige el flujo actual.

---

## 1. Mapeo idea → arquitectura

| # | Idea del owner | Dónde vive | Sub-fase |
|---|---|---|---|
| 1 | Cliente no pierde tiempo, compra directo | UX marketplace: CTA rápido + catálogo filtrado | 3.3 |
| 2 | Opción de leer mucha info para quien quiera | Patrón "contenido progresivo" (resumen + "Ver más") | 3.6 |
| 3 | Preparación/recetas: cucharadas, agua, hielo, frutos rojos opcional, según objetivo | Módulo `Recipe` + `RecipeIngredient` | 3.5 |
| 4 | Recetas según productos comprados | `Recipes::ListForUser` (match contra historial de compras) | 3.5 |
| 5 | Descargos de responsabilidad / consultar médico | Campo de disclaimer + aceptación en checkout | 3.4 |
| 6 | CTA rápida marketplace "¿qué quieres?" | `HealthGoal` + selector rápido en `/marketplace` | 3.1 + 3.3 |
| 7 | Analizar BD y taggear productos por objetivo de salud, agrupar en combos | `HealthGoal`, `product_health_goals`, (futuro) `ProductBundle` | 3.1 |
| 8 | Grupos de productos configurables por admin con color/icono | Admin CRUD de `HealthGoal` | 3.2 |
| 9 | Campo "sabor" en productos | `products.flavor` | 3.1 |
| 10 | Email de pedido al usuario + copia a admin | `OrderMailer` | 3.4 |
| 11 | Dashboard con tarjetas en orden dinámico según último uso | `UserFeatureUsage` + ordenamiento en frontend | 3.7 |
| 12 | Búsqueda de productos en marketplace y en otras páginas (admin, recetas) | `pg_search` + `pg_trgm` + `unaccent` — spec completa en [`busqueda-full-text.md`](./busqueda-full-text.md) | 3.8 |

---

## 2. Sub-fase 3.1 — Fundamentos de datos (bajo riesgo, alto valor)

### 2.1 Backend

- [X] Migración: agregar `flavor` (`string`, nullable) a `products`.
  - Justificación: pedido explícito del owner (idea #9). No se usa para variantes de precio (eso seguiría siendo `product_prices` por nivel); es un atributo informativo/filtrable, igual que `category`.
- [X] Crear tabla `health_goals`:
  ```ruby
  create_table :health_goals do |t|
    t.string  :key,         null: false           # "bajar_peso", "subir_peso", "mantener_peso",
                                                    # "nutrirse_bien", "mas_energia",
                                                    # "salud_cardiovascular", "mejorar_digestion",
                                                    # "comprar_por_mi_cuenta" (comodín, ver 3.3)
    t.string  :name,        null: false            # "Bajar de peso"
    t.text    :description
    t.string  :icon,        null: false            # nombre de icono lucide-react, ej. "Flame"
    t.string  :color,       null: false            # hex o token, ej. "#3d7ea3"
    t.integer :position,    null: false, default: 0
    t.boolean :active,      null: false, default: true
    t.timestamps
  end
  add_index :health_goals, :key, unique: true
  ```
- [X] Crear tabla puente `product_health_goals` (muchos a muchos, un producto puede servir a varios objetivos):
  ```ruby
  create_table :product_health_goals do |t|
    t.references :product, null: false, foreign_key: true
    t.references :health_goal, null: false, foreign_key: true
    t.timestamps
  end
  add_index :product_health_goals, [:product_id, :health_goal_id], unique: true
  ```
- [X] Modelo `HealthGoal`:
  - `has_many :product_health_goals, dependent: :destroy`
  - `has_many :products, through: :product_health_goals`
  - `scope :active, -> { where(active: true) }`
  - `scope :ordered, -> { order(:position, :name) }`
- [X] Modelo `Product`: agregar `has_many :product_health_goals, dependent: :destroy` y `has_many :health_goals, through: :product_health_goals`.
- [X] Seed inicial de `health_goals` (7 objetivos + "comprar por mi cuenta") en `db/seeds.rb`, con icono/color por defecto editables luego desde admin.
- [X] **Nota de escalabilidad (combos)**: para "agrupar por combos" (idea #7) el MVP resuelve la agrupación por `health_goal` (filtrar catálogo por objetivo). Un `ProductBundle` real (precio de combo, empaquetado como unidad de compra) es una entidad nueva con impacto en carrito/checkout — **se deja fuera de esta fase y se propone como Fase 4**, para no acoplar el checkout actual. A confirmar con el owner si se necesita antes.

### 2.2 Blueprints

- [X] `HealthGoalBlueprint`: `id, key, name, description, icon, color, position`.
- [X] `ProductBlueprint`: agregar `flavor` y `health_goals` (array de `HealthGoalBlueprint` resumido: `id, key, name, icon, color`).

### 2.3 Endpoints (públicos/autenticados)

- [X] `GET /api/v1/health_goals` → lista de objetivos activos, ordenados por `position`. Reutilizable por el selector rápido del marketplace y por el formulario admin de productos (para elegir tags).
- [X] `GET /api/v1/products?health_goal_key=bajar_peso` → extender `Products::ListForUser` para aceptar filtro opcional por objetivo (join con `product_health_goals`).

---

## 3. Sub-fase 3.2 — Admin: gestión de objetivos de salud

### 3.1 Backend

- [X] Namespace `Api::V1::Admin::HealthGoalsController` (CRUD completo), con `authorize_admin!`.
- [X] Interactors `Admin::HealthGoals::{List,Create,Update,Destroy}`.
  - `Destroy` es soft-delete (`active = false`), igual que productos — evita romper productos ya taggeados.
  - `List` acepta `?active=` (igual que `Admin::Products::List`).
- [X] Extender `Admin::Products::{Create,Update}` para aceptar `health_goal_ids: []` y sincronizar `product_health_goals`.
- [X] Documentar en `docs/endpoints/api-v1-admin-health-goals.md` al implementar.

### 3.2 Frontend

- [X] Página `/admin/health-goals`: tabla + formulario crear/editar con:
  - [X] selector de icono (lista curada de iconos lucide-react: `TrendingDown`, `TrendingUp`, `Scale`, `Apple`, `Zap`, `Heart`, `Activity`, `ShoppingBag`, `Flame`, `Sparkles` — `lib/constants/healthGoalOptions.ts`).
  - [X] selector de color (paleta de 8 swatches derivados de `docs/design/color-tokens.md`, no color picker libre).
  - [X] campo `position` (orden de aparición en el CTA rápido).
- [X] En `/admin/products/new` y `/admin/products/[id]/edit`: selector múltiple de objetivos de salud (`components/admin/HealthGoalCheckboxGroup.tsx`, pills clicables con icono+color, solo objetivos activos) y campo `flavor` (texto libre).
- [X] Componentes reutilizables: `lib/constants/healthGoalOptions.ts` (iconos/colores curados) + `HealthGoalCheckboxGroup` — se optó por botones/pills en vez de un `<select>` estilizado, para poder mostrar icono y color de cada objetivo directamente en el selector.

---

## 4. Sub-fase 3.3 — Marketplace: CTA rápido "¿Qué quieres?"

Resuelve las ideas #1 y #6 directamente: minimizar clics entre "entro a la app" y "compro lo que necesito".

### 4.1 Frontend

- [ ] Componente `HealthGoalQuickSelector` en `components/marketplace/`, mostrado **arriba del catálogo** en `/marketplace`, antes de cualquier otro contenido:
  - Tarjetas grandes con icono + color por objetivo (viene de `GET /api/v1/health_goals`).
  - Última opción siempre: **"Comprar por mi cuenta"** → limpia el filtro y muestra el catálogo completo (objetivo comodín `comprar_por_mi_cuenta`, no requiere lógica especial en backend, solo omite el filtro).
  - Al seleccionar un objetivo: navega a `/marketplace?health_goal=bajar_peso` (o filtra client-side si el catálogo ya está cargado) y hace scroll directo a la grilla de productos filtrada.
- [ ] El filtro seleccionado debe quedar visible (chip removible tipo "Bajar de peso ✕") para que el usuario no se sienta atrapado.
- [ ] Mantener el filtro también en la barra de búsqueda/otros filtros existentes (categoría) — deben poder combinarse.

### 4.2 UX (no negociable, viene de idea #1)

- [ ] Cero pasos intermedios entre seleccionar objetivo y ver productos comprables (sin loaders bloqueantes, sin modales).
- [ ] Botón "Agregar al carrito" visible directamente en cada card del resultado filtrado (ya existe en `MarketplaceProductCard`, solo reutilizar).

---

## 5. Sub-fase 3.4 — Confianza: descargos de responsabilidad + email de pedido

### 5.1 Descargos de responsabilidad (idea #5)

**Backend**
- [X] Migración: agregar `disclaimer` (`text`, nullable) a `products` — advertencia específica por producto (opcional, si vacío se usa el genérico).
- [X] Migración: agregar `medical_disclaimer_accepted_at` (`datetime`, nullable) a `purchases` — evidencia de que el usuario confirmó el aviso antes de pagar.
- [X] `Marketplace::Orders::Prepare` persiste la aceptación (`purchases.medical_disclaimer_accepted_at`) cuando llega `medical_disclaimer_accepted: true`.
  - **Desviación deliberada**: NO se rechaza con 422 todavía si falta — el endpoint ya está en producción con checkout funcionando; endurecerlo antes de que el frontend enviara el campo habría roto el checkout en vivo. Se hará obligatorio en un PR de seguimiento una vez confirmado que el frontend ya lo envía siempre.
  - **Nota de UX**: a pedido del owner, el checkbox en frontend viene marcado por defecto (`checked`) para no exigir un clic extra — reduce el valor de "consentimiento explícito" pero mantiene el aviso visible y el registro de aceptación.

**Frontend**
- [X] Componente `MedicalDisclaimer` reutilizable (`components/ui/medical-disclaimer/`) con el texto estándar, mostrado en:
  - [ ] Pie de página global (footer) — **pendiente**: el proyecto todavía no tiene un componente `Footer`/layout de pie de página; agregarlo es un cambio más grande que el alcance de este sprint. Queda para cuando se construya el footer.
  - [X] Detalle de producto (`/marketplace/[id]`), usando `product.disclaimer` si existe o el texto genérico.
  - [ ] Detalle de receta (`/recetas/[id]`) — llega con el módulo de recetas en sub-fase 3.5 (aún no implementado).
  - [X] Checkout: checkbox junto al botón de pago (marcado por defecto, ver nota de UX arriba).

### 5.2 Email de confirmación de pedido (idea #10)

**Backend**
- [X] Crear `OrderMailer < ApplicationMailer` con método `confirmation(order)`:
  - Destinatario: `order.purchase.user.email`.
  - `bcc`: `ENV["ADMIN_NOTIFICATION_EMAIL"]` (copia al admin, sin exponerlo al cliente).
  - Cuerpo: número de compra, fecha, items comprados (nombre, cantidad, precio), subtotal/impuestos/envío/total, dirección de envío, fecha estimada de entrega.
- [X] Vista `app/views/order_mailer/confirmation.html.erb` (+ `.text.erb` como fallback).
- [X] Disparo: al final de `Marketplace::Orders::Complete`, **justo después** (no dentro) de la transacción de éxito, se encola `OrderMailer.confirmation(purchase).deliver_later` (usa `solid_queue`, ya instalado — alineado con "Background Jobs" del `CLAUDE.md`).
  - **Ajuste sobre la spec original**: se dispara después del `commit`, no dentro de la transacción — evita acoplar un side-effect externo (aunque sea solo encolar) a una transacción de DB que podría hacer rollback por otra razón.
- [X] **Decisión pendiente a confirmar con el owner**: proveedor SMTP/API de envío (ej. Resend, Postmark, SMTP de Supabase/otro). Se requiere `ENV` nuevo: `SMTP_*` o `RESEND_API_KEY`, y `ADMIN_NOTIFICATION_EMAIL`. No se debe improvisar un proveedor sin confirmarlo, por la regla de `general-rules.md` de justificar y confirmar decisiones fuera del stack ya definido.
- [X] Manejar fallos de envío sin romper el flujo de compra (el pedido se confirma igual aunque el email falle; loggear el error).

---

## 6. Sub-fase 3.5 — Módulo de Recetas y Preparación

Resuelve las ideas #3 y #4.

### 6.1 Modelo de datos

- [X] Tabla `recipes`:
  ```ruby
  create_table :recipes do |t|
    t.string  :title,          null: false
    t.string  :slug,           null: false
    t.text    :description
    t.integer :servings,       default: 1
    t.integer :prep_time_minutes
    t.integer :difficulty,     default: 0, null: false   # enum: facil, media, dificil
    t.jsonb   :instructions,   default: [], null: false   # array de pasos ordenados
    t.string  :image_url
    t.boolean :active,         default: true, null: false
    t.timestamps
  end
  add_index :recipes, :slug, unique: true
  ```
- [X] Tabla puente `recipe_health_goals` (una receta puede servir a varios objetivos: "para bajar de peso" y "para más energía").
- [X] Tabla `recipe_ingredients` — **decisión de diseño**: en vez de columnas fijas tipo `water_amount`/`ice_amount`/`berries` en `recipes` (rígido, no escala a otros productos/ingredientes), se modela como líneas de ingrediente:
  ```ruby
  create_table :recipe_ingredients do |t|
    t.references :recipe, null: false, foreign_key: true
    t.references :product, foreign_key: true          # nullable: puede ser un ingrediente genérico
    t.string  :generic_name                            # ej. "Agua", "Hielo", "Frutos rojos" cuando no hay product_id
    t.string  :quantity, null: false                   # ej. "2 cucharadas", "250 ml", "1 taza"
    t.boolean :is_optional, default: false, null: false # ej. frutos rojos = true
    t.integer :position, default: 0, null: false
    t.timestamps
  end
  ```
  - Justificación: así "cuántas cucharadas de producto X", "cuánta agua", "cuánto hielo" y "frutos rojos (opcional)" son todas filas de la misma tabla, sin campos especiales por ingrediente. Cubre cualquier receta futura sin migraciones nuevas.
- [X] Modelo `Recipe`: `has_many :recipe_ingredients, dependent: :destroy`; `has_many :products, through: :recipe_ingredients`; `has_many :recipe_health_goals, dependent: :destroy`; `has_many :health_goals, through: :recipe_health_goals`; enum `difficulty`.

### 6.2 Backend — Endpoints

- [X] `GET /api/v1/recipes` — catálogo público/autenticado, filtros: `health_goal_key`, `difficulty`, `max_prep_time`.
  - Extra sobre la spec: también acepta `product_id`, usado por "Recetas con este producto" (ver 6.3).
- [X] `GET /api/v1/recipes/:slug` — detalle con ingredientes ordenados y flag `is_optional`.
- [X] `GET /api/v1/recipes/for_me` (auth requerida) — interactor `Recipes::ListForUser`:
  - Obtiene `product_id`s distintos de `purchase_items` confirmados del usuario (vía `Purchase.status: confirmed`).
  - Busca recetas cuyos `recipe_ingredients.product_id` estén en ese set, ordenadas por cantidad de ingredientes que el usuario ya tiene comprados (más coincidencias primero).
  - Si el usuario no tiene compras aún, devuelve fallback: recetas destacadas/genéricas (mismo criterio que el catálogo público, sin fallar).
- [X] Admin CRUD `Api::V1::Admin::RecipesController` + interactors `Admin::Recipes::*` (incluye gestión anidada de `recipe_ingredients`; `update` reemplaza la lista completa en vez de diffear por id).
- [X] Blueprints: `RecipeBlueprint` (vista `:default` resumida para listado, vista `:detail` con ingredientes completos e instrucciones, vista `:admin` que además agrega `active`/timestamps), `RecipeIngredientBlueprint`.
- Documentado en [`api-v1-recipes.md`](../endpoints/api-v1-recipes.md) y [`api-v1-admin-recipes.md`](../endpoints/api-v1-admin-recipes.md).

### 6.3 Frontend

- [X] Reemplazar el stub estático de `/recetas` (actualmente datos hardcodeados) por datos reales vía `lib/services/recipes.ts`.
- [X] Sección **"Recetas para ti"** al tope de `/recetas` cuando el usuario está autenticado y `for_me` devuelve resultados — refuerza directamente la idea #4.
- [X] Filtros existentes en la UI (tiempo, económicas, alta proteína...) se mapean a `health_goal_key`/`difficulty`/tiempo reales en vez de badges decorativos.
  - Los filtros decorativos originales ("Alta proteína", "Antiinflamatorias") no correspondían a ningún objetivo de salud real seedeado, así que se reemplazaron por chips de objetivo de salud real + dificultad + tiempo máximo (15/30 min), en vez de intentar mapear etiquetas inventadas a datos que no existen.
- [X] Página `/recetas/[slug]`: instrucciones paso a paso, lista de ingredientes marcando claramente los opcionales ("Frutos rojos — opcional"), y `MedicalDisclaimer` (ver 3.4) cuando la receta usa productos de suplementación.
  - El colapsado de instrucciones en móvil (visto rápido vs. completo) llega con la sub-fase 3.6 (`Collapsible`) — por ahora se muestran completas.
- [X] Desde `/marketplace/[id]` (detalle de producto), sección "Recetas con este producto" (recetas donde aparece ese `product_id` en `recipe_ingredients`) — cierra el círculo compra→preparación.
- **Extra sobre la spec**: admin CRUD de recetas en `/admin/recipes` (list + new + edit) — el backend ya expone el CRUD pero la spec no listaba una UI para usarlo; sin ella no había forma de crear recetas fuera de la consola de Rails (mismo criterio que se siguió con `/admin/health-goals` en la sub-fase 3.2).

---

## 7. Sub-fase 3.6 — Contenido progresivo ("para los que les gusta leer")

Resuelve la idea #2, complementa la #1 (rapidez para quien no quiere leer).

- [ ] Nuevo componente `components/ui/Collapsible` (o `Accordion`) — no existe aún en el design system (confirmado en `CLAUDE.md` frontend, sección "Not yet implemented").
- [ ] Regla de UX transversal: toda pantalla educativa/de producto muestra por defecto **solo lo esencial** (nombre, descripción corta, precio/CTA) y oculta detalle extendido detrás de un toggle "Ver información completa" / "Aprende más":
  - Detalle de producto: agregar `products.long_description` (`text`, nullable) separado del `description` corto ya usado en las cards. El corto sigue siendo obligatorio y visible siempre; el largo es opcional y va dentro del collapsible.
  - Detalle de receta: instrucciones completas colapsadas por defecto en vista rápida (móvil), expandidas en desktop si hay espacio.
  - `/habitos` (blog educativo, hoy stub): cada artículo muestra resumen + CTA "Leer artículo completo".
- [ ] No aplicar este patrón al flujo de compra en sí (carrito, checkout) — ahí la prioridad es velocidad, no lectura.

---

## 8. Sub-fase 3.7 — Dashboard dinámico por uso

Resuelve la idea #11.

### 8.1 Backend

- [ ] Tabla `user_feature_usages`:
  ```ruby
  create_table :user_feature_usages do |t|
    t.references :user, null: false, foreign_key: true
    t.string   :feature_key, null: false   # "marketplace", "mi-plan", "seguimiento", "coach-ia", "recetas", "habitos", "retos"
    t.datetime :last_used_at, null: false
    t.integer  :use_count, default: 0, null: false
    t.timestamps
  end
  add_index :user_feature_usages, [:user_id, :feature_key], unique: true
  ```
- [ ] Interactor `Users::TrackFeatureUsage.call(user:, feature_key:)` — upsert atómico (`find_or_create_by` + incrementos), sin bloquear la respuesta (debe ser una operación barata).
- [ ] Endpoint `POST /api/v1/users/track_usage` con body `{ feature_key: "marketplace" }` — autenticado, sin lógica de negocio compleja, solo delega al interactor.
- [ ] `GET /api/v1/users/me` — extender `UserBlueprint` para incluir `feature_usages: [{feature_key, last_used_at}]`, evitando una llamada extra en cada carga del dashboard.

### 8.2 Frontend

- [ ] En cada página relevante (`/marketplace`, `/mi-plan`, `/seguimiento`, `/coach-ia`, `/recetas`, `/habitos`, `/retos`), disparar en `useEffect` (fire-and-forget, sin bloquear render) una llamada a `track_usage` con su `feature_key`.
- [ ] En `/dashboard`, la sección "Acceso Rápido" (hoy con orden fijo: Mi Plan, Marketplace, Seguimiento, Coach IA) debe ordenarse por `last_used_at` descendente usando los datos de `feature_usages` del usuario actual; features nunca usadas van al final en su orden actual (fallback estable, no aleatorio).
- [ ] Persistir el orden calculado en memoria/estado de la página (no hace falta cachear en localStorage; la fuente de verdad es el backend).

---

## 8bis. Sub-fase 3.8 — Búsqueda de texto (marketplace y otras páginas)

Resuelve la idea #12. Spec técnica completa (decisión de gema, extensiones de Postgres, configuración de acentos/similitud, checklist backend/frontend) en el documento dedicado [`busqueda-full-text.md`](./busqueda-full-text.md) — no se repite aquí para evitar que las dos versiones se desincronicen.

Resumen ejecutivo:

- Gema `pg_search` (propuesta por el owner) sobre Postgres nativo, combinando `tsearch` (con una configuración `spanish_unaccent` para ignorar tildes) + `trigram` (`pg_trgm`, tolerancia a errores de tipeo) — evita depender de un motor de búsqueda externo (Elasticsearch/Meilisearch/Algolia) que sería sobre-ingeniería para el volumen actual.
- Cierra el hueco más importante detectado: `GET /api/v1/products` (marketplace público) hoy **no tiene ningún filtro de búsqueda en backend** — todo el filtrado ocurre en el navegador sobre la lista completa ya cargada.
- El mismo patrón (concern `Searchable` + `pg_search_scope`) se reutiliza en `Admin::Products::List` (reemplazando el `ILIKE` actual, que no maneja tildes), `Admin::Orders::List`, y debe incluirse desde el día uno en el módulo de Recetas (sub-fase 3.5) para no repetir la misma deuda técnica en una funcionalidad nueva.

---

## 9. Orden de implementación recomendado (sprints)

1. **Sprint 1 — Fundamentos** (3.1 + mitad de 3.4): `flavor`, `health_goals`, `product_health_goals`, `disclaimer` en productos, `medical_disclaimer_accepted_at`, seed de objetivos. Solo backend, bajo riesgo, habilita todo lo demás.
2. **Sprint 2 — Confianza y notificación** (resto de 3.4): `MedicalDisclaimer` en frontend + checkbox en checkout, `OrderMailer` (requiere decisión de proveedor de email — confirmar con owner antes de este sprint).
3. **Sprint 3 — Admin de objetivos** (3.2): CRUD `/admin/health-goals`, asignación de objetivos y sabor en el formulario de producto.
4. **Sprint 4 — Marketplace inteligente** (3.3): `HealthGoalQuickSelector`, filtro por objetivo end-to-end.
5. **Sprint 5 — Recetas** (3.5): modelo completo + endpoints + `/recetas` real + "Recetas para ti".
6. **Sprint 6 — Contenido progresivo** (3.6): componente `Collapsible`, `long_description`, aplicarlo en producto/receta/hábitos.
7. **Sprint 7 — Dashboard dinámico** (3.7): tracking de uso + reordenamiento de tarjetas.
8. **Sprint 8 — Búsqueda de texto** (3.8, detalle en `busqueda-full-text.md`): extensiones Postgres (`pg_trgm`, `unaccent`) + configuración `spanish_unaccent`, concern `Searchable`, aplicarlo a `Product` (ya con `flavor` del Sprint 1) y conectar `/marketplace` + `/admin/products` a búsqueda real en backend. Puede adelantarse antes del Sprint 5 si el catálogo empieza a crecer y el filtrado client-side actual se vuelve notoriamente lento — no tiene dependencias duras con los demás sprints salvo reutilizar `Product` ya con `flavor`.

Cada sprint cierra con: migraciones aplicadas, endpoints documentados en `docs/endpoints/`, `docs/schema.rb` del frontend actualizado, y este documento con los `[ ]` marcados como `[X]`.

---

## 10. Decisiones a confirmar con el owner antes de implementar

- [X] Proveedor de envío de email transaccional — resuelto: Resend (gem `resend` + `RESEND_API_KEY`, ver `config/application.rb`).
- [ ] Si "combos por objetivo" (idea #7) necesita precio de paquete real (`ProductBundle`) en esta fase o si el filtro por `health_goal` es suficiente por ahora (recomendación: dejarlo para Fase 4).
- [X] Lista definitiva de objetivos de salud — resuelto: 9 seedeados en `db/seeds.rb` (7 propuestos + "Snacks sanos" + "Comprar por mi cuenta"), con icono/color reales.
- [ ] Confirmar que Supabase permite crear la `TEXT SEARCH CONFIGURATION spanish_unaccent` y las extensiones `pg_trgm`/`unaccent` en el schema `extensions` con el rol que usa Rails en producción (ver `busqueda-full-text.md` sección 3) — validar en un entorno de staging antes del Sprint 8.
