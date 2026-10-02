# Coach Virtual — Brújula Corporal (consultas)

Todos los endpoints requieren JWT válido y membresía premium (`403 { "error": "Se requiere membresía premium" }` en otro caso).

## Ficha mostrada (`ficha_mostrada`)

El `system_response_payload` de la entrada `ficha_mostrada` incluye, además de `symptom_pattern`, `emotional_theme`, `narrative_explanation`, `reflective_questions`, `integration_guidance` y `severity_flag`, el campo:

- `practices`: arreglo de 0 a 3 objetos `{ "title": String (1-50), "description": String (1-140) }`.

## POST /api/v1/coach_virtual/consultations/:id/practice_choices

Registra la práctica que la usuaria eligió al final de la consulta y si la agregó a sus hábitos. No crea el hábito: eso lo hace el frontend con la API de hábitos.

### Request

```json
{ "practice_choice": { "title": "Pausa antes de comer", "added_to_habits": true } }
```

- `title`: debe coincidir con el `title` de una de las `practices` de la última `ficha_mostrada`.
- `added_to_habits`: booleano (acepta `"true"`/`"false"`); si falta, se guarda `false`.

### Respuestas

- `200`: `{ "consultation": { ... } }` (vista con entradas). Se agrega una entrada `entry_type: "practica_elegida"` con `user_input` = `title`, `system_response_payload` = `{ "added_to_habits": bool }` y `body_emotion_insight_id` de la ficha mostrada.
- `422`: `{ "error": String }` con alguno de:
  - `Consulta no encontrada`
  - `La consulta ya está cerrada`
  - `Primero elige una zona`
  - `La práctica no corresponde a la ficha mostrada`
- `403`: el usuario no es premium.
