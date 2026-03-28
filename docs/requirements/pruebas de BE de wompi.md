PRUEBAS EN BACKEND:

Perfecto, con esas variables ya puedes ejecutar las pruebas manuales de backend en Sandbox.

## Plan de pruebas BE (Sandbox)

Te recomiendo cubrir 4 bloques:

1. **Firma válida** (webhook aceptado)  
2. **Firma inválida** (webhook rechazado)  
3. **Estados finales** (`APPROVED`, `DECLINED`, `VOIDED`, `ERROR`)  
4. **Duplicidad de eventos** (idempotencia por `transaction.id`)

---

## 1) Precondiciones

- Backend Rails corriendo.
- `WOMPI_ENV=sandbox` (=> el webhook espera `environment: "test"`).
- URL pública (`ngrok`) configurada en Wompi Sandbox.
- Tener un `external_reference` real generado por `/orders/prepare` + `/checkout/prepare`.

---

## 2) Script base para enviar webhook manual (firma válida)

Guarda esto como ejemplo en tu terminal (ajusta `EXTERNAL_REFERENCE`):

```bash
export WEBHOOK_URL="https://df9e-181-133-132-102.ngrok-free.app/api/v1/marketplace/checkout/webhook"
export WOMPI_EVENTS_SECRET="test_events_fSHbPRjapl5KnzaslkP50SyJaOdnzuVn"
export EXTERNAL_REFERENCE="PON_AQUI_EXTERNAL_REFERENCE_REAL"

TX_ID="test-tx-$(date +%s)"
STATUS="APPROVED"      # luego cambia a DECLINED, VOIDED, ERROR
AMOUNT_IN_CENTS="551180"
TIMESTAMP="$(date +%s)"

cat > /tmp/wompi_event.json <<EOF
{
  "event": "transaction.updated",
  "data": {
    "transaction": {
      "id": "$TX_ID",
      "reference": "$EXTERNAL_REFERENCE",
      "status": "$STATUS",
      "amount_in_cents": $AMOUNT_IN_CENTS,
      "currency": "COP"
    }
  },
  "environment": "test",
  "signature": {
    "properties": [
      "transaction.id",
      "transaction.status",
      "transaction.amount_in_cents"
    ],
    "checksum": ""
  },
  "timestamp": $TIMESTAMP
}
EOF

CHECKSUM=$(python3 - <<'PY'
import json, hashlib, os
p = json.load(open('/tmp/wompi_event.json'))
data = p["data"]
concat = ""
for prop in p["signature"]["properties"]:
    v = data
    for k in prop.split("."):
        v = v.get(k, "") if isinstance(v, dict) else ""
    concat += str(v)
concat += str(p["timestamp"]) + os.environ["WOMPI_EVENTS_SECRET"]
print(hashlib.sha256(concat.encode()).hexdigest())
PY
)

python3 - <<'PY'
import json
f='/tmp/wompi_event.json'
p=json.load(open(f))
import os
p["signature"]["checksum"]=os.environ["CHECKSUM"]
json.dump(p, open(f,'w'))
PY

curl -i -X POST "$WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -H "X-Event-Checksum: $CHECKSUM" \
  --data-binary @/tmp/wompi_event.json
```

Esperado con firma válida: **HTTP 200**.

---

## 3) Prueba de firma inválida

Repite el mismo payload pero cambia el header checksum:

```bash
curl -i -X POST "$WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -H "X-Event-Checksum: 0000000000000000000000000000000000000000000000000000000000000000" \
  --data-binary @/tmp/wompi_event.json
```

Esperado: **422** con error `Invalid webhook signature`.

---

## 4) Prueba de ambiente inválido

Edita payload y cambia:

- `"environment": "prod"` (dejando `WOMPI_ENV=sandbox`)

Envía con checksum correcto.

Esperado: **422** con error `Invalid webhook environment`.

---

## 5) Prueba de estados finales

Para cada estado, usa un `TX_ID` distinto y un `external_reference` de una compra en estado pendiente:

- `APPROVED` => `payment.status = approved` y se dispara `orders/complete`.
- `DECLINED` => `payment.status = rejected` y **no** completa orden.
- `VOIDED` => `payment.status = rejected` y **no** completa orden.
- `ERROR` => `payment.status = rejected` y **no** completa orden.

---

## 6) Prueba de duplicidad (idempotencia)

Envía **dos veces** exactamente el mismo evento (`mismo TX_ID`, mismo checksum/payload).

Esperado:

- ambos requests retornan **200**,
- no se crean múltiples pagos para el mismo `provider_payment_id`,
- la orden no se duplica ni se reconfirma de forma inconsistente.

