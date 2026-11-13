# Etapa 3 — Legal y privacidad (Ley 1581): diseño

_Aprobado en el chat el 2026-11-13. Corresponde a la etapa 3 de [`ruta-a-produccion.md`](ruta-a-produccion.md)._

## Objetivo

Que QVITAL pueda recibir datos de salud cumpliendo la Ley 1581 de 2012 y el Decreto 1377 de 2013. Para eso:

- la clienta autoriza de forma expresa y separada el uso de sus datos sensibles, y queda prueba con fecha y versión;
- puede leer las políticas, retirar su autorización y borrar su cuenta sola;
- los registros (logs) no guardan datos sensibles;
- ninguna clienta puede ver los datos de otra;
- los endpoints públicos tienen límite de peticiones.

## Decisiones de Jorge

- **Responsable del tratamiento:** queda como `[PENDIENTE: responsable]`. Debe ser una persona identificable: nombre, cédula, dirección y correo. El pie de página dice "Hecho por JIC Software", que es su nombre de trabajo y no una empresa registrada.
- **Supresión:** es autoservicio. Hay un botón "Eliminar mi cuenta" en `/perfil`, sin escribir nada para confirmar.
- **Consentimiento:**
  - una casilla obligatoria, que reúne términos, política y datos de salud;
  - una casilla opcional para recibir mercadeo.
- **Textos legales:** son páginas estáticas del frontend con una versión. La versión vigente es una constante.
- **Prueba del consentimiento:** se guarda en una tabla de auditoría `consents`, a la que solo se agregan filas.

## 1. Experiencia de la clienta

### Registro (`SignupForm`)

Bajo los campos de contraseña hay dos casillas grandes, fáciles de tocar:

1. **Obligatoria:** "Acepto los [Términos] y la [Política de datos], y autorizo el uso de mis datos de salud (peso, medidas, cómo me siento) para darme recomendaciones." Debajo va un enlace "Leer más" que abre `/privacidad` en otra pestaña.
2. **Opcional:** "Quiero recibir consejos y promociones por correo o WhatsApp."

Si intenta registrarse sin marcar la obligatoria, ve el mensaje "Para crear tu cuenta necesitamos que aceptes esto." en el esquema Zod, junto a la casilla.

Como el registro ocurre en Supabase antes de que exista el usuario local, el consentimiento se manda en los metadatos del signup (`consent_version`, `consent_marketing`). En el primer `auth/sync`, el backend crea las filas de `consents` con `source: "signup"`.

### Puerta "Antes de seguir"

- **Cuándo aparece:** si `auth/sync` o `users/me` responde `consent_required: true`, el frontend muestra la pantalla `/antes-de-seguir` en lugar de cualquier página protegida. Esto cubre a las clientas que ya existían y a cualquier cambio futuro de versión. La validación vive en `ProtectedRoute`.
- **Contenido:** el mismo texto y las mismas dos casillas del registro, y el botón "Aceptar y continuar".
- **Salidas:**
  - "Prefiero no aceptar: cerrar sesión";
  - un enlace pequeño "Eliminar mi cuenta", que lleva al flujo de borrado de la sección 3.
- **Cuando el backend la bloquea:** si cualquier petición devuelve 403 `{error: "consent_required"}`, el cliente HTTP redirige a `/antes-de-seguir`.

### `/evaluacion`

Antes de "Ver mi resultado" o de guardar el correo:

- aparece la misma casilla obligatoria, adaptada: "…autorizo el uso de estos datos de salud para darme mi resultado y recomendaciones";
- aparece la casilla opcional de mercadeo;
- al final de la página va el aviso de salud corto.

### Pie de página global (nuevo)

En todas las páginas, incluidas las públicas:

> Política de datos · Términos · Aviso de salud
> Hecho por JIC Software

Usa texto grande y enlaces con área táctil de al menos 44 px.

### `/perfil` → "Tus datos"

Una sección nueva en `/perfil` con:

- el interruptor "Recibir consejos y promociones", que crea una fila `marketing` con `source: "perfil"`;
- enlaces a las tres páginas legales;
- el texto "Para pedir una copia o corregir tus datos, escríbenos a `[PENDIENTE: correo]`";
- el botón rojo **"Eliminar mi cuenta"**, descrito en la sección 3.

## 2. Datos y backend

### Tabla `consents` (solo se agregan filas)

| Columna | Tipo | Notas |
|---|---|---|
| `user_id` | bigint, null, FK | Va este o el siguiente, nunca los dos (check constraint) |
| `evaluation_lead_id` | bigint, null, FK | |
| `kind` | string, not null | `terms_and_health` \| `marketing` |
| `granted` | boolean, not null | |
| `version` | string, not null | p. ej. `2026-11-13` |
| `source` | string, not null | `signup` \| `gate` \| `evaluacion` \| `perfil` |
| `ip_address` | string, null | `request.remote_ip` |
| `created_at` | datetime | Sin `updated_at`: las filas no se editan |

