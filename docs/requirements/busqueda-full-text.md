# Búsqueda de Texto (Full-Text Search) — pg_search

## 1. Contexto y alcance

`marketplace_sdd.md` (sección 4.1) ya listaba "Búsqueda por texto" como requisito del catálogo, pero nunca se especificó cómo. Hoy la búsqueda existe en varios lugares del frontend, pero **de forma inconsistente y sin soporte real de backend**:

| Página | Estado actual | Problema |
|---|---|---|
| `/marketplace` (catálogo público) | 100% client-side: `product.name.toLowerCase().includes(searchTerm.toLowerCase())` sobre el array ya cargado | `GET /api/v1/products` no acepta ningún parámetro de búsqueda; no escala; no tolera tildes distintas ni errores de tipeo |
| `/admin/products` | Filtro client-side sobre la lista completa ya cargada, aunque el backend **sí** tiene `search` (`Admin::Products::List`, `ILIKE`) | El `ILIKE` de Postgres no es insensible a tildes (`"nutricion"` no encuentra `"Nutrición"`) ni tolera errores de tipeo |
| `/admin/users` | Filtro client-side (email/nombre) | Sin backend, mismo problema de escala |
| `/recetas` (stub, Fase 3.5) | Input "Buscar recetas..." sin lógica | Módulo aún no implementado — riesgo de repetir la misma deuda si no se define el patrón antes |

Este documento define un único patrón de búsqueda, reutilizable en todas las páginas actuales y futuras que necesiten un buscador (marketplace, admin de productos/órdenes/usuarios, recetas, hábitos), en vez de que cada pantalla invente su propia solución.

---

## 2. Decisión de gema

El owner propuso `pg_search`. Se evaluaron alternativas explícitamente por el requisito de tolerar tildes y texto similar:

| Opción | A favor | En contra | Veredicto |
|---|---|---|---|
| **`pg_search`** (sobre Postgres nativo) | Ya estamos en Postgres (Supabase), cero infraestructura nueva; scopes de ActiveRecord idiomáticos; combina búsqueda por palabras (`tsearch`) y por similitud de caracteres (`trigram`) | Requiere configurar bien la búsqueda de texto para que ignore tildes (no viene gratis) | ✅ **Elegida** |
| `ransack` | Útil para filtros admin tipo campo=valor | No hace full-text ni tolera tildes/errores — no resuelve el problema de fondo | ❌ Insuficiente por sí sola |
| ILIKE manual (lo que ya existe en `Admin::Products::List`) | Simple, sin gemas | No tolera tildes ni errores de tipeo; sin ranking; se repite en cada interactor | ❌ Es justamente lo que estamos reemplazando |
| Elasticsearch / `searchkick` | Muy potente, ranking avanzado, escala a millones de registros | Requiere un servicio adicional (infraestructura, costo, mantenimiento) | ❌ Sobre-ingeniería para el volumen actual (MVP privado, un solo "seller") — reevaluar si QVITAL escala a SaaS multi-tenant con catálogos grandes |
| Meilisearch / Algolia (SaaS externo) | Excelente UX de búsqueda, muy rápido, tolera errores "out of the box" | Servicio externo de terceros, costo recurrente, expone el catálogo a un proveedor externo | ❌ No justificado para el volumen y alcance actual |

**Decisión: usar `pg_search`**, pero **no** en su modo más simple (un solo `tsearch` con diccionario `spanish`), porque eso *no* resuelve tildes ni errores de tipeo por sí solo. Se configura combinando:

- **`tsearch`** (búsqueda por palabras/lexemas, con stemming en español) — para que "proteína" encuentre "proteínas".
- **`unaccent`** aplicado a esa configuración de texto — para que "nutricion" encuentre "Nutrición".
- **`trigram`** (similitud de caracteres, extensión `pg_trgm`) — para tolerar errores de tipeo ("protina" → "proteína") y funcionar razonablemente incluso sin acentuar correctamente.

---

## 3. Infraestructura Postgres/Supabase requerida

### 3.1 Extensiones

Igual que las extensiones ya habilitadas en `db/schema.rb` (`pgcrypto`, `uuid-ossp`, etc.), instalar estas en el **schema `extensions`** (no en `public`), siguiendo el patrón ya usado por Supabase en este proyecto:

```ruby
# migración
enable_extension "extensions.pg_trgm"
enable_extension "extensions.unaccent"
```

### 3.2 Configuración de búsqueda de texto en español sin tildes

Postgres no tiene, por defecto, una configuración de texto que sea "español + sin tildes" a la vez. Hay que crearla una vez, vía migración con SQL crudo:

```ruby
class CreateSpanishUnaccentSearchConfig < ActiveRecord::Migration[8.0]
  def up
    execute <<~SQL
      CREATE TEXT SEARCH CONFIGURATION spanish_unaccent ( COPY = spanish );
      ALTER TEXT SEARCH CONFIGURATION spanish_unaccent
        ALTER MAPPING FOR hword, hword_part, word
        WITH extensions.unaccent, spanish_stem;
    SQL
  end

  def down
    execute "DROP TEXT SEARCH CONFIGURATION IF EXISTS spanish_unaccent;"
  end
end
```

**Nota Supabase (importante):** como `unaccent` se instala en el schema `extensions` (no en `public`), la función debe referenciarse calificada (`extensions.unaccent`) tal como arriba, o agregar `extensions` al `search_path` del rol que usa Rails. Sin esto, la migración falla con `function unaccent(text) does not exist`.

Con `spanish_unaccent` creada, se le indica a `pg_search` que use esa configuración en vez de `"spanish"` (ver sección 5).

