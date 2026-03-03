## Marketplace QVital – Specification‑Driven Development (SDD)

### 1. Contexto y objetivos

- **Proyecto origen**: Marketplace de Pitz (carrito, checkout, órdenes, integración de pagos).
- **Nuevo proyecto**: Marketplace QVital, implementado en otra app, reutilizando el diseño conceptual y de backoffice de Pitz pero con restricciones:
  - No habrá múltiples sellers/terceros: **todas las ventas las atiende un único “seller” interno (el admin de QVital)**.
  - **Créditos del marketplace no se incluyen** (no hay vouchers de crédito, líneas de crédito, scoring, etc.).
- **Objetivo del documento**: Definir de forma detallada el comportamiento funcional, modelos, endpoints y flujos para que backend y frontend de QVital puedan implementar el marketplace siguiendo un enfoque de Specification‑Driven Development (SDD), tomando como referencia la implementación actual en Pitz.

Este documento describe “qué debe hacer el sistema” sin código, para que las implementaciones en Rails (backend) y en el frontend de QVital se basen en una especificación compartida.

---

### 2. Alcance funcional del marketplace

#### 2.1. Actor principal

- **Cliente QVital**:
  - Navega catálogo de productos.
  - Agrega productos a carrito y ajusta cantidades.
  - Ingresa dirección de entrega y datos del receptor.
  - Selecciona fecha de entrega y método de pago.
  - Completa el pago (a través de un procesador externo tipo Mercado Pago / WOMPI u otro).
  - Consulta el estado de sus órdenes.

#### 2.2. Admin QVital

- Configura catálogo (productos disponibles en marketplace).
- Configura reglas generales (monto mínimo de compra, costos de envío, disponibilidad de fechas).
- Revisa órdenes generadas, sus estados y coordina despacho y facturación.

#### 2.3. Fuera de alcance

- Múltiples sellers/terceros: no se gestiona un marketplace multi‑seller; no hay reparto de órdenes por vendedor externo.
- Créditos de marketplace: no se manejan créditos, vouchers de crédito ni líneas de financiamiento asociadas al carrito.

---

### 3. Modelo de dominio (alto nivel)

#### 3.1. Entidades principales

- **Product** (producto del marketplace):
  - Representa un artículo vendible (ej. medicamento, insumo).
  - Atributos clave: identificador interno, SKU/EAN, nombre, descripción, categoría, subcategoría, marca, precio base, impuestos, stock disponible, flags de visibilidad en web.

- **Cart** (carrito):
  - Representa la intención de compra en curso de un usuario.
  - Atributos clave: id, user_id (opcional para anónimos), estado (`open`, `completed`), timestamps.
  - Relación: 1 carrito tiene N `CartItems`.

- **CartItem**:
  - Línea de producto dentro de un carrito.
  - Atributos clave: id, cart_id, product_id, cantidad, precio “snapshot” (precio unitario usado en el carrito), metadatos para reporting (códigos, categoría, etc.).

- **PurchaseIntent**:
  - Intención de compra previa al pago, usada para orquestar el checkout y enlazar con el proveedor de pagos.
  - Atributos clave: id, user/company_id, external_reference (UUID), status (`pending`, `completed`), total esperado.

- **Purchase**:
  - Representa la compra consolidada (pedido global) asociada a un intent.
  - Atributos clave: id, purchase_intent_id, total_amount, status (`pending`, `confirmed`, `cancelled`), número de compra (ej. PUR‑2026‑001), dirección de envío y datos de contacto.
  - Relación: 1 purchase tiene N `PurchaseItems`.

- **PurchaseItem**:
  - Detalle de cada producto en una compra.
  - Atributos clave: id, purchase_id, product_id, cantidad, precio unitario, subtotales, impuestos, metadatos de producto (categoría, marca, códigos).

- **Order** (orden logística QVital):
  - En Pitz, se generaba una orden por seller; en QVital **hay un único seller interno**, por lo que:
    - Para cada `Purchase`, se puede seguir usando el concepto de `Order` pero siempre con el mismo “seller” (admin QVital).
    - Alternativa: 1 purchase = 1 order. El documento asume esta simplificación para QVital.
  - Atributos clave: id, purchase_id, status (`pending`, `confirmed`, `shipped`, `delivered`, `cancelled`), montos y fechas relevantes.

- **OrderItem**:
  - Relación producto–orden (detalle logístico).
  - Atributos clave: id, order_id, product_id, cantidad, precio, información útil para logística.

- **Payment** (externo al alcance directo de este doc, pero relevante para el flujo):
  - Registro del proveedor de pagos (ej. preapproval/preference, estado de pago, referencias).
  - QVital debe almacenar al menos: external_reference, identificador de transacción del proveedor, status de pago, montos.

---