---

## 7) Cómo validar resultados

### A) Endpoint de estado
Con JWT:
- `GET /api/v1/marketplace/checkout/status?transaction_id=<TX_ID>`
- o `?external_reference=<ref>`

### B) DB (rápido)
Revisar:
- `payments` (`provider_payment_id`, `status`, `external_reference`)
- `purchase_intents`, `purchases`, `orders` (transiciones de estado)

---


------------------------ PASO A PASO EN POSTMAN --------------------------  

Perfecto. Lo más fácil para ti es hacerlo **100% con Postman** (sin scripts de terminal).

## App a usar
- **Postman** (principal)
- Opcional: tu app/frontend para generar `external_reference` real

---

## Paso a paso (Postman)

## 0) Crea un Environment en Postman

Variables recomendadas:

- `API_URL` = `http://localhost:3001` (o tu backend)
- `WEBHOOK_URL` = `https://df9e-181-133-132-102.ngrok-free.app/api/v1/marketplace/checkout/webhook`
- `JWT` = `<token válido>`
- `WOMPI_EVENTS_SECRET` = `test_events_fSHbPRjapl5KnzaslkP50SyJaOdnzuVn`
- `external_reference` = (la llenas luego)
- `checksum` = vacío
- `tx_id` = vacío

---

## 1) Genera un `external_reference` real

Puedes hacerlo desde tu frontend o con Postman:

1. `POST {{API_URL}}/api/v1/marketplace/orders/prepare` (con JWT)
2. Copia `external_reference` de la respuesta
3. Guárdalo en variable de Postman `external_reference`

---

## 2) (Opcional pero recomendado) Prepara checkout

1. `POST {{API_URL}}/api/v1/marketplace/checkout/prepare`
2. Usa `external_reference` en body
3. Esto deja `payment` en `pending` antes del webhook

---

## 3) Crea request de webhook válido en Postman

### Request
- Método: `POST`
- URL: `{{WEBHOOK_URL}}`
- Headers:
  - `Content-Type: application/json`
  - `X-Event-Checksum: {{checksum}}`

### Body (raw JSON)
Pon este body base:

```json
{
  "event": "transaction.updated",
  "data": {
    "transaction": {
      "id": "test-tx-001",
      "reference": "{{external_reference}}",
      "status": "APPROVED",
      "amount_in_cents": 551180,
      "currency": "COP"
    }
  },
  "environment": "test",
  "signature": {
    "properties": [
      "transaction.id",
      "transaction.status",
      "transaction.amount_in_cents"
    ],
    "checksum": ""
  },
  "timestamp": 0
}
```

### Pre-request Script (en esa request)
Pega esto:

```javascript
const CryptoJS = require('crypto-js');

let payload = JSON.parse(pm.request.body.raw);

// timestamp dinámico
payload.timestamp = Math.floor(Date.now() / 1000);

// tx_id dinámico si quieres
if (!pm.environment.get('tx_id')) {
  pm.environment.set('tx_id', `test-tx-${Date.now()}`);
}
payload.data.transaction.id = pm.environment.get('tx_id');

// helper para obtener paths tipo "transaction.id"
function pick(obj, path) {
  return path.split('.').reduce((acc, k) => (acc && acc[k] !== undefined ? acc[k] : ''), obj);
}

const props = payload.signature.properties || [];
const concatenated =
  props.map(p => String(pick(payload.data, p))).join('') +
  String(payload.timestamp) +
  pm.environment.get('WOMPI_EVENTS_SECRET');

const checksum = CryptoJS.SHA256(concatenated).toString(CryptoJS.enc.Hex);

// guarda checksum en header variable
pm.environment.set('checksum', checksum);

// también lo pone dentro del body
payload.signature.checksum = checksum;
pm.request.body.update(JSON.stringify(payload, null, 2));
```

Ahora presiona **Send**.

### Esperado
- HTTP `200 OK`

---

## 4) Prueba de firma inválida

Duplica la request anterior y haz esto:

- En Headers, pon:
  - `X-Event-Checksum: 0000000000000000000000000000000000000000000000000000000000000000`
- Quita el Pre-request Script (o déjalo pero que no sobreescriba header variable)

Envía.

### Esperado
- HTTP `422`
- error: `Invalid webhook signature`

---

## 5) Prueba de ambiente inválido

Usa la request válida, pero cambia en body:

- `"environment": "prod"` (tu backend está en sandbox)

Mantén firma correcta con pre-request script (sí debe firmar ese payload con `prod`).

