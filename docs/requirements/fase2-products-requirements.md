
QVITAL ya tiene:

* Auth moderna (ES256 + JWKS)
* Sync desacoplado
* Interactor
* Roles + niveles
* Frontend integrado
* Design system base


# 🎯 Ahora viene la parte importante

Ya no estamos en fase técnica.
Estamos en fase de **producto mínimo funcional (MVP real)**.

Y el siguiente paso correcto NO es seguir mejorando auth.

Es construir el primer flujo de valor para el usuario.

---

# 🚀 Qué sigue ahora en QVITAL

Recuerda el objetivo:

> Usuario entra → ve valor → compra → tú recibes pedido.

Entonces el siguiente bloque lógico es:

# 🟢 BLOQUE 1 — Sistema de Productos + Marketplace básico

Ahora debes conectar:

* products
* product_prices
* level del usuario

Y mostrar productos dinámicamente según su nivel.

---

# 🧠 Paso estratégico clave

Tu marketplace NO debe mostrar el mismo precio a todos.

Debe hacer:

```text
user.level → determina precio → mostrar precio correcto
```

Eso es el corazón de tu modelo de negocio.

---

# 🎯 Lo siguiente que deberías implementar

En este orden:

## 1️⃣ Backend

Crear endpoint:

```
GET /api/v1/products
```

Que:

* Obtenga usuario autenticado (usando JWT validado)
* Determine su level
* Devuelva productos con el precio correspondiente a su level

Ejemplo respuesta:

```json
{
  "products": [
    {
      "id": 1,
      "name": "Proteína Herbal",
      "price": 850.00,
      "currency": "MXN"
    }
  ]
}
```

No devuelvas todos los precios.
Solo el correspondiente.

---

## 2️⃣ Middleware de autenticación global

Ya validas en `/sync`.

Ahora debes:

* Extraer validación JWT a un concern o middleware
* Proteger rutas automáticamente

Ejemplo:

```ruby
before_action :authenticate_user!
```

Eso hace que tu API ya sea profesional.

---

## 3️⃣ Frontend

Crear:

```
/app/marketplace
```

Y:

* Fetch productos
* Render ProductCard
* Mostrar precio dinámico

---

# 🔥 Este es el momento clave

Cuando el usuario logueado vea:

* Su precio personalizado
* Productos reales
* Layout profesional

QVITAL deja de ser infraestructura.
Se convierte en negocio.

---

# 🧠 Arquitectura mental correcta ahora

Auth ya está.

Ahora debes construir:

```
Auth → Usuario → Nivel → Precio → Compra → Pedido
```

Ese es el flujo SaaS.

---

# 🎯 Mi recomendación concreta

Siguiente sprint:

1. Middleware global JWT
2. Endpoint GET /products con precio por nivel
3. Página marketplace básica mostrando datos reales

Nada más.

No carrito todavía.
No MercadoPago todavía.

Primero ver precio dinámico funcionando.

---

Si quieres, ahora te diseño la arquitectura exacta del endpoint `/products` correctamente estructurada con interactor y serializer limpio.
