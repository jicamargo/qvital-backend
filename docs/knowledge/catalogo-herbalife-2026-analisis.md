# Análisis del Catálogo Oficial Herbalife Colombia 2026

## 0. Fuente y metodología

- **Fuente**: `catalogo-herbalife-2026.pdf` (41 páginas, catálogo oficial impreso, "Válido para Colombia", HLF Colombia Ltda.).
- **Método**: extracción de texto completa del PDF (`pypdf`) + lectura íntegra, cruzada contra un export completo de la tabla `products` en producción (39 productos activos a la fecha de este análisis, 2026-08-22).
- **Objetivo**: identificar qué información del catálogo oficial sirve para (a) corregir/enriquecer datos que ya tenemos, y (b) agregar campos o funcionalidades nuevas al proyecto QVITAL.

Este documento es un **análisis**, no implementa nada — las acciones sugeridas al final quedan como checklist para decidir cuáles priorizar.

---

## 1. Estructura del catálogo oficial

El catálogo 2026 organiza los productos en **4 secciones**:

1. **Nutrición Básica** — Fórmula 1, PDM, Beta Heart, Fórmula 3, Barra Proteica, Crocante de Proteína, Nutri Soup, Bebida Herbal, Herbal Relax Infusion, Golden Beverage.
2. **Nutrición Específica** — Herbal Aloe Concentrado, Beverage Mix, Fibra Activa, Herbalifeline Plus, Complejo Multivitamínico, Xtra-Cal Advanced, Collagen Drink.
3. **Vida Activa** — N-R-G, Kickoff, CR7 Drive, Rebuild Strength.
4. **Nutrición Externa** — Gel Refrescante / Crema Manos y Cuerpo (Herbal Aloe), línea Herbalife SKIN (limpiador, tonificador, sérum, crema FPS30, mascarilla, exfoliante).

**Hallazgo #1 — nuestra taxonomía de categorías no coincide con la del catálogo.** En la app, las 4 secciones oficiales quedaron repartidas en categorías más granulares (`Proteína`, `Herbal Aloe`, `Bebida Herbal`, `Fórmula 1 - Batido Nutricional`, un catch-all `Nutrición Específica`, `Nutrición Externa`), y los 4 productos de **Vida Activa** (Kickoff, CR7 Drive, Rebuild Strength, N-R-G) terminaron mezclados dentro de `Nutrición Específica` junto con vitaminas, colágeno y fibra — productos con propósitos muy distintos. Ver sección 4.

---

## 2. Inventario completo del catálogo (39 SKUs) vs. base de datos

**Cobertura: 100%.** Todos los productos del catálogo oficial 2026 ya existen en la tabla `products`, con el mismo SKU. No falta ningún producto por crear. Solo hay diferencias menores de nombre:

| SKU | Nombre en catálogo 2026 | Nombre en BD actual | Nota |
|---|---|---|---|
| 0267 | Beta Glucanor | Beta Heart | Mismo SKU — verificar si "Beta Heart" es el nombre comercial vigente o quedó desactualizado |
| 3122 | Complejo Multivitamínico | Fórmula 2 - Complejo Multivitamínico | BD agrega el prefijo "Fórmula 2 -", coherente con la línea Fórmula 1/2/3 |
| 0020 | Xtra-Cal Advanced | Xtra Cal Advanced | Diferencia de guión, cosmética |
| 1134 | Naranja-Crema | Naranja Crema | Diferencia de guión, cosmética |

Precios sugeridos de venta al público (PVP, COP) tal como aparecen en el catálogo — útiles para contrastar contra el precio del nivel "Cliente" en `product_prices` y detectar desactualizaciones:

