## Requerimientos – Imágenes de Recetas (Supabase Storage + Rails API)

Mismo patrón que `product-images-req.md` (imágenes de productos), aplicado a
`recipes`. Ver ese doc para el razonamiento arquitectónico completo — aquí
solo se documentan las decisiones específicas de recetas.

### 1. Backend (Rails)

- [X] `recipes.image_url` (ya existía, agregado en la sub-fase 3.5).
- [X] `recipes.image_path` — migración `20260903150000_add_image_path_to_recipes.rb`.
- [X] `POST/PATCH /api/v1/admin/recipes` aceptan `image_url` e `image_path` (`recipe_params` + `Admin::Recipes::{Create,Update}`).
- [X] `RecipeBlueprint` expone `image_url` en todas las vistas (público incluido) e `image_path` solo en `view: :admin` — igual que `products.image_path`, que tampoco es público.
- [ ] (Futuro) Limpieza del archivo en Storage al desactivar/eliminar una receta — mismo pendiente que productos.

### 2. Frontend

- [X] `lib/services/recipeImages.ts` — clon de `productImages.ts` (`uploadRecipeImage`), bucket `recipes`, mismas reglas de validación (JPG/PNG/WEBP, máx. 5MB).
- [X] `components/admin/RecipeForm.tsx` — reemplazado el campo de texto libre "URL de imagen" por selector de archivo + preview (`ProductMainImage`, reutilizado) + subida a Supabase antes de enviar el payload a Rails, igual que `app/admin/products/{new,[id]/edit}/page.tsx`. A diferencia de productos, en recetas la lógica vive dentro del componente compartido `RecipeForm` (usado por `new` y `[id]/edit`) en vez de duplicarse en cada página.
- [X] `AdminRecipe`/`AdminRecipePayload` (`lib/services/adminRecipes.ts`) incluyen `image_path`.
- [X] Consumo/renderizado ya existía: `RecipeCard` usa `ProductMarketplaceImage` con `recipe.image_url` desde la sub-fase 3.5.

### 3. Supabase Storage

- [X] Bucket `recipes` creado vía Storage Admin API (`rails runner` + `SUPABASE_SERVICE_ROLE_KEY`, no hay precedente de esto en migraciones ni CLI para `products` tampoco — se creó igual, sin trazabilidad en código para ese bucket).
  - público, `file_size_limit` 5MB, `allowed_mime_types` jpeg/png/webp.
- [X] **RLS policies en `storage.objects` — migración `20260903170000_add_authenticated_upload_policies_to_recipes_bucket.rb`.**
  Corrección 2026-09-03: la primera versión de este doc asumía que `products`
  tampoco tenía policies reales (el checklist de `product-images-req.md` §4.2
  seguía sin marcar) — resultó ser solo que el checklist no se había
  actualizado. `products` **sí** tiene 3 policies en `storage.objects`
  (`Allow authenticated uploads 1ifhysk_{0,1,2}`: SELECT/INSERT/UPDATE para
  el rol `authenticated`, filtradas por `bucket_id`), creadas manualmente en
  algún momento sin dejar rastro en migraciones. `recipes` no las tenía —
  causaba `403 "new row violates row-level security policy"` al subir una
  imagen desde el admin — y ahora tiene las 3 mismas policies, mismo criterio
  (`authenticated`, no específicamente `role = 'admin'`), vía migración (no
  ad-hoc). Las policies de `products` no se tocaron.

### 4. Estado

Shippeado 2026-09-03 en `feature/recipe-images` (ambos repos). Ver memoria
`recipes-nutrition-fields-project` para el contexto del resto del trabajo de
recetas.