---

## 4. Gemfile

```ruby
gem "pg_search"
```

Sin dependencias adicionales — usa las extensiones de Postgres ya instaladas en el punto 3.

---

## 5. Patrón de implementación (DRY, reutilizable por modelo)

En vez de repetir `pg_search_scope` con la misma configuración en cada modelo, crear un concern:

```ruby
# app/models/concerns/searchable.rb
module Searchable
  extend ActiveSupport::Concern

  class_methods do
    # columns: symbols de columnas propias a indexar
    # associated_against: hash opcional { asociacion: [:columnas] } (ej. category: [:name])
    def searchable_by(*columns, associated_against: {})
      include PgSearch::Model

      pg_search_scope :search_by_text,
        against: columns,
        associated_against: associated_against,
        using: {
          tsearch: { dictionary: "spanish_unaccent", prefix: true },
          trigram: { threshold: 0.2 }
        }
    end
  end
end
```

Uso en `Product` (agrega también `flavor`, ver Fase 3 — `fase3-personalizacion-objetivos-salud.md` sección 2.1):

```ruby
class Product < ApplicationRecord
  include Searchable
  searchable_by :name, :description, :sku, :flavor, associated_against: { category: [:name] }
  # ...
end
```

Este patrón es el que deben seguir también `Recipe` (Fase 3.5), y en el futuro cualquier modelo que necesite un buscador (`Purchase` para admin de órdenes, `User` para admin de usuarios).

---

## 6. Cambios concretos por endpoint (backend)

- [ ] **`GET /api/v1/products`** (`Products::ListForUser`) — **el gap más importante**: hoy el marketplace público no filtra en backend en absoluto. Agregar parámetro opcional `q`:
  ```ruby
  @products = @products.search_by_text(@query) if @query.present?
  ```
  Documentar el nuevo parámetro en `docs/endpoints/api-v1-products.md` al implementar.
- [ ] **`Admin::Products::List`** — reemplazar el bloque `ILIKE` actual (no maneja tildes/typos) por `Product.search_by_text(params[:search])`.
- [ ] **`Admin::Orders::List`** — agregar `search` sobre `purchase_number` y nombre del cliente vía el mismo patrón (`Purchase` incluye `Searchable`).
- [ ] **Admin de usuarios** — si se agrega un endpoint de listado con filtros en backend (hoy `/admin/users` filtra 100% client-side), aplicar el mismo patrón sobre `email`, `name`, `last_name`.
- [ ] **Recetas (Fase 3.5, `fase3-personalizacion-objetivos-salud.md`)** — implementar `Recipes::List` / `Recipes::ListForUser` ya con `searchable_by :title, :description` desde el primer día, para no repetir esta misma deuda técnica en un módulo nuevo.

---

## 7. Cambios en frontend

- [ ] Reemplazar el filtrado client-side (`.includes()`) en `/marketplace`, `/admin/products` y `/admin/users` por llamadas reales al backend con el parámetro `q`/`search`.
- [ ] Aplicar **debounce** (≈300ms) al input de búsqueda antes de disparar la petición, para no llamar al backend en cada tecla.
- [ ] Loading state mientras se busca — regla ya vigente en `CLAUDE.md`: *"Every async action must support loading, error and empty states"*.
- [ ] `/recetas`: conectar el input de búsqueda ya existente (hoy decorativo) al endpoint real cuando se implemente el módulo de recetas.

---

## 8. Alcance MVP vs. futuro

- **MVP (esta fase):** `tsearch` (con `spanish_unaccent`) + `trigram` combinados vía `pg_search`, sin ranking avanzado, sin sinónimos, sin autocompletado con sugerencias.
- **Futuro:** si el catálogo crece mucho (por ejemplo, al evolucionar a SaaS multi-tenant con miles de productos por tienda), reevaluar Elasticsearch/Meilisearch. Como el acceso a la búsqueda queda encapsulado en el concern `Searchable` y en el método `search_by_text`, migrar de motor no debería requerir tocar controllers ni frontend — solo la implementación interna del concern.

---

## 9. Checklist de implementación

### Backend

- [ ] Agregar gem `pg_search` al `Gemfile`.
- [ ] Migración: habilitar extensiones `extensions.pg_trgm` y `extensions.unaccent`.
- [ ] Migración: crear `TEXT SEARCH CONFIGURATION spanish_unaccent`.
- [ ] Crear `app/models/concerns/searchable.rb`.
- [ ] Aplicar `searchable_by` en `Product` (incluye `flavor` de Fase 3).
- [ ] Actualizar `Products::ListForUser` para aceptar `q` y usar `search_by_text`.
- [ ] Actualizar `Admin::Products::List` para usar `search_by_text` en vez de `ILIKE`.
- [ ] Actualizar `Admin::Orders::List` con búsqueda sobre `Purchase`.
- [ ] Documentar el parámetro `q`/`search` en cada `docs/endpoints/*.md` afectado.
- [ ] Copiar `db/schema.rb` actualizado a `qvital-frontend/docs/schema.rb` (regla de `CLAUDE.md`).

### Frontend

- [ ] `/marketplace`: reemplazar filtro client-side por llamada a `GET /api/v1/products?q=...` con debounce.
- [ ] `/admin/products`: usar el `search` que `adminProducts.ts` ya soporta (dejar de filtrar client-side sobre la lista completa).
- [ ] `/admin/users`: conectar a un endpoint real con `search` (hoy no existe backend para esto).
- [ ] `/recetas`: dejar preparado para conectar cuando se implemente el módulo (Fase 3.5).