| Producto | PVP catálogo 2026 |
|---|---|
| Batido Nutricional Fórmula 1 (cualquier sabor) | $164.000 |
| Bebida de Proteína en Polvo (PDM) | $205.000 |
| Beta Glucanor / Beta Heart | $186.000 |
| Fórmula 3 - Alimento Proteínico | $122.000 |
| Barra Proteica | $119.000 |
| Crocante de Proteína | $65.000 |
| Fórmula 1 Nutri Soup | $119.000 |
| Bebida Herbal 102 g | $126.000 |
| Bebida Herbal 51 g | $213.000 |
| Herbal Relax Infusion | $227.000 |
| Golden Beverage | $145.000 |
| Herbal Aloe Concentrado | $166.000 |
| Beverage Mix | $140.000 |
| Fibra Activa | $135.000 |
| Herbalifeline Plus | $171.000 |
| Complejo Multivitamínico | $68.000 |
| Xtra-Cal Advanced | $69.000 |
| Collagen Drink | $194.000 |
| N-R-G | $97.000 |
| Kickoff | $105.000 |
| CR7 Drive | $167.000 |
| Rebuild Strength | $342.000 |
| Gel Refrescante Corporal | $46.000 |
| Crema Manos y Cuerpo | $46.000 |
| Limpiador Cítrico | $99.000 |
| Tonificador energizante de hierbas | $78.000 |
| Sérum reductor de líneas | $232.000 |
| Crema Humectante FPS30 | $173.000 |
| Mascarilla purificadora de arcilla | $86.000 |
| Exfoliante instantáneo con arándanos | $80.000 |

> Nota: estos son precios **de lista pública sugeridos**, no necesariamente iguales al precio "Cliente" de nuestra tabla `product_prices` (que viene de un Excel de precios de distribuidor). Vale la pena una comparación puntual si se sospecha que algún precio quedó desactualizado, pero no se hizo automáticamente en este análisis (son fuentes distintas con propósitos distintos).

---

## 3. Sabores — validación cruzada

El sabor que ya extrajimos por rake task (`fase3:backfill_health_goals`) para los 9 productos de Fórmula 1 coincide con el catálogo oficial casi exactamente (solo "Naranja-Crema" vs. "Naranja Crema", diferencia de guión sin impacto real). **No requiere corrección.**

El catálogo confirma además sabores en otras líneas que **hoy no están en el campo `flavor`** de la BD (quedaron en el nombre del producto, no separados):

| Producto | Sabor (según catálogo) | ¿Separado en `flavor` hoy? |
|---|---|---|
| Bebida de Proteína en Polvo (PDM) | Vainilla / Crema de Maní | Parcial — "Crema de Maní" está en el `name`, no en `flavor` |
| Fórmula 3 - Alimento Proteínico | Original / Frutos rojos | No — está en el `name` |
| Herbal Aloe Concentrado | Original / Mango / Mandarina | **Sí** (ya corregido en Sprint 3) |
| Bebida Herbal | Original / Limón / Frambuesa / Durazno / Chai | Parcial — solo "Chai" y "Durazno" están en `flavor` hoy |
| N-R-G | Original / Guaraná Tropical | No — está en el `name` |

**Acción sugerida**: extender el rake task de Sprint 3 (o uno nuevo) para poblar `flavor` en estos productos también, con la misma lógica de "extraer después del separador en el nombre" (aquí el separador no siempre es " - ", habría que revisar caso por caso).

---

## 4. Descargos de responsabilidad — texto oficial por tipo de producto

Este es el hallazgo más directamente accionable para `products.disclaimer` (Fase 3, hoy vacío en el 100% de los productos). El catálogo usa **4 textos legales distintos según el tipo de producto**, no uno solo:

### 4.1 Genérico (aparece en casi todas las páginas)

> "Los productos Herbalife no tienen el propósito de tratar, curar, ni prevenir enfermedad alguna y han sido formulados para su consumo por adultos. Revise su etiqueta antes de consumirlos."

Este es prácticamente el mismo mensaje (mismo espíritu, distinta redacción) que ya usamos como texto genérico en `MedicalDisclaimer` del frontend. **Sugerencia**: alinear nuestro texto genérico al oficial de Herbalife, ya que el 100% de nuestro catálogo es Herbalife.

### 4.2 Suplementos dietarios (vitaminas, minerales, fibra, omega-3, colágeno, cúrcuma…)

> "ESTE PRODUCTO ES UN SUPLEMENTO DIETARIO, NO ES UN MEDICAMENTO Y NO SUPLE UNA ALIMENTACIÓN EQUILIBRADA. NO CONSUMIR EN ESTADO DE EMBARAZO Y LACTANCIA. PUEDE CAUSAR HIPERSENSIBILIDAD."

Aplica a: Fibra Activa, Herbalifeline Plus, Complejo Multivitamínico, Xtra-Cal Advanced, Collagen Drink, Golden Beverage, Beta Heart — es decir, casi toda la categoría "Nutrición Específica".

### 4.3 Bebidas energizantes con cafeína (Kickoff)

> "Contenido elevado en cafeína (27mg/100ml). La Bebida Energizante no previene los efectos generados por el consumo de bebidas alcohólicas. No se recomienda el consumo de bebidas energizantes con bebidas alcohólicas. Este producto solo podrá ser comercializado, expendido y dirigido a población mayor de 14 años. Este producto no es recomendado para personas sensibles a la cafeína. Este producto no contribuye a la recuperación ni reemplaza líquidos o electrolitos perdidos durante el ejercicio físico."

Aplica solo a **Kickoff** (SKU 204K) — es el único con esta advertencia específica de edad mínima y alcohol.

### 4.4 Cuidado personal / piel (línea Herbalife SKIN + Herbal Aloe externo)

> "Herbalife recomienda realizar una prueba de parche en la piel antes de usar cualquier producto de cuidado personal. En caso de reacción adversa, suspenda el uso inmediatamente y consulte a su médico de ser necesario."

Aplica a los 8 productos de `Nutrición Externa`.

**Acción sugerida**: un rake task de backfill (mismo patrón que `fase3:backfill_health_goals`) que asigne `disclaimer` por categoría/producto usando estos 4 textos exactos, en vez de dejar que todos caigan en el genérico del frontend.

---

## 5. Instrucciones de preparación / dosis — insumo directo para el módulo de Recetas (Fase 3.5)

El catálogo trae "Modo de uso" con dosis exactas para varios productos — justo el tipo de contenido que la Fase 3.5 (`Recipe` / `RecipeIngredient`) necesita para "cuántas cucharadas, cuánta agua…":

| Producto | Modo de uso (textual del catálogo) |
|---|---|
| Herbal Aloe Concentrado | Adultos: 1-2 porciones al día, antes o después de las comidas. Agitar y mezclar **3 tapas (15 ml)** en **media taza de agua (120 ml)** |
| Fibra Activa | Mezclar **1 medida (7,4 g)** en **1 taza (240 ml) de agua** u otra bebida. Tomar 1-2 veces al día |
| Herbalifeline Plus | 1 cápsula blanda 2 veces al día, preferiblemente con las comidas |
| Complejo Multivitamínico | 1 tableta con cada comida principal (desayuno, almuerzo, cena) |
| Xtra-Cal Advanced | 1 tableta 3 veces al día con las comidas (3 tabletas/día total) |
| Golden Beverage | Mezclar el sobre en **120 ml de agua** |
| Fórmula 1 Nutri Soup | **3 cucharas (27 g)** mezcladas con **240 ml de bebida de soya o agua** |

Nutri Soup además trae una tabla comparativa útil (Fórmula 1 vs. Nutri Soup): 16 g / 169 kcal vs. 9 g proteína / 90 kcal — información nutricional real, no genérica.

**Acción sugerida**: cuando se implemente el módulo de Recetas (Sprint 5 del plan de Fase 3), usar estas instrucciones oficiales como semilla real en vez de datos inventados — le da credibilidad regulatoria al contenido (viene literalmente del fabricante).

---

## 6. Objetivos de salud — la asignación por categoría del rake task de Sprint 3 es demasiado gruesa

El rake task `fase3:backfill_health_goals` asignó objetivos **por categoría completa**. Cruzando esa asignación contra los beneficios reales que el catálogo declara por producto, aparecen varios desajustes concretos:

### 6.1 Error concreto a corregir: Herbal Relax Infusion

Quedó con el objetivo **"Aumentar mi energía"** (por estar en la categoría `Bebida Herbal`), pero el catálogo dice explícitamente lo contrario: *"Desconéctate y acompaña tus momentos de relajación... Sin adición de cafeína... para acompañar tus momentos de calma y descanso"*. Es un producto **relajante**, no energizante — asignarle "más energía" contradice su propio marketing oficial.

### 6.2 Categoría "Nutrición Específica" (13 productos, hoy todos con `mas_energia` + `salud_cardiovascular`)

| Producto | Objetivo real según catálogo | ¿Coincide con lo asignado? |
|---|---|---|
| Beta Heart | Colesterol / cardiovascular | ✅ `salud_cardiovascular` |
| Herbalifeline Plus | Omega-3 / riesgo cardiovascular | ✅ `salud_cardiovascular` |
| Kickoff | Energía / alerta mental (cafeína) | ✅ `mas_energia` |
| N-R-G (2 sabores) | Energía (cafeína/guaraná) | ✅ `mas_energia` |
| Fibra Activa | Fibra dietaria / función intestinal | ❌ debería ser `mejorar_digestion`, no energía/corazón |
| Xtra-Cal Advanced | Calcio / salud ósea | ❌ no encaja en ninguno de los dos — no existe un objetivo de "huesos" |
| Collagen Drink | Colágeno / piel / antioxidantes | ❌ no encaja — no existe un objetivo de "piel/belleza" |
| Golden Beverage | Cúrcuma / articulaciones / recuperación muscular | ❌ no encaja — no existe un objetivo de "articulaciones" |
| Complejo Multivitamínico | Vitaminas y minerales generales | ⚠️ más cercano a `nutrirse_bien` que a energía/corazón |
| NutriSoup | Sopa baja en calorías, control de porciones | ⚠️ más cercano a `bajar_peso` que a energía/corazón |
| CR7 Drive | Hidratación y glucógeno durante ejercicio | ⚠️ parcialmente energía, pero es específico de rendimiento deportivo |
| H24 Rebuild Strength | Recuperación muscular post-ejercicio | ⚠️ parcialmente energía, pero es específico de recuperación deportiva |

De 13 productos, solo 4 encajan bien con lo que ya se les asignó; 3 no encajan en ningún objetivo existente (huesos, piel, articulaciones); 3 encajarían mejor en objetivos *ya existentes* pero distintos a los que tienen (digestión, nutrición, bajar de peso); 2 son casos específicos de rendimiento deportivo que ningún objetivo actual cubre bien.

### 6.3 Objetivos de salud que el catálogo sugiere y hoy no existen

- **Salud ósea / articular** — Xtra-Cal Advanced, Golden Beverage.
- **Piel y belleza** — Collagen Drink, toda la línea Herbalife SKIN, Herbal Aloe (crema/gel externo).
- **Rendimiento y recuperación deportiva** — CR7 Drive, Rebuild Strength (distinto de "energía" genérica).
- **Relajación / descanso** — Herbal Relax Infusion (coincide con el "Reto Dormir mejor" que ya estaba en el PRD original de hábitos, `general-rules.md`).

---

## 7. Categorías huérfanas — limpieza de datos pendiente

La tabla `categories` tiene 4 registros con **0 productos**, resultado de reseeding repetido con nombres ligeramente distintos:

| id | name | products |
|---|---|---|
| 1 | Batido Nutricional | 0 (duplicado de id=9 "Fórmula 1 - Batido Nutricional", que sí tiene 9 productos) |
| 5 | Deporte y vida activa | 0 (duplicado singular de id=10) |
| 8 | Otros | 0 |
| 10 | Deportes y vida activa | 0 (los 4 productos de Vida Activa están en realidad en id=6 "Nutrición Específica") |

**Acción sugerida**: decidir entre (a) borrar las categorías huérfanas 1, 5 y 8 si no se van a usar, o (b) mover los 4 productos de Vida Activa (Kickoff, CR7 Drive, Rebuild Strength, N-R-G) a la categoría id=10 "Deportes y vida activa" para que coincida con la estructura real del catálogo oficial, y luego borrar la id=5 duplicada.

---

## 8. Otro contenido del catálogo (no urgente, pero útil a futuro)

- **25 años en Colombia, +38.000 distribuidores, patrocinio de Camila Osorio y Cristiano Ronaldo, Herbalife Family Foundation** — contenido de marca/confianza que podría alimentar una sección "Nosotros"/"Por qué Herbalife" en la landing pública, si se decide reforzar la narrativa de marca.
- **Consejo Científico de Herbalife** (Dr. David Heber, Susan Bowerman, etc.) — respaldo científico que podría citarse en el `MedicalDisclaimer` o en contenido educativo ("Aprende más") de la Fase 3.6, para reforzar confianza sin inventar reclamos.
- **Contenido nutricional estructurado** (contenido neto, porciones por envase, tamaño de porción, calorías/proteína por porción) — no existe hoy ningún campo para esto en `products`. Se podría modelar a futuro como columnas nuevas (`net_content`, `servings_per_container`, `serving_size`) si se quiere mostrar información nutricional real en el detalle de producto.

---

## 9. Checklist de acciones sugeridas (priorizado)

### Alta prioridad — bajo esfuerzo, alto valor

- [ ] Backfill de `products.disclaimer` con los 4 textos oficiales de la sección 4 (rake task nuevo, mismo patrón que `fase3:backfill_health_goals`).
- [ ] Corregir el objetivo de salud de Herbal Relax Infusion (quitar `mas_energia`, ya que contradice su propósito real).
- [ ] Revisar/afinar los 13 productos de "Nutrición Específica" uno por uno según la tabla de la sección 6.2, en vez de dejarlos todos con el mismo par de objetivos.

### Media prioridad

- [ ] Extender el backfill de `flavor` a PDM (Crema de Maní), Fórmula 3 (Frutos rojos), Bebida Herbal (Original/Limón/Frambuesa) y N-R-G (Guaraná Tropical) — hoy el sabor sigue metido en el `name`.
- [ ] Decidir si se crean nuevos objetivos de salud: salud ósea/articular, piel y belleza, rendimiento/recuperación deportiva, relajación/descanso.
- [ ] Limpiar categorías huérfanas (`Batido Nutricional` id=1, `Deporte y vida activa` id=5, `Otros` id=8) y mover los 4 productos de Vida Activa a la categoría "Deportes y vida activa" (id=10).
- [ ] Alinear el texto genérico de `MedicalDisclaimer` (frontend) más de cerca al texto oficial de Herbalife citado en la sección 4.1.

### Baja prioridad / a futuro

- [ ] Usar las instrucciones de uso de la sección 5 como semilla real para el módulo de Recetas (Fase 3.5) cuando se implemente.
- [ ] Evaluar modelar contenido nutricional estructurado (contenido neto, porciones, calorías/proteína) como columnas nuevas en `products`.
- [ ] Contenido de marca/confianza (25 años, respaldo científico) para reforzar el `MedicalDisclaimer`/páginas educativas de la Fase 3.6, sin inventar reclamos no verificados.
- [ ] Reconciliar el nombre "Beta Heart" (BD) vs. "Beta Glucanor" (catálogo, mismo SKU 0267) — confirmar cuál es el nombre comercial vigente.

---

## 10. Advertencia sobre uso de este contenido

Los textos de descargo de responsabilidad y los reclamos de beneficio citados aquí son **transcripción literal del catálogo oficial de Herbalife**, no interpretación propia — se recomienda usarlos tal cual (no parafrasear reclamos de salud), dado que este tipo de contenido suele estar regulado. Cualquier reclamo nuevo que no esté textualmente en el catálogo oficial no debería agregarse a la app sin confirmarlo primero con el owner.
