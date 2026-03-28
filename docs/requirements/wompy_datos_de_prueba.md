Datos de prueba en Sandbox
Para realizar una transacción de pruebas sólo debes asegurarte que estás usando la llave pública de comercio para el ambiente Sandbox. Recuerda que esta tiene el prefijo pub_test_.

A continuación verás los datos de prueba necesarios para cada uno de los métodos de pago:

Tarjetas
Para una transacción de pruebas con tarjeta puedes usar los siguientes números de tarjeta a la hora de usar el endpoint de tokenización (si usas una integración con API) o al llenar los datos de la tarjeta en el Widget, para obtener respuestas distintas:

4242 4242 4242 4242 para una transacción aprobada (APPROVED). Cualquier fecha de expiración en el futuro y CVC de 3 dígitos son válidos.
4111 1111 1111 1111 para una transacción declinada (DECLINED). Cualquier fecha de expiración en el futuro y CVC de 3 dígitos son válidos.
Si usas cualquier otra tarjeta que no sea alguna de estas dos, el estado final de la transacción será ERROR.

Nequi
Para realizar transacciones aprobadas o rechazadas en el ambiente Sandbox sólo debes tener en cuenta los siguientes números:

3991111111 para generar una transacción aprobada (APPROVED)
3992222222 para generar una transacción declinada (DECLINED)
Ten en cuenta que cualquier otro número que utilices resultará en una transacción con status final en ERROR.

Por ejemplo:

{
  // Otros campos de la transacción a crear...
  "payment_method": {
    "type": "NEQUI",
    "phone_number": "3991111111" // Esto resultará current una transacción APROBADA
  }
}

PSE
Para pagos con PSE, en caso de usar integración directa con el API debes enviar un tipo de banco específico, con la propiedad financial_institution_code del objeto payment_method, en el momento que estés creando una transacción (con el endpoint POST /transactions). Por ejemplo:

{
  // Otros campos de la transacción a crear...
  "payment_method": {
    "type": "PSE",
    "user_type": 0, // Tipo de persona, natural (0) o jurídica (1)
    "user_legal_id_type": "CC", // Tipo de documento, CC o NIT
    "user_legal_id": "1999888777", // Número de documento
    "financial_institution_code": "1", // "1" para transacciones APROBADAS, "2" para transacciones DECLINADAS
    "payment_description": "Pago a Tienda Wompi" // Nombre de lo que se está pagando. Máximo 30 caracteres
  }
}


Para la integración con Widget, verás listados los siguientes bancos para tu elección:

Banco que aprueba: Con este, obtienes una transacción APROBADA de PSE.
Banco que rechaza: Con este, obtienes una transacción DECLINADA de PSE.
Botón de Transferencia Bancolombia
Para pagos con Botón Bancolombia, en caso de usar integración directa con el API debes usar la propiedad sandbox_status dentro del objeto payment_method, en el momento que estés creando una transacción (con el endpoint POST /transactions). Por ejemplo:

{
  // Otros campos de la transacción a crear...
  "payment_method": {
    "type": "BANCOLOMBIA_TRANSFER",
    "payment_description": "Pago a Tienda Wompi", // Nombre de lo que se está pagando. Máximo 64 caracteres
  }
}


Una vez iniciada la transacción y consultando el estado de la misma se puede ejecutar la aprobación seleccionando el botón en la redirección del campo data -> payment_method -> async_payment_url

{
  "data": {
    "id": "11004-1718123303-80111",
    "created_at": "2024-06-11T16:28:23.299Z",
    "finalized_at": null,
    "amount_in_cents": 150000,
    "reference": "jvo4t513zc9",
    "currency": "COP",
    "payment_method_type": "BANCOLOMBIA_TRANSFER",
    "payment_method": {
      "type": "BANCOLOMBIA_TRANSFER",
      "extra": {
        "is_three_ds": false,
        "async_payment_url": "<<URL a cargar el paso de autenticación>>"
      },
      "user_type": "PERSON",
      "payment_description": "Prueba"
    },
    "payment_link_id": null,
    ............ Demas datos de respuesta

Esa URL te llevara la siguiente vista donde puedes seleccionar el estado en el que quires que la transacción termine

Bandbox AUTH Page

Bancolombia QR
Para pagos con Bancolombia QR, en caso de usar integración directa con el API debes usar la propiedad sandbox_status dentro del objeto payment_method, en el momento que estés creando una transacción (con el endpoint POST /transactions). Por ejemplo:

{
  // Otros campos de la transacción a crear...
  "payment_method": {
    "type": "BANCOLOMBIA_QR",
    "payment_description": "Pago a Tienda Wompi", // Nombre de lo que se está pagando. Máximo 64 caracteres
    "sandbox_status": "APPROVED" // Status final deseado en el Sandbox. Uno de los siguientes: APPROVED, DECLINED o ERROR
  }
}


Para la integración con Widget, verás listados los siguientes estados para tu elección:

Transacción APROBADA
Transacción DECLINADA
Transacción con ERROR
Puntos Colombia
Para pago con Puntos Colombia, en caso de usar integración directa con el API debes usar la propiedad sandbox_status dentro del objeto payment_method, en el momento que estés creando una transacción (con el endpoint POST /transactions). Ejemplo:

{
  // Otros campos de la transacción a crear...
  "payment_method": {
    "type": "PCOL",
    "sandbox_status": "APPROVED_ONLY_POINTS" // Status final deseado en el Sandbox.
  }
}

Los posibles estados de prueba para el campo sandbox_status son:

APPROVED_ONLY_POINTS: Pago total con puntos
APPROVED_HALF_POINTS: Pago 50% con puntos
DECLINED: Pago solo puntos declinado
ERROR: Error al realizar el pago con solo puntos
BNPL Bancolombia
Para el entorno de prueba de BNPL, la única variación que notarás es que la URL que te dirige a la experiencia de BNPL te llevará a una página donde podrás definir el estado final en el que concluirá la transacción. El aspecto del sitio web será el siguiente:

sandbox bnpl

DAVIPLATA - Pago simple
Cuando inicias una transacción con el medio de pago Daviplata y utilizas la interfaz proporcionada por Wompi, tendrás la posibilidad de elegir el estado final de la transacción, como se muestra en la siguiente imagen:

sandbox daviplata

Para llevar a cabo transacciones mediante la API, simplemente debes tener en cuenta los siguientes códigos OTP:

574829 para generar una transacción aprobada (APPROVED)
932015 para generar una transacción declinada (DECLINED)
186743 para generar una transacción declinada sin saldo (DECLINED)
999999 para generar una transacción error (ERROR)
DAVIPLATA - Pago recurrente
Para crear un token Daviplata podemos usar los siguientes numeros de prueba:

3991111111 para crear un token, y obtener transacciones aprobadas (APPROVED)
3992222222 para crear un token, y obtener transacciones declinadas (DECLINED)
3993333333 para crear un token declinado monedero invalido (DECLINED)
Codigos OTPs:

574829 para confirmar un token como aprobado (APPROVED)
932016 para confirmar un token como declinado por suscripción ya existente (DECLINED)
Para simular un mensaje de codigo OTP invalido debes ingresar cualquier numero de 6 digitos
Su+ Pay
Para el entorno de prueba de SU+ Pay, serás redirigido a una página donde podrás definir el estado final de la transacción. El aspecto del sitio web será el siguiente:

sandbox su + pay