### Esperado
- HTTP `422`
- error: `Invalid webhook environment`

---

## 6) Prueba de estados finales

Repite request válida cambiando:

- `status = APPROVED`
- `status = DECLINED`
- `status = VOIDED`
- `status = ERROR`

Usa `tx_id` distinto en cada una.

### Esperado
- `APPROVED` -> `payment` aprobado y se completa orden
- `DECLINED/VOIDED/ERROR` -> `payment` rechazado, no completa orden

---

## 7) Prueba de duplicidad (idempotencia)

Envía **dos veces** el mismo evento:
- mismo `tx_id`
- misma `reference`
- idealmente mismo payload

Tip Postman: enviar una vez y luego **Resend** desde History.

### Esperado
- ambas respuestas `200`
- no se crean pagos duplicados por `provider_payment_id`
- no hay inconsistencias de estado de orden

---

## 8) Validación final

### A) Endpoint de estado
Con JWT:
- `GET {{API_URL}}/api/v1/marketplace/checkout/status?transaction_id=<tx_id>`
- o `... ?external_reference={{external_reference}}`

### B) Verifica DB (si quieres)
Tabla `payments`:
- `provider = wompi`
- `provider_payment_id = tx_id`
- `status` según caso

---

## 9) Collection de Postman lista para importar

### 9.1 Paso a paso (importar y usar)

1. Copia el JSON completo de la sección **9.2**.
2. En Postman: **Import** -> **Raw text** -> pega el JSON -> **Continue** -> **Import**.
3. Crea un **Environment** nuevo (ejemplo: `Wompi Sandbox BE`) con estas variables:
   - `API_URL`
   - `WEBHOOK_URL`
   - `JWT`
   - `WOMPI_EVENTS_SECRET`
   - `external_reference` (inicialmente vacío)
   - `tx_id` (inicialmente vacío)
   - `checksum` (inicialmente vacío)
   - `status` (valor inicial sugerido: `APPROVED`)
4. Selecciona ese Environment en la esquina superior derecha de Postman.
5. Ejecuta requests en este orden:
   - `01 - Orders Prepare (opcional, genera external_reference)`
   - `02 - Checkout Prepare`
   - `03 - Webhook VALID signature (transaction.updated)`
   - `06 - Checkout Status by transaction_id`
6. Para probar estados finales, cambia variable `status` a: `DECLINED`, `VOIDED`, `ERROR` y vuelve a enviar `03`.
7. Para firma inválida usa `04 - Webhook INVALID signature`.
8. Para ambiente inválido usa `05 - Webhook INVALID environment`.
9. Para duplicidad, reenvía exactamente `03` (mismo `tx_id`) desde History.

---

### 9.2 JSON de Collection (Postman v2.1)