### 4. Flujo de usuario y pantallas

#### 4.1. Catálogo y detalle de producto

- **Listado de productos**:
  - Página de búsqueda/categorías con:
    - Búsqueda por texto.
    - Filtros por categoría, marca, disponibilidad.
    - Paginación o carga incremental.
  - Cada tarjeta de producto muestra: nombre, imagen, precio, breve descripción, botón “Agregar al carrito”.

- **Detalle de producto**:
  - Página con información completa: descripción ampliada, imágenes adicionales, composición, advertencias, stock, precio, posible “desde X al mes” si se quiere mostrar suscripciones o bundles en el futuro.
  - Permite seleccionar cantidad a agregar al carrito.

#### 4.2. Carrito

- **Página de carrito**:
  - Muestra todos los `CartItems` del carrito abierto:
    - Producto, cantidad, precio unitario, subtotal por línea.
  - Operaciones:
    - Cambiar cantidad de un item.
    - Eliminar un item.
    - Vaciar carrito.
  - Totales calculados y mostrados:
    - Subtotal (suma de cantidades × precio snapshot).
    - Impuestos (por ejemplo 16 % IVA, según configuración de QVital).
    - Costo de envío estimado.
    - Total final (subtotal + impuestos + envío).
  
#### 4.3. Checkout

- **Paso de dirección y entrega**:
  - Formulario con:
    - Dirección de envío: calle, número, barrio, ciudad, departamento, código postal, teléfono.
    - Opción “El receptor es otra persona”: cuando está activa se piden nombre y teléfono del receptor.
    - Costo de envío final (puede depender de la dirección, peso, etc.).

- **Resumen de pedido en checkout**:
  - Muestra el mismo resumen que el carrito, más:
    - Dirección de envío seleccionada.
    - Fecha de entrega.
  - Debe estar sincronizado con el payload que se enviará al backend en el endpoint de “prepare checkout”.

#### 4.4. Pago

- **Integración con proveedor de pagos** (inspirada en Mercado Pago / WOMPI, pero desacoplada):
  - Tras preparar el checkout, el backend devuelve:
    - Datos de `Purchase` y `PurchaseIntent`.
    - Un `external_reference` que se usará hacia el proveedor de pagos.
  - El frontend invoca otro endpoint backend para preparar el checkout con el proveedor de pagos:
    - El backend crea la preferencia o plan de pago y devuelve:
      - Identificadores del proveedor (ej. preference_id, init_point).
  - El frontend redirige o inicializa el SDK de pago con esos datos.

- **Pantallas de respuesta**:
  - **Éxito**:
    - Página con número de orden/compra, resumen del pedido, y mensaje de confirmación.
  - **Fallo**:
    - Página de error indicando que el pago no fue completado; acciones sugeridas: reintentar pago, volver al carrito.

#### 4.5. Historial y detalle de orden

- **Lista de órdenes**:
  - Para cada compra (`Purchase`/`Order`): número de compra, fecha, total, estado.

- **Detalle de orden**:
  - Muestra productos comprados, cantidades, precios, dirección de envío, fecha estimada de entrega, estados de la orden y eventos relevantes (por ejemplo, “pago confirmado”, “en preparación”, “despachado”).

---

### 5. Especificación de endpoints (backend QVital)

Los nombres se basan en los endpoints actuales del marketplace de Pitz, adaptados al escenario de un solo seller y sin créditos.

#### 5.1. Gestión de carrito

1) Obtener carrito abierto del usuario actual  
   - Método: GET  
   - Ruta: `/api/v1/marketplace/cart`  
   - Comportamiento:
     - Si existe un carrito `status = open` para el usuario, devolverlo con sus items.
     - Si no existe, devolver `null` o crear un carrito vacío (según decisión de diseño).

2) Agregar item al carrito  
   - Método: POST  
   - Ruta: `/api/v1/marketplace/cart/items`  
   - Request (conceptual):
     - `product_id`, `quantity`, precio actual (snapshot), y metadatos necesarios.
   - Comportamiento:
     - Si ya existe un item para el mismo `product_id` en el carrito abierto, sumar cantidades.
     - Validar stock e integridad de datos.

3) Actualizar cantidad de item  
   - Método: PATCH  
   - Ruta: `/api/v1/marketplace/cart/items/:id`  
   - Comportamiento:
     - Cambia la cantidad o precio snapshot del item.
     - Si cantidad llega a 0, se puede eliminar el item.

4) Eliminar item del carrito  
   - Método: DELETE  
   - Ruta: `/api/v1/marketplace/cart/items/:id`

5) Vaciar carrito  
   - Método: POST (o DELETE)  
   - Ruta: `/api/v1/marketplace/cart/clear`  
   - Comportamiento: elimina todos los `cart_items` de un carrito y deja el carrito en estado `open` o marca como `empty` según diseño.

#### 5.2. Preparar checkout (órdenes)

1) Preparar checkout completo  
   - Método: POST  
   - Ruta: `/api/v1/marketplace/orders/prepare`  
   - Campos principales (basado en Pitz, adaptado):
     - `cart_items`: lista de items (id de producto, cantidad, precio, metadatos).
     - `shipping_address`: dirección de envío (calle, ciudad, estado, zipCode, teléfono).
     - `recipient_info`: información del receptor (bandera “es diferente”, nombre, teléfono).
     - `selected_date`: fecha de entrega deseada.
     - `shipping_cost`: costo de envío calculado.
     - Opcional: `payment_method` (ej. “credit_card”, “spei”).  
     - No incluir campos de crédito (ni vouchers ni montos de crédito).
   - Backend QVital debe:
     - Validar parámetros y monto mínimo.
     - Sincronizar cliente (si aplica) con tabla de clientes interna.
     - Crear/actualizar `PurchaseIntent` y `Purchase` en transacción atómica.
     - Crear/actualizar `PurchaseItems` con los productos del carrito.
     - Crear/actualizar una única `Order` asociada al purchase (no dividir por sellers).
     - Devolver: `purchase_intent`, `purchase`, `external_reference`, `orders` (una o más, pero en QVital típicamente 1).

#### 5.3. Integración con proveedor de pagos

2) Preparar checkout con proveedor de pagos  
   - Método: POST  
   - Ruta: `/api/v1/marketplace/checkout/prepare`  
   - Campos:
     - Referencia externa generada en `/orders/prepare`.
     - Datos del pagador: nombre, email, teléfono, documento (según requerimientos del proveedor de pagos).
     - Información agregada del pedido (monto total, moneda).
   - Backend QVital debe:
     - Llamar a la API del proveedor de pagos (por ejemplo, para crear una preferencia de pago recurrente o única).
     - Guardar identificadores relevantes (preference_id, init_point, etc.).
     - Devolver al frontend los datos necesarios para redirigir o inicializar el widget de pago.

3) Webhook / callback de pago  
   - Método: POST  
   - Ruta: `/api/v1/marketplace/checkout/webhook` (o similar)  
   - Comportamiento:
     - Recibir notificaciones del proveedor de pagos sobre el estado del pago (aprobado, rechazado, pendiente).
     - Localizar `PurchaseIntent`/`Purchase` usando `external_reference`.
     - Actualizar registro de pagos internos.
     - Si el pago está aprobado:
       - Llamar internamente al endpoint `/api/v1/marketplace/orders/complete` o ejecutar la misma lógica.

#### 5.4. Completar orden

4) Completar orden  
   - Método: POST  
   - Ruta: `/api/v1/marketplace/orders/complete`  
   - Campos:
     - `purchase_id`: identificador de la compra.
     - `order_ids`: lista de órdenes a confirmar (en QVital, en general será una sola orden).
     - Opcional: `cart_id` usado durante el checkout para marcar el carrito como `completed`.
   - Comportamiento en backend:
     - Validar que el purchase pertenece a la compañía del usuario (multi‑tenant).
     - Verificar que las órdenes existen y pertenecen al purchase.
     - Actualizar:
       - `purchase_intent.status` a `completed` (si aplica).
       - `purchase.status` a `confirmed`.
       - `orders.status` a `confirmed`.
       - `carts.status` a `completed` y limpiar sus items (o mantener snapshot según diseño).

---

### 6. Modelos y tablas (vista conceptual)

> Nota: Los nombres concretos de campos/columnas pueden ajustarse en la implementación, pero esta sección marca la **intención de diseño**.
> Algunas tablas ya existen en el proyecto Qvital, se debe analizar y agregar los campos necesarios.
> manejar estados siempre en ingles, minusculas y en singular y como enum.

#### 6.1. Tabla `products` (Ya existe en el proyecto Qvital)

- Campos sugeridos:
  - id
  - sku / ean_code
  - name
  - description
  - category, subcategory, segment, brand
  - base_price, tax_percentage
  - is_active, show_in_web
  - stock_quantity (si se controla inventario en QVital)

#### 6.2. Tabla `carts`

- Campos sugeridos:
  - id
  - user_id (nullable para anónimos)
  - status (`open`, `completed`, `abandoned`)
  - created_at, updated_at

#### 6.3. Tabla `cart_items`

- Campos sugeridos:
  - id
  - cart_id (FK a carts)
  - product_id (FK a products)
  - quantity
  - price_snapshot (precio unitario al momento de añadir al carrito)
  - metadatos: descripción, categoría, marca, etc. según necesidad de reporting.

#### 6.4. Tabla `purchase_intents`