- Índices: `[user_id, kind, created_at]` y `[evaluation_lead_id]`.
- Para saber el estado actual se lee la última fila por `kind`.
- **Versión vigente:** `Consents::CURRENT_VERSION = "2026-11-13"` en el backend, con la misma constante en el frontend (`lib/legal.ts`). Si la versión enviada no es la vigente, se responde 422.
- `consent_required` es verdadero si la última fila `terms_and_health` del usuario no existe, tiene `granted: false` o es de otra versión.
- Las filas del usuario se borran cuando se borra su cuenta (sección 3).

### Endpoints

- **`POST /api/v1/consents`** `{version, source, terms, marketing}`:
  - lo llama la puerta o el perfil;
  - `terms: true` es obligatorio cuando `source` es `gate`;
  - el perfil solo manda `marketing`;
  - el trabajo lo hace el interactor `Consents::Record`;
  - responde 201 con `{consent_required, marketing_opt_in}`.
- **`auth/sync` y `users/me`:** agregan `consent_required` y `marketing_opt_in` a la respuesta. El sync además registra el consentimiento del signup si vino en los metadatos y el usuario aún no tiene filas.
- **`POST /evaluation_leads`:** exige `consent: {version, terms: true, marketing}`. Sin eso responde 422. Crea el lead y sus filas de `consents` en una transacción.

### Bloqueo en el backend

Es un `before_action` en el controlador base autenticado. Si `current_user.consent_required?`, responde 403 `{error: "consent_required"}`. Quedan exentos:

- `auth/sync`;
- `POST /consents`;
- `DELETE /users/me`;
- los settings públicos;
- todo el namespace admin.

### Pruebas

Hay pruebas para:

- el modelo: la restricción de "uno de los dos" y el último estado por tipo;
- `Consents::Record`;
- el endpoint: versión vieja → 422, puerta sin `terms` → 422;
- `auth/sync` con metadatos del signup;
- el bloqueo 403 y sus exenciones;
- `evaluation_leads` sin consentimiento → 422 y con consentimiento → 201 con filas creadas.

## 3. Borrado de cuenta y seguridad

### Borrado (derecho de supresión)

Lo hace el interactor compartido `Users::DeleteAccount`. Lo usan `DELETE /api/v1/users/me` (nuevo) y `Admin::Users::Destroy`, que hoy falla con `InvalidForeignKey` cuando hay compras.

En una transacción:

1. **Borra** las filas de seguimiento (`tracking_entries`), las consultas de la Brújula con sus entradas, los hábitos con sus cumplimientos, `user_feature_usages`, `coach_demo_views`, los carritos con sus ítems y los `consents` del usuario.
2. **Borra** los `evaluation_leads` con el mismo correo, junto con sus `consents`.
3. **Anonimiza** las compras, porque se conservan por contabilidad:
   - `purchases`: `user_id = nil`, `recipient_name = nil`, `recipient_phone = nil`, `shipping_address = {}`;
   - `purchase_intents`: `user_id = nil`;
   - `payments.raw_payload`: se quitan los datos personales de la clienta que guarda Wompi (`customer_email`, `customer_data`, `shipping_address`, `billing_data`). Se conservan id, referencia, estado, monto y método de pago;
   - `orders`: no guardan datos personales, así que no cambian.
4. **Borra** el usuario.

Después de confirmar la transacción, borra el usuario en Supabase Auth: `DELETE /auth/v1/admin/users/{supabase_uid}` con la service role key, en un servicio nuevo `Supabase::AdminUsers`. Si eso falla, solo se registra el error. Para la clienta la cuenta ya quedó borrada, porque no puede volver a entrar a sus datos: un nuevo login crearía un usuario vacío.

Reglas:

- **Un admin no se puede borrar** con este flujo: responde 422.
- **Confirmación en el frontend:** un modal con un botón rojo grande "Sí, eliminar mi cuenta" y otro "No, volver". El texto explica:
  - que se borran su seguimiento, sus consultas y sus hábitos;
  - que "Tus compras se guardan sin tu nombre, por contabilidad";
  - que no se puede deshacer.
- **Al terminar:** cierra la sesión y muestra "Tu cuenta fue eliminada".

### Registros (logs) sin datos sensibles

- A `filter_parameter_logging.rb` se agregan `:weight`, `:waist`, `:height`, `:emotional_state`, `:user_input`, `:phone`, `:address`, `:cedula`, `:recipient_name`, `:shipping_address`, `:raw_payload` y `:customer_data`.
- El `tx.inspect` de Wompi que señalaba la ruta ya no existe en `status.rb`. Hoy los mensajes solo registran id y estado.
- Una prueba verifica que los parámetros filtrados aparecen como `[FILTERED]`.

### Endpoint de depuración

Se quita `POST auth/update_metadata`: la ruta, la acción y su documentación. El frontend no lo usa.

### Límite de peticiones (Rails 8 `rate_limit`, store `solid_cache`)

| Endpoint | Límite |
|---|---|
| `POST /evaluation_leads` | 5 por minuto por IP |
| `POST /marketplace/checkout/webhook` | 60 por minuto |
| `POST /auth/sync` | 30 por minuto |
| `POST /consents`, `DELETE /users/me` | 10 por minuto |