```json
{
  "info": {
    "_postman_id": "7ed65fe8-9b17-4f18-a1c4-5f4f6a3c9a01",
    "name": "QVITAL - Wompi Sandbox BE Tests",
    "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json",
    "description": "Pruebas manuales BE para webhook y flujo Wompi Sandbox."
  },
  "item": [
    {
      "name": "01 - Orders Prepare (opcional, genera external_reference)",
      "request": {
        "method": "POST",
        "header": [
          {
            "key": "Content-Type",
            "value": "application/json"
          },
          {
            "key": "Authorization",
            "value": "Bearer {{JWT}}"
          }
        ],
        "body": {
          "mode": "raw",
          "raw": "{\n  \"cart_items\": [\n    {\n      \"product_id\": 13,\n      \"quantity\": 1,\n      \"price\": \"96910.0\",\n      \"metadata\": {}\n    }\n  ],\n  \"shipping_address\": {\n    \"street\": \"CR 5 SUR 83 200 CON RES LA FLORIDA 1\",\n    \"city\": \"IBAGUE\",\n    \"state\": \"Tolima\",\n    \"zipCode\": \"730005\",\n    \"phone\": \"3001112233\"\n  },\n  \"recipient_info\": {\n    \"is_different\": false,\n    \"name\": \"PEDRO CAMANEI\",\n    \"phone\": \"3001112233\"\n  },\n  \"selected_date\": \"2026-03-06\",\n  \"shipping_cost\": \"0\",\n  \"payment_method\": \"credit_card\",\n  \"purchase_intent_id\": null,\n  \"update_user_profile\": true\n}"
        },
        "url": {
          "raw": "{{API_URL}}/api/v1/marketplace/orders/prepare",
          "host": [
            "{{API_URL}}"
          ],
          "path": [
            "api",
            "v1",
            "marketplace",
            "orders",
            "prepare"
          ]
        }
      },
      "event": [
        {
          "listen": "test",
          "script": {
            "exec": [
              "if (pm.response.code === 200) {",
              "  const data = pm.response.json();",
              "  if (data.external_reference) {",
              "    pm.environment.set('external_reference', data.external_reference);",
              "  }",
              "}"
            ],
            "type": "text/javascript"
          }
        }
      ]
    },
    {
      "name": "02 - Checkout Prepare",
      "request": {
        "method": "POST",
        "header": [
          {
            "key": "Content-Type",
            "value": "application/json"
          },
          {
            "key": "Authorization",
            "value": "Bearer {{JWT}}"
          }
        ],
        "body": {
          "mode": "raw",
          "raw": "{\n  \"external_reference\": \"{{external_reference}}\",\n  \"payer\": {\n    \"name\": \"JORGE CAMARGO\",\n    \"email\": \"jicsoftware1@gmail.com\",\n    \"phone\": \"3001112233\",\n    \"document\": \"12345678\"\n  },\n  \"order\": {\n    \"amount\": \"551180.0\",\n    \"currency\": \"COP\",\n    \"provider\": \"wompi\"\n  },\n  \"shipping_address\": {\n    \"street\": \"CR 5 SUR 83 200 CON RES LA FLORIDA 1\",\n    \"city\": \"IBAGUE\",\n    \"state\": \"Tolima\",\n    \"zipCode\": \"730005\",\n    \"phone\": \"3001112233\"\n  },\n  \"recipient_info\": {\n    \"name\": \"PEDRO CAMANEI\",\n    \"phone\": \"3001112233\"\n  }\n}"
        },
        "url": {
          "raw": "{{API_URL}}/api/v1/marketplace/checkout/prepare",
          "host": [
            "{{API_URL}}"
          ],
          "path": [
            "api",
            "v1",
            "marketplace",
            "checkout",
            "prepare"
          ]
        }
      }
    },
    {
      "name": "03 - Webhook VALID signature (transaction.updated)",
      "request": {
        "method": "POST",
        "header": [
          {
            "key": "Content-Type",
            "value": "application/json"
          },
          {
            "key": "X-Event-Checksum",
            "value": "{{checksum}}"
          }
        ],
        "body": {
          "mode": "raw",
          "raw": "{\n  \"event\": \"transaction.updated\",\n  \"data\": {\n    \"transaction\": {\n      \"id\": \"{{tx_id}}\",\n      \"reference\": \"{{external_reference}}\",\n      \"status\": \"{{status}}\",\n      \"amount_in_cents\": 551180,\n      \"currency\": \"COP\"\n    }\n  },\n  \"environment\": \"test\",\n  \"signature\": {\n    \"properties\": [\n      \"transaction.id\",\n      \"transaction.status\",\n      \"transaction.amount_in_cents\"\n    ],\n    \"checksum\": \"\"\n  },\n  \"timestamp\": 0\n}"
        },
        "url": {
          "raw": "{{WEBHOOK_URL}}",
          "host": [
            "{{WEBHOOK_URL}}"
          ]
        }
      },
      "event": [
        {
          "listen": "prerequest",
          "script": {
            "exec": [
              "const CryptoJS = require('crypto-js');",
              "let payload = JSON.parse(pm.request.body.raw);",
              "if (!pm.environment.get('tx_id')) {",
              "  pm.environment.set('tx_id', `test-tx-${Date.now()}`);",
              "}",
              "payload.data.transaction.id = pm.environment.get('tx_id');",
              "payload.timestamp = Math.floor(Date.now() / 1000);",
              "function pick(obj, path) {",
              "  return path.split('.').reduce((acc, k) => (acc && acc[k] !== undefined ? acc[k] : ''), obj);",
              "}",
              "const props = payload.signature.properties || [];",
              "const concatenated = props.map(p => String(pick(payload.data, p))).join('') + String(payload.timestamp) + pm.environment.get('WOMPI_EVENTS_SECRET');",
              "const checksum = CryptoJS.SHA256(concatenated).toString(CryptoJS.enc.Hex);",
              "pm.environment.set('checksum', checksum);",
              "payload.signature.checksum = checksum;",
              "pm.request.body.update(JSON.stringify(payload, null, 2));"
            ],
            "type": "text/javascript"
          }
        }
      ]
    },
    {
      "name": "04 - Webhook INVALID signature",
      "request": {
        "method": "POST",
        "header": [
          {
            "key": "Content-Type",
            "value": "application/json"
          },
          {
            "key": "X-Event-Checksum",
            "value": "0000000000000000000000000000000000000000000000000000000000000000"
          }
        ],
        "body": {
          "mode": "raw",
          "raw": "{\n  \"event\": \"transaction.updated\",\n  \"data\": {\n    \"transaction\": {\n      \"id\": \"{{tx_id}}\",\n      \"reference\": \"{{external_reference}}\",\n      \"status\": \"APPROVED\",\n      \"amount_in_cents\": 551180,\n      \"currency\": \"COP\"\n    }\n  },\n  \"environment\": \"test\",\n  \"signature\": {\n    \"properties\": [\n      \"transaction.id\",\n      \"transaction.status\",\n      \"transaction.amount_in_cents\"\n    ],\n    \"checksum\": \"invalid\"\n  },\n  \"timestamp\": 1730000000\n}"
        },
        "url": {
          "raw": "{{WEBHOOK_URL}}",
          "host": [
            "{{WEBHOOK_URL}}"
          ]
        }
      }
    },
    {
      "name": "05 - Webhook INVALID environment",
      "request": {
        "method": "POST",
        "header": [
          {
            "key": "Content-Type",
            "value": "application/json"
          },
          {
            "key": "X-Event-Checksum",
            "value": "{{checksum}}"
          }
        ],
        "body": {
          "mode": "raw",
          "raw": "{\n  \"event\": \"transaction.updated\",\n  \"data\": {\n    \"transaction\": {\n      \"id\": \"{{tx_id}}\",\n      \"reference\": \"{{external_reference}}\",\n      \"status\": \"APPROVED\",\n      \"amount_in_cents\": 551180,\n      \"currency\": \"COP\"\n    }\n  },\n  \"environment\": \"prod\",\n  \"signature\": {\n    \"properties\": [\n      \"transaction.id\",\n      \"transaction.status\",\n      \"transaction.amount_in_cents\"\n    ],\n    \"checksum\": \"\"\n  },\n  \"timestamp\": 0\n}"
        },
        "url": {
          "raw": "{{WEBHOOK_URL}}",
          "host": [
            "{{WEBHOOK_URL}}"
          ]
        }
      },
      "event": [
        {
          "listen": "prerequest",
          "script": {
            "exec": [
              "const CryptoJS = require('crypto-js');",
              "let payload = JSON.parse(pm.request.body.raw);",
              "if (!pm.environment.get('tx_id')) {",
              "  pm.environment.set('tx_id', `test-tx-${Date.now()}`);",
              "}",
              "payload.data.transaction.id = pm.environment.get('tx_id');",
              "payload.timestamp = Math.floor(Date.now() / 1000);",
              "function pick(obj, path) {",
              "  return path.split('.').reduce((acc, k) => (acc && acc[k] !== undefined ? acc[k] : ''), obj);",
              "}",
              "const props = payload.signature.properties || [];",
              "const concatenated = props.map(p => String(pick(payload.data, p))).join('') + String(payload.timestamp) + pm.environment.get('WOMPI_EVENTS_SECRET');",
              "const checksum = CryptoJS.SHA256(concatenated).toString(CryptoJS.enc.Hex);",
              "pm.environment.set('checksum', checksum);",
              "payload.signature.checksum = checksum;",
              "pm.request.body.update(JSON.stringify(payload, null, 2));"
            ],
            "type": "text/javascript"
          }
        }
      ]
    },
    {
      "name": "06 - Checkout Status by transaction_id",
      "request": {
        "method": "GET",
        "header": [
          {
            "key": "Authorization",
            "value": "Bearer {{JWT}}"
          }
        ],
        "url": {
          "raw": "{{API_URL}}/api/v1/marketplace/checkout/status?transaction_id={{tx_id}}",
          "host": [
            "{{API_URL}}"
          ],
          "path": [
            "api",
            "v1",
            "marketplace",
            "checkout",
            "status"
          ],
          "query": [
            {
              "key": "transaction_id",
              "value": "{{tx_id}}"
            }
          ]
        }
      }
    }
  ],
  "variable": [
    { "key": "API_URL", "value": "http://localhost:3001" },
    { "key": "WEBHOOK_URL", "value": "https://df9e-181-133-132-102.ngrok-free.app/api/v1/marketplace/checkout/webhook" },
    { "key": "JWT", "value": "" },
    { "key": "WOMPI_EVENTS_SECRET", "value": "test_events_fSHbPRjapl5KnzaslkP50SyJaOdnzuVn" },
    { "key": "external_reference", "value": "" },
    { "key": "tx_id", "value": "" },
    { "key": "checksum", "value": "" },
    { "key": "status", "value": "APPROVED" }
  ]
}
```
 