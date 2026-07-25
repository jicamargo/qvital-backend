cuando se crea un pedido se crea un registro en payments, con status 0, luego cuando serrecibe el webhook de wompi se actualiza:

Ejemplo de ambos registros: 

[
  {
    "id": 26,
    "purchase_id": 21,
    "external_reference": "c3b99866-7e0b-4493-8e86-f9d8c8102ea7",
    "provider": "wompi",
    "provider_payment_id": null,
    "provider_preference_id": "c3b99866-7e0b-4493-8e86-f9d8c8102ea7",
    "status": 0,
    "amount": "474280.00",
    "currency": "COP",
    "raw_payload": {
      "order": {
        "amount": "474280.0",
        "currency": "COP",
        "provider": "wompi"
      },
      "payer": {
        "name": "JORGE CAMARGO",
        "email": "jicsoftware1@gmail.com",
        "phone": "3164695217",
        "document": ""
      },
      "wompi_checkout": {
        "fields": {
          "currency": "COP",
          "reference": "c3b99866-7e0b-4493-8e86-f9d8c8102ea7",
          "public-key": "pub_test_DDZEwkIhkqzau6VXaw8oJZHOisumrvAz",
          "redirect-url": "https://api.qvital.ia/marketplace/checkout/result",
          "amount-in-cents": "47428000",
          "customer-data:email": "jicsoftware1@gmail.com",
          "signature:integrity": "7612937f5c72c1d32dfa2b940aa830df83790913fde06aa41ef130ca727371b8",
          "customer-data:full-name": "JORGE CAMARGO",
          "customer-data:phone-number": "3164695217",
          "customer-data:phone-number-prefix": "+57"
        },
        "checkout_url": "https://checkout.wompi.co/p/"
      }
    },
    "created_at": "2026-03-23 23:56:24.159754",
    "updated_at": "2026-03-23 23:56:24.159754"
  }
]


[
  {
    "id": 26,
    "purchase_id": 21,
    "external_reference": "c3b99866-7e0b-4493-8e86-f9d8c8102ea7",
    "provider": "wompi",
    "provider_payment_id": "12045125-1774310294-52190",
    "provider_preference_id": "c3b99866-7e0b-4493-8e86-f9d8c8102ea7",
    "status": 1,
    "amount": "474280.00",
    "currency": "COP",
    "raw_payload": {
      "order": {
        "amount": "474280.0",
        "currency": "COP",
        "provider": "wompi"
      },
      "payer": {
        "name": "JORGE CAMARGO",
        "email": "jicsoftware1@gmail.com",
        "phone": "3164695217",
        "document": ""
      },
      "wompi_event": {
        "event": "transaction.updated",
        "sent_at": "2026-03-23T23:58:18.632Z",
        "signature": {
          "checksum": "db8eff80b0b6c8eed2f6064801cef297c75e649bc41908a6e880990e47134435",
          "properties": [
            "transaction.id",
            "transaction.status",
            "transaction.amount_in_cents"
          ]
        },
        "timestamp": 1774310298,
        "environment": "test",
        "transaction": {
          "id": "12045125-1774310294-52190",
          "status": "APPROVED",
          "currency": "COP",
          "reference": "c3b99866-7e0b-4493-8e86-f9d8c8102ea7",
          "created_at": "2026-03-23T23:58:14.134Z",
          "finalized_at": "2026-03-23T23:58:18.358Z",
          "redirect_url": "https://api.qvital.ia/marketplace/checkout/result",
          "status_message": "",
          "amount_in_cents": 47428000,
          "payment_method_type": "BANCOLOMBIA_TRANSFER"
        }
      },
      "wompi_checkout": {
        "fields": {
          "currency": "COP",
          "reference": "c3b99866-7e0b-4493-8e86-f9d8c8102ea7",
          "public-key": "pub_test_DDZEwkIhkqzau6VXaw8oJZHOisumrvAz",
          "redirect-url": "https://api.qvital.ia/marketplace/checkout/result",
          "amount-in-cents": "47428000",
          "customer-data:email": "jicsoftware1@gmail.com",
          "signature:integrity": "7612937f5c72c1d32dfa2b940aa830df83790913fde06aa41ef130ca727371b8",
          "customer-data:full-name": "JORGE CAMARGO",
          "customer-data:phone-number": "3164695217",
          "customer-data:phone-number-prefix": "+57"
        },
        "checkout_url": "https://checkout.wompi.co/p/"
      }
    },
    "created_at": "2026-03-23 23:56:24.159754",
    "updated_at": "2026-03-23 23:58:21.398861"
  }
]