Al pasarse, responde 429 `{error: "Demasiados intentos, espera un momento"}`. Hay pruebas del 429.

### Ninguna clienta ve datos de otra (verificación #4)

Hay una prueba por recurso en la que la clienta B intenta leer o cambiar lo de la clienta A y recibe 404. Cubre:

- el carrito y sus ítems;
- los pedidos y el estado del pago;
- el seguimiento;
- los hábitos y sus cumplimientos;
- las consultas de la Brújula y sus pasos;
- el perfil.

Lo que falle se corrige en esta misma etapa, buscando siempre desde `current_user`.

## 4. Textos legales y aviso de salud

Los redacta Claude en lenguaje claro y cálido. Cada página tiene:

- un resumen "En pocas palabras" arriba;
- el texto completo debajo;
- la versión y la fecha al final.

### Política de tratamiento de datos (`/privacidad`)

Cubre lo que exigen la Ley 1581 y el Decreto 1377:

- **Responsable:** `[PENDIENTE: nombre, cédula, dirección, correo]`.
- **Datos que se recogen:**
  - de cuenta: correo, nombre y teléfono;
  - de compra: dirección de envío;
  - **sensibles de salud:** peso, medidas, estado de ánimo y lo que escribe en la Brújula y en la evaluación.
- **Finalidades:**
  - recomendaciones;
  - procesar y enviar pedidos;
  - Premium;
  - mercadeo, solo con autorización.
- **Carácter facultativo de los datos de salud,** y qué funciones no se pueden usar sin ellos.
- **Encargados con quienes se comparten:** Supabase, Wompi, Herbalife (envío) y el proveedor de correo. Los datos nunca se venden.
- **Derechos:** conocer, actualizar, rectificar y suprimir los datos, revocar la autorización y quejarse ante la SIC.
- **Cómo ejercer los derechos:** desde `/perfil` o por correo. Las consultas se responden en máximo 10 días hábiles y los reclamos en máximo 15.
- **Conservación:** los datos se guardan mientras exista la cuenta. Las compras anonimizadas se guardan el tiempo que exija la contabilidad.

### Términos y condiciones (`/terminos`)

- **Qué es QVITAL:** una herramienta de bienestar, no un servicio médico.
- **Productos:**
  - son de Herbalife;
  - los pide el distribuidor y Herbalife los envía;
  - el envío es gratis;
  - tiempos aproximados: `[PENDIENTE: días]`.
- **Premium:**
  - qué incluye;
  - 30 días por compra desde el umbral, o el plan de $30.000;
  - los días se suman;
  - no es una suscripción y no tiene cobros automáticos.
- **Derecho de retracto:**
  - 5 días hábiles desde la entrega, con el producto sin abrir (Estatuto del Consumidor, Ley 1480);
  - cómo pedirlo y cómo se devuelve el dinero: `[PENDIENTE: medio de devolución]`;
  - en Premium aplica si no se ha usado.
- **Devoluciones y garantía:** cubre productos dañados o equivocados.
- **Pagos:** se hacen por Wompi. Precios con IVA incluido: `[PENDIENTE: confirmar con el contador]`.
- **Uso de la cuenta** y ley aplicable: Colombia.

### Aviso de salud (`/aviso-de-salud`)

> QVITAL te acompaña en tu bienestar, pero no da diagnósticos ni reemplaza a tu médico. Si tienes una molestia fuerte, que no se quita o que te preocupa, consulta a un profesional de la salud. Si es una emergencia, llama al 123.

Además dice:

- que no suspenda medicamentos ni tratamientos por lo que diga la app;
- que, si está embarazada, lactando o tiene una enfermedad crónica, consulte antes de tomar suplementos.

**Dónde aparece:**

- en el pie de página, como enlace;
- en la Brújula, donde ya existe `DisclaimerFooter`;
- al final de `/evaluacion`;
- en el checkout, donde ya existe la casilla `medical_disclaimer_accepted_at`.

### Versionado

`LEGAL_VERSION = "2026-11-13"` se muestra al pie de cada página. Si un texto cambia de forma importante:

1. se sube la versión en el backend y en el frontend;
2. la puerta "Antes de seguir" vuelve a pedir el consentimiento a todas las clientas.

Los cambios menores, como erratas, no suben la versión.

## Fuera de alcance

- Exportar los datos en un archivo (portabilidad). Por ahora la copia se pide por correo.
- Un panel de admin para consultar consentimientos. Por ahora se consultan en la DB.
- Banner de cookies: QVITAL no usa cookies de terceros. Se revisa en la etapa 5, cuando entren PostHog y Meta Pixel.

## Pendientes para el contador o abogado (J)

1. Datos del responsable: nombre, cédula, dirección y correo de atención.
2. ¿Hace falta registrar la base de datos en el RNBD de la SIC? Hoy solo es obligatorio para sociedades y entidades públicas con activos superiores a 100.000 UVT, así que probablemente no aplica.
3. Si los precios se publican con IVA incluido, y la facturación electrónica.
4. Cómo y en cuánto tiempo se devuelve el dinero en un retracto.
5. Los tiempos de envío de Herbalife que se pueden prometer.
6. La revisión final de los tres textos.
