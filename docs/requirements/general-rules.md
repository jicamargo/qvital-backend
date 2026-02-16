- Controllers minimalistas
- Logica en interactors 
- uso de blueprinter para serializar las respuestas
- DRY, SOLID, DESACOPLADO 
- Siempre que se cree un nuevo endpoint, se debe crear un nuevo archivo en el directorio `docs/endpoints` con el nombre del endpoint para que los dev de frontend puedan ver la documentación del endpoint.

- Este proyecto es un MVP para usarlo por ahora por mi (el creador del proyecto), pero despues se escalara a un SaaS multitenant, asi que ten presente esto a la hora de diseñar la arquitectura, es decir hazlo funcional y rapido para MVP, pero que sea escalable para SaaS posteriormente sin tener que refactorizar mucho.
-Toda documentacion debe devidirse en fases y seiones de backend y frontend con [X] y [ ] para que se pueda ver el progreso de la implementacion e ir actualizando la documentacion a medida que se va implementando.
- Si alguna recomendacion o prompt va en contravia de las reglas generales, buenas prtacticas, se debe explicar por que, justificar la decision y confirmar conmigo antes de implementar.


--------------- DESCRIPCION GENERAL DEL PROYECTO ---------------

Estás construyendo más que un marketplace: estás creando un ecosistema de transformación personal.
Te propongo un mapa estructural base de la app, pensado para:
•	🧲 Atraer tráfico (SEO + valor real)
•	🧠 Generar confianza
•	📊 Ofrecer herramientas gratuitas útiles
•	🔐 Convertir a Premium (Marketplace + servicios personalizados)
________________________________________
🗺️ MAPA GENERAL DE QVITAL
________________________________________
🌍 1. PARTE PÚBLICA (GRATUITA – LANDING + CONTENIDO)
Esta parte es tu máquina de atracción y conversión.
________________________________________
🏠 1. Home (Landing Principal)
Objetivo: Convertir visitantes en usuarios registrados.
Secciones recomendadas:
1.	Hero section
o	Frase potente: “Transforma tu salud con hábitos simples y sostenibles”
o	CTA principal: Empieza gratis
o	CTA secundaria: Haz tu evaluación gratuita
2.	¿Qué es QVITAL?
o	Explicación clara del enfoque:
	No fitness extremo
	No dietas restrictivas
	No presión
	Enfoque integral: cuerpo + mente + hábitos
3.	Beneficios clave
o	Plan personalizado
o	Evaluación con IA
o	Recetas fáciles
o	Retos simples
o	Marketplace saludable
4.	Testimonios (futuro)
5.	CTA final fuerte → Registro
________________________________________
📊 2. Evaluación Gratuita (IA Health Check)
Este será tu mayor gancho.
Página: /evaluacion
Funcionalidades:
•	Formulario:
o	Edad
o	Sexo
o	Peso
o	Estatura
o	Nivel de actividad
o	Objetivo
o	Estado emocional general
•	Cálculos automáticos:
o	IMC
o	Clasificación general
o	Recomendaciones básicas
•	Respuesta con agente IA:
o	Diagnóstico amigable
o	Sugerencias iniciales
o	CTA: “Desbloquea tu plan personalizado”
Aquí conviertes fuerte 🔥
________________________________________
🥗 3. Biblioteca de Hábitos (Blog educativo)
Página: /habitos
Categorías:
•	Alimentación sencilla
•	Movimiento para no amantes del ejercicio
•	Salud mental y emocional
•	Rutinas simples de 10 minutos
•	Espiritualidad y propósito
Formato:
•	Artículos
•	Mini guías
•	Checklists descargables
•	Videos cortos
Objetivo: SEO + autoridad + confianza.
________________________________________
🍽 4. Recetas Fáciles
Página: /recetas
Filtros:
•	Menos de 15 minutos
•	Económicas
•	Alta proteína
•	Antiinflamatorias
•	Para principiantes
Objetivo:
Mostrar valor real y práctico.
Algunas recetas premium pueden requerir registro 👀
________________________________________
🧘 5. Mini Retos Gratuitos
Página: /retos
Ejemplos:
•	Reto 7 días de hidratación
•	5 días caminando 10 minutos
•	3 días sin azúcar añadida
•	Reto “Dormir mejor”
Funciona como micro onboarding.
________________________________________
🤖 6. Agente IA Público (Limitado)
Página: /coach-ia
Permite:
•	3 preguntas gratis
•	Respuestas generales
Luego:
“Para un plan personalizado crea tu cuenta”
________________________________________
💰 7. Página Premium / Marketplace
Página: /premium
Explica:
•	Qué desbloquea el plan premium
•	Acceso a:
o	Plan personalizado completo
o	Seguimiento
o	Productos saludables
o	Programas guiados
o	Comunidad
Botón claro:
👉 “Acceder al Marketplace”
________________________________________
🔐 2. PARTE PRIVADA (USUARIO REGISTRADO)
Aquí empieza el producto real.
________________________________________
📊 1. Dashboard Personal
Página: /dashboard
Componentes:
•	Resumen de salud
•	Progreso
•	Hábitos activos
•	Recomendaciones IA
•	Acceso rápido a marketplace
________________________________________
📈 2. Mi Plan Personalizado
Página: /mi-plan
Incluye:
•	Objetivos
•	Plan semanal
•	Rutina simple
•	Guía alimenticia
•	Seguimiento emocional
________________________________________
🛒 3. Marketplace
Página: /marketplace
Podría incluir:
•	Productos saludables
•	Programas digitales
•	Coaching
•	Retos avanzados
•	Suplementos (si aplica)
Modelo:
•	Compra directa
•	Suscripción
•	Créditos internos
________________________________________
📅 4. Seguimiento
Página: /seguimiento
•	Registro de peso
•	Estado de ánimo
•	Energía
•	Hábitos cumplidos
•	Gráficas simples
________________________________________
🤖 5. Coach IA Completo
•	Consultas ilimitadas
•	Recomendaciones personalizadas
•	Ajuste de plan dinámico
________________________________________
🧠 ESTRUCTURA GENERAL DE RUTAS
/ (home)
/evaluacion
/habitos
/recetas
/retos
/coach-ia
/premium
/login
/signup

/dashboard
/mi-plan
/marketplace
/seguimiento
/perfil
________________________________________
🎯 FUNNEL DE CONVERSIÓN IDEAL
1.	Usuario llega por SEO → Artículo
2.	Ve CTA → Haz tu evaluación gratuita
3.	Recibe resultado personalizado
4.	CTA fuerte → Desbloquea tu plan
5.	Se registra
6.	Ve dashboard básico
7.	Upsell a premium
________________________________________
💡 Posicionamiento Estratégico
QVITAL no es:
•	❌ Un gym online
•	❌ Una dieta estricta
•	❌ Un coach fitness hardcore
QVITAL es:
“La forma simple, realista y sostenible de mejorar tu salud.”
________________________________________
🚀 Siguiente Nivel (Arquitectura)
Ya que tú trabajas con:
•	Backend: Rails
•	Auth: Supabase
•	Frontend: React
Te recomiendo estructurarlo como:
•	public_pages
•	health_assessment
•	habits
•	plans
•	marketplace
•	ai_agent
•	tracking