------------------------------------------------------------------------------

Esto es un analisis de los que ocurre: 

Buenísimo este análisis 👌 — esto es un flujo real de pagos, y lo tienes **bien modelado**.
Te explico claramente **qué cambió entre ambos objetos** y qué significa a nivel de negocio.

---

# 🧠 Resumen rápido

👉 Son **el mismo pago**, pero en **dos momentos distintos del flujo**:

| Estado       | Qué representa                     |
| ------------ | ---------------------------------- |
| Primer JSON  | Pago creado (checkout iniciado)    |
| Segundo JSON | Pago confirmado (webhook recibido) |

---

# 🔍 Diferencias clave

## 1️⃣ `status`

```json
"status": 0
```

vs

```json
"status": 1
```

👉 Esto es lo MÁS importante.

* `0` → pendiente / iniciado
* `1` → aprobado / pagado

💡 Tu sistema está funcionando como debe:

* primero creas el pago
* luego lo actualizas cuando llega Wompi

---

## 2️⃣ `provider_payment_id`

Primer JSON:

```json
"provider_payment_id": null
```

Segundo JSON:

```json
"provider_payment_id": "12045125-1774310294-52190"
```

👉 Esto significa:

* Antes: **no existe transacción real en Wompi**
* Después: **Wompi ya creó la transacción**

💡 Este ID es clave para:

* conciliación
* soporte
* auditoría

---

## 3️⃣ `raw_payload` cambia completamente

### 🔹 Primer JSON

Tiene:

```json
"wompi_checkout"
```

👉 Esto es:

🟡 **Lo que tú envías para crear el pago**

Contiene:

* amount
* reference
* datos del cliente
* URL de checkout

---

### 🔹 Segundo JSON

Tiene:

```json
"wompi_event"
```

👉 Esto es:

🟢 **Webhook que Wompi te envía**

Incluye:

```json
"event": "transaction.updated"
```

y:

```json
"status": "APPROVED"
```

💡 Aquí está la verdad del pago.

---

## 4️⃣ Información de la transacción

Solo aparece en el segundo:

```json
"transaction": {
  "id": "12045125-1774310294-52190",
  "status": "APPROVED",
  "finalized_at": "...",
  "payment_method_type": "BANCOLOMBIA_TRANSFER"
}
```

👉 Esto te dice:

* método de pago usado
* hora real de confirmación
* estado final

---

## 5️⃣ `updated_at`

Primer JSON:

```text
2026-03-23 23:56:24
```

Segundo JSON:

```text
2026-03-23 23:58:21
```

👉 Pasaron ~2 minutos.

💡 Flujo típico:

1. usuario inicia pago
2. paga en Wompi
3. webhook llega
4. actualizas registro

---

# 🧠 Interpretación completa del flujo

## 🟡 Paso 1 — Checkout creado

* Generas `external_reference`
* Guardas `status: 0`
* Guardas `wompi_checkout`
* Usuario es redirigido a pagar

---

## 🟢 Paso 2 — Wompi responde (webhook)

* Llega `transaction.updated`
* Status = `APPROVED`
* Guardas:

  * `provider_payment_id`
  * `status: 1`
  * `wompi_event`

---

# 🎯 Conclusión

Tu sistema ya está manejando correctamente:

✅ Separación entre:

* intención de pago
* confirmación real

✅ Uso de:

* `external_reference` (clave)
* webhook (correcto)

✅ Persistencia de:

* payload inicial
* payload final

---

# ⚠️ Mejora importante (te recomiendo)

Ahora mismo estás guardando:

```json
raw_payload
```

Pero te sugiero además guardar campos directos:

```ruby
payment_method_type
approved_at
provider_status
```

Ejemplo:

```ruby
payment.update!(
  status: :approved,
  provider_payment_id: transaction["id"],
  payment_method: transaction["payment_method_type"],
  approved_at: transaction["finalized_at"]
)
```

👉 Esto evita depender del JSON crudo después.

---

# 🚀 En una frase

👉 El primer objeto es **la intención de pago**,
👉 el segundo es **la confirmación real del dinero**.

---

Si quieres, puedo ayudarte a diseñar:

* un **estado de pagos profesional (state machine tipo Stripe)**
* o cómo manejar **pagos fallidos, pendientes y reintentos correctamente**

Eso te va a servir mucho cuando escales QVITAL 💪
