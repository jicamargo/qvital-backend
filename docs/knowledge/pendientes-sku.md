# Pendientes de SKU — Base de Conocimiento QVITAL

**Categoría:** Documento de control (no es contenido educativo)
**Fuente:** Cruce de los documentos de `docs/knowledge/` contra `table products.csv` (catálogo QVITAL, 47 productos activos al 2026-08-26).

Este documento tiene dos partes: (1) los 4 tomos de recetas "Mi Nutrición Favorita" (regla: nunca asumir sabor, todo lo ambiguo queda pendiente), y (2) los documentos de capacitaciones/escuelas (Sistemas, Nutrición General, Coaching) (regla distinta, confirmada por Jorge el 2026-08-26: cuando el producto no especifica sabor, se asigna el primer sabor por defecto — ver sección 2 — así que ahí solo quedan pendientes los casos de **identidad incierta**, no los de sabor sin especificar).

# Parte 1 — Recetas Mi Nutrición Favorita (Tomos 1-4)

Este documento junta todos los productos mencionados en las recetas de los 4 tomos que **no se pudieron cruzar con confianza contra un SKU del catálogo**, para que Jorge asigne el SKU correcto. Una vez asignado, hay que volver al/los documento(s) de receta indicado(s) (columna "Archivo") y reemplazar el `(SKU pendiente)` por `*<Nombre del catálogo>* (SKU XXXX)`.

## Reglas de equivalencia ya confirmadas por Jorge (2026-08-26) — aplicadas en los 4 documentos, ya NO están pendientes

| Mención en el libro | Equivalente confirmado |
|---|---|
| "Batido Nutricional Fórmula 1 sabor chocolate" | Fórmula 1 - Chocoavellana, SKU 0884 |
| "N-R-G" (sin calificativo) | NRG (Original), SKU 0102 — el N-R-G Guaraná Tropical (075K) solo se usa si el libro lo especifica explícitamente |
| "Relaxation Tea" | Herbal Relax Infusion - Menta 48 g., SKU 044K |
| "Fórmula 1 Nutri Soup" / "Nutri Soup" | NutriSoup, SKU 395K |
| "Herbal Aloe Concentrado sabor original" / "Aloe Original" / "Concentrado de Sábila Original" | Herbal Aloe Concentrado - Sábila, SKU 0006 |
| "Aloe de Mandarina" | Herbal Aloe Concentrado - Mandarina, SKU 2631 (ya se venía aplicando correctamente) |
| "Aloe de Mango" | Herbal Aloe Concentrado - Mango, SKU 1065 (ya se venía aplicando correctamente) |

Estas reglas ya se aplicaron y quedaron escritas en `recetas-mi-nutricion-favorita-tomo-1.md`, `-tomo-2.md` y `-tomo-4.md` (el Tomo 3 no tenía ninguna mención de estos casos). La nota de inconsistencia entre Tomo 1 y Tomo 4 sobre "sabor original" que existía en la versión anterior de este documento **quedó resuelta** — ambos tomos usan ahora SKU 0006 de forma consistente.

## Tabla de pendientes reales (lo que todavía falta)

Importante: las siguientes son menciones donde el libro **no especifica ningún sabor/nombre concreto** (deja la elección abierta al lector), o donde el nombre no tiene ningún candidato razonable en el catálogo — no aplican las reglas de equivalencia de arriba.

| Producto mencionado en la receta | Motivo | Archivo | Receta | Página |
|---|---|---|---|---|
| Batido Nutricional Fórmula 1 de tu sabor favorito | Receta no especifica sabor concreto (no dice "chocolate" ni ningún otro) | tomo-2 | Waffles (para el sirope) | 33 |
| Té Concentrado de Hierbas sabor limón (gramaje no especificado) | Catálogo tiene "Bebida Herbal - Limón" en 51g (0255) y 102g (0188); la receta no dice cuál | tomo-1 | Bebida de Poder Espumosa | 36 |
| Té Concentrado de Hierbas de tu preferencia (sabor no especificado) | Sin sabor especificado | tomo-1 | Té Energizante | 39 |
| Té Concentrado de Hierbas de tu sabor favorito | Sin sabor especificado | tomo-2 | Gelatina Fit | 14 |
| Té Concentrado de Hierbas del sabor de tu preferencia | Sin sabor especificado | tomo-4 | Coctel Herbalífico | 26 |
| Aloe Concentrate de tu sabor favorito | Sin sabor especificado (no dice "original") | tomo-2 | Gelatina Fit | 14 |
| Herbal Aloe Concentrate (sabor no especificado) | Sin sabor especificado (no dice "original") | tomo-2 | Té Berrylicious | 32 |
| Herbal Aloe Concentrado de tu sabor favorito | Sin sabor especificado (no dice "original") | tomo-3 | Limonada Power | 34 |
| Herbal Aloe Concentrado del sabor de tu preferencia | Sin sabor especificado (no dice "original") | tomo-4 | Coctel Herbalífico | 26 |
| Herbal Aloe Concentrado, el sabor de tu preferencia | Sin sabor especificado (no dice "original") | tomo-4 | Té Frutal Relajante | 41 |
| Collagen Beauty Drink | No coincide literal con "Collagen Drink" (SKU 3987) del catálogo — nombre distinto, no se asumió que sea el mismo producto | tomo-2 | Té Berrylicious | 32 |
| Collagen Beauty Drink | ídem | tomo-2 | Té Mega Citrus | 34 |
| Immunity Essentials | No hay ningún candidato en el catálogo bajo ese nombre | tomo-4 | Bebida Cítrica Immunity | 37 |

**Total: 13 menciones pendientes** (bajaron de 27 a 13 tras aplicar tus 5 reglas de equivalencia — quedan solo casos genéricos "sabor a elección" y 2 productos sin candidato claro: Collagen Beauty Drink e Immunity Essentials).

Nota: en `recetas-mi-nutricion-favorita-tomo-4.md` (Coctel Herbalífico) también hay "Beverage Mix" (SKU 093K) ya asignado sin ambigüedad — no confundir con estos pendientes.

# Parte 2 — Capacitaciones (Escuelas, Sistemas de Salud, Nutrición General, Coaching)

**Regla aplicada (confirmada por Jorge 2026-08-26):** a diferencia de las recetas, en estos documentos SÍ se asigna un SKU por defecto cuando el producto se menciona sin sabor específico:
- Fórmula 1 sin sabor → **Fórmula 1 - Cookies & Cream, SKU 0146** (regla explícita de Jorge, no es el sabor "Original" porque Fórmula 1 no tiene esa variante)
- Bebida Herbal / Té Herbal sin sabor → **Bebida Herbal - Original 102 g., SKU 0106**
- Herbal Aloe Concentrado sin sabor → **Herbal Aloe Concentrado - Sábila (Natural), SKU 0006**
- Fórmula 3 / Personalized Protein Powder sin más detalle → **Fórmula 3 - Alimento Proteínico en Polvo, SKU 0242**
- Bebida de Proteína en Polvo / Protein Drink Mix (PDM) sin más detalle → **Bebida de Proteína en Polvo - PDM, SKU 1122**
- Productos con una sola variante en el catálogo (Fibra Activa, Xtra-Cal, Herbalifeline, Collagen Drink, Barra con Proteína, H24 Rebuild Strength, Fórmula 2, NRG, etc.) → esa única variante, sin importar si el documento menciona o no un sabor/detalle adicional.

Estas reglas ya se aplicaron dentro de cada documento afectado (sección "Productos Herbalife mencionados" de cada uno). Lo que queda pendiente aquí son solo los casos donde el producto en sí **no se pudo identificar con certeza** (no es un problema de sabor, sino de qué producto es):

| Producto mencionado | Motivo | Archivo | Diapositiva |
|---|---|---|---|
| Línea NouriFusion | El catálogo actual de QVITAL no tiene una línea "NouriFusion" — tiene "Herbalife SKIN", que podría ser el sucesor/rebranding de esa línea, pero no se asumió que sean el mismo producto sin confirmación | `nutricion-general-las-proteinas.md` | 18 |
| "Fórmula 3 — Alimento Proteínico / Bebida de Proteína en Polvo (Personalized Protein Powder / Protein Drink Mix)" | El documento combina en un solo punto lo que podrían ser dos productos distintos del catálogo (Fórmula 3 SKU 0242 vs. PDM SKU 1122); se asignó 0242 como principal, pero no hay certeza de si alguna de las menciones (diap. 18, 21, 23, 24) se refiere en realidad al PDM | `sistema-inmune.md` | 18, 21, 23, 24 |
| Producto adicional en tono rosado (posible "Healthy Meal" o segunda variante del Batido Nutricional) | Identidad no confirmada, solo se identificó por color en una imagen poco legible | `nutricion-general-estilo-de-vida-saludable-dra-carbonell.md` | 22, 23 |
| "Producto de fibra + Aloe" (nombre exacto no confirmado) | Imagen ilegible; podría ser dos productos distintos (un producto de fibra/provitaminas y un producto de Aloe), no se pudo confirmar cuáles | `nutricion-general-por-que-las-dietas-no-funcionan.md` | 15 |

**Total: 4 casos de identidad incierta.** A diferencia de la Parte 1, estos no se resuelven asignando un sabor por defecto — se necesita que Jorge confirme cuál es el producto real (o revise la imagen original) antes de asignar un SKU.

Nota aparte (no requiere acción, ya documentada en su propio archivo): en `sistema-inmune.md` y `nutricion-general-estilo-de-vida-saludable-dra-carbonell.md`, el producto "N-R-G" aparece con la etiqueta parcialmente cortada/ilegible en una imagen, pero como el nombre "N-R-G" sí se lee con certeza en el texto de la diapositiva, se le asignó SKU 0102 igual (regla de N-R-G por defecto) — no se dejó pendiente.