- Campos sugeridos:
  - id
  - user_id / company_id
  - external_reference (UUID)
  - status (`pending`, `completed`, `cancelled`)
  - total_amount
  - created_at, updated_at

#### 6.5. Tabla `purchases`

- Campos sugeridos:
  - id
  - purchase_intent_id (FK)
  - user_id / company_id
  - total_amount, subtotal_amount, tax_amount, shipping_cost
  - status (`pending`, `confirmed`, `cancelled`)
  - purchase_number (string legible para usuario)
  - shipping_address (puede ser JSON estructurado)
  - recipient_name, recipient_phone (si receptor es distinto)
  - created_at, updated_at

#### 6.6. Tabla `purchase_items`

- Campos sugeridos:
  - id
  - purchase_id (FK)
  - product_id
  - quantity
  - unit_price, line_subtotal, line_tax, line_total
  - metadatos de producto (categoría, marca, etc.) para snapshot.

#### 6.7. Tabla `orders`

- En Pitz, existía una tabla por seller; en QVital:
  - Se puede usar `orders` como tabla de órdenes logísticas internas, con un único seller lógico (el admin).
- Campos sugeridos:
  - id
  - purchase_id (FK)
  - status (`pending`, `confirmed`, `shipped`, `delivered`, `cancelled`)
  - total_amount
  - shipping_date_estimated, shipping_date_real
  - tracking_info (opcional)
  - created_at, updated_at

#### 6.8. Tabla `order_items`

- Campos sugeridos:
  - id
  - order_id (FK)
  - product_id
  - quantity
  - price (snapshot)
  - metadatos para logística.

#### 6.9. Tabla `payments` (u otra relacionada)

- Registra la relación con el proveedor de pagos (opcional en este SDD, pero recomendado):
  - id
  - purchase_id
  - external_reference
  - provider (ej. “mercado_pago”)
  - provider_payment_id / provider_preference_id
  - status (`pending`, `approved`, `rejected`, etc.)
  - amount, currency
  - raw_payload (JSON con respuesta del proveedor para auditoría).

---

### 7. Consideraciones específicas para QVital

1. **Un solo seller (admin)**  
   - No se deben exponer ni gestionar entidades de “sellers externos” ni separar órdenes por seller.
   - Los campos que en Pitz contenían `seller_id` pueden:
     - O bien fijarse siempre al id del admin interno, o
     - Eliminarse del modelo si no aportan valor.

2. **Sin créditos de marketplace**  
   - No incluir:
     - Campos de crédito a usar en el carrito.
     - Estados relacionados a solicitudes de crédito.
     - Tablas específicas de créditos de marketplace.
   - El flujo de pago debe asumirse siempre como pago directo (tarjeta, transferencia) o pago contra entrega si QVital así lo decide.

3. **Ninguna dependencia de Pitz**  
   - Aunque el diseño está inspirado en Pitz, las tablas y endpoints deben nombrarse de forma genérica para QVital, evitando conceptos  específicos a Pitz (como “pitz_orders”). en cambio usar prefijos para separar lo que es admin interno y lo que es del admin externo (usuario de la app)
   - Mantener el patrón: preparar checkout → integrar pago → completar orden.

4. **Idempotencia**  
   - Los endpoints `/orders/prepare` y `/orders/complete` deben ser idempotentes (si se llaman varias veces con los mismos datos, no duplican entidades, solo actualizan las existentes).

5. **Multi‑tenant (aun no se eplementa en el MVP de proyecto Qvital, pero se debe tener en cuenta para el futuro)**  
   - Si QVital es multi‑tenant (varias clínicas/empresas usando el mismo backend), los endpoints deben filtrar por `company_id` y aplicar RLS o equivalente.

---

### 8. Resumen de lo que debe gestionar el backend

- Persistencia y lógica de:
  - Carritos (`carts`, `cart_items`).
  - Intenciones de compra (`purchase_intents`).
  - Compras (`purchases`, `purchase_items`).
  - Órdenes logísticas (`orders`, `order_items`).
  - Integración con proveedor de pagos (creación de preferencias/planes, webhook de notificación, estados de pago).
- Endpoints REST para:
  - Gestión de carrito.
  - Preparación de checkout.
  - Preparación de pago con proveedor externo.
  - Completar órdenes tras pago exitoso.
- Lógica de negocio:
  - Validación de carrito (monto mínimo, stock, datos de envío).
  - Cálculo de totales (subtotal, impuestos, envío).
  - Manejo de estados de purchase/orden de forma consistente y atómica.

Este SDD debe servir como base para que el equipo backend de QVital implemente los modelos y endpoints necesarios, y para que el frontend pueda integrarse de forma clara y consistente con el comportamiento ya probado en el marketplace de Pitz, ajustado al contexto de un único seller y sin créditos. 
