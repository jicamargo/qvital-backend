# Autenticación con Supabase - Especificación Técnica

## 📋 Flujo de Autenticación

```
Supabase Auth → Frontend obtiene JWT → Backend valida JWT → Backend sincroniza usuario
```

### Objetivo
Implementar sincronización de usuarios entre Supabase Auth y la base de datos Rails, permitiendo que el backend mantenga un registro local de usuarios con sus niveles y roles.

### ⚠️ Importante: Algoritmo de Validación

**Supabase usa ECC (P-256) con algoritmo ES256** (firma asimétrica), NO HS256 (legacy).

- ✅ **Actual**: ECC (P-256) → Algoritmo ES256
- ❌ **Legacy**: HS256 (Shared Secret) → NO usar

**Validación mediante JWKS (JSON Web Key Set)**, no con secret compartido.

---

## 🔧 BACKEND (Rails API)

### Configuración Inicial

- [ ] **Variables de Entorno**
  - [X] Agregar `SUPABASE_URL` al `.env`
  - [X] Formato: `SUPABASE_URL=https://TU_PROJECT_ID.supabase.co`
  - [X] Agregar `SUPABASE_SERVICE_ROLE_KEY` al `.env` (para actualizar metadata de usuarios)
  - [X] Formato: `SUPABASE_SERVICE_ROLE_KEY=eyJhbGc...` (obtener desde Supabase Dashboard → Settings → API → service_role key)
  - [X] **NO** usar `SUPABASE_JWT_SECRET` (legacy)
  - [X] **NO** guardar private keys
  - [X] Verificar que el proyecto use ECC (P-256) en Supabase Dashboard
  - [X] **IMPORTANTE**: `SUPABASE_SERVICE_ROLE_KEY` solo debe usarse en el backend, NUNCA en el frontend

- [X] **Dependencias**
  - [X] Agregar gem `jwt`: `bundle add jwt`
  - [X] Agregar gem `net-http`: `bundle add net-http` (ya incluida en Ruby estándar)
  - [X] Ejecutar `bundle install`

### Implementación

- [X] **Controlador de Autenticación**
  - [X] Generar controlador: `rails generate controller api/v1/auth --skip-routes`
  - [X] Crear archivo: `app/controllers/api/v1/auth_controller.rb`
  - [X] Implementar método `fetch_jwks` para obtener claves públicas (en interactor)
  - [X] Implementar método `sync` con validación JWT usando JWKS
  - [X] Usar algoritmo ES256 (no HS256)
  - [X] Manejar errores de decodificación JWT
  - [X] Implementar lógica de creación/actualización de usuario

- [X] **Interactor**
  - [X] Crear `app/interactors/auth/sync_user.rb`
  - [X] Mover lógica de negocio del controlador al interactor
  - [X] Implementar validación de token
  - [X] Implementar sincronización de usuario
  - [X] Manejar asignación de nivel por defecto

- [X] **Rutas**
  - [X] Agregar namespace `api/v1` en `config/routes.rb`
  - [X] Definir ruta: `POST /api/v1/auth/sync`
  - [X] Configurar formato JSON por defecto (API only mode)

- [X] **Modelo User**
  - [X] Verificar método `find_or_initialize_by(supabase_uid:)` (método estándar de ActiveRecord)
  - [X] Verificar relación con `Level` (belongs_to :level, optional: true)
  - [X] Verificar validaciones de `email` y `supabase_uid` (presentes y únicos)

- [X] **Modelo Level**
  - [X] Verificar existencia de nivel "Cliente" en seeds
  - [X] Verificar método `find_by(name: "Cliente")` (método estándar de ActiveRecord)

### Endpoint: POST /api/v1/auth/sync

**Request:**
```http
POST /api/v1/auth/sync
Authorization: Bearer <jwt_token>
Content-Type: application/json
```

**Response (200 OK):**
```json
{
  "user": {
    "id": 1,
    "email": "usuario@example.com",
    "supabase_uid": "uuid-from-supabase",
    "role": "cliente",
    "level_id": 1,
    "level": {
      "id": 1,
      "name": "Cliente",
      "priority": 1
    }
  }
}
```

**Response (401 Unauthorized):**
```json
{
  "error": "No token" | "Invalid token"
}
```

### Lógica de Sincronización

1. Extraer token del header `Authorization`
2. Obtener JWKS desde `{SUPABASE_URL}/auth/v1/.well-known/jwks.json`
3. Validar y decodificar JWT usando JWKS con algoritmo ES256
4. Extraer del payload:
   - `sub` → `supabase_uid`
   - `email` → `email`
5. Buscar usuario por `supabase_uid`
6. Si no existe:
   - Crear nuevo usuario
   - Asignar nivel "Cliente" (default)
   - Asignar rol "cliente"
7. Si existe:
   - Actualizar email si cambió
8. **Actualizar `app_metadata` en Supabase** con el `role` del usuario de Rails
9. Retornar usuario con relaciones

### Sincronización de Role con Supabase Metadata

**Objetivo**: Hacer que el `role` del usuario en Rails esté disponible en el JWT de Supabase cuando el frontend usa `supabase.auth.getUser()`.

**Problema**: Si el frontend consulta directamente `supabase.auth.getUser()`, el JWT no incluirá el `role` de Rails a menos que lo actualicemos en Supabase.

**Solución**:
- Interactor `Auth::UpdateSupabaseMetadata` actualiza `app_metadata.role` en Supabase usando la API Admin
- Se llama automáticamente después de sincronizar el usuario en `Auth::SyncUser`
- Se llama automáticamente cuando el `role` cambia en el modelo `User` (callback `after_update`)

**Requisitos**:
- Variable de entorno `SUPABASE_SERVICE_ROLE_KEY` configurada
- Esta key solo debe usarse en el backend, nunca en el frontend

**Resultado**:
Cuando el frontend llama `supabase.auth.getUser()`, el objeto retornado incluirá:
```json
{
  "user": {
    "app_metadata": {
      "role": "admin"  // o "cliente" según el role en Rails
    }
  }
}
```

**Uso en Policies de Supabase**:
Una vez sincronizado, el JWT incluirá `app_metadata.role` y se puede usar en policies:
```sql
auth.jwt() -> 'app_metadata' ->> 'role' = 'admin'
```

### Código de Referencia

```ruby
# app/controllers/api/v1/auth_controller.rb
require 'jwt'
require 'net/http'
require 'json'

class Api::V1::AuthController < ApplicationController
  def sync
    token = extract_token
    return render_unauthorized('No token') unless token

    begin
      jwks = fetch_jwks

      decoded = JWT.decode(
        token,
        nil, # No se usa secret, se usa JWKS
        true, # Verificar firma
        algorithms: ['ES256'], # Algoritmo ECC P-256
        jwks: jwks
      )

      payload = decoded.first

      user = User.find_or_initialize_by(supabase_uid: payload["sub"])
      user.email = payload["email"]

      if user.new_record?
        default_level = Level.find_by(name: "Cliente")
        user.level = default_level
        user.role = "cliente"
      end

      user.save!

      render json: { user: user }, status: :ok

    rescue JWT::DecodeError => e
      render json: { error: e.message }, status: :unauthorized
    rescue StandardError => e
      render json: { error: 'Internal server error' }, status: :internal_server_error
    end
  end

  private

  def fetch_jwks
    url = URI("#{ENV['SUPABASE_URL']}/auth/v1/.well-known/jwks.json")
    response = Net::HTTP.get(url)
    JSON.parse(response)
  end

  def extract_token
    request.headers['Authorization']&.split(' ')&.last
  end

  def render_unauthorized(message)
    render json: { error: message }, status: :unauthorized
  end
end
```

### 🔍 Explicación del Código

**JWKS (JSON Web Key Set):**
- Supabase firma tokens con clave privada (ECC P-256)
- Las claves públicas están disponibles en el endpoint `.well-known/jwks.json`
- El gem `jwt` usa estas claves públicas para validar la firma

**Algoritmo ES256:**
- ECC (P-256) usa el algoritmo ES256 (Elliptic Curve Signature)
- Es más seguro que HS256 (simétrico)
- Es el estándar moderno de Supabase

---

## 🎨 FRONTEND (Next.js / React)

### Configuración Inicial

- [x] **Cliente Supabase**
  - [x] Configurar cliente de Supabase en el proyecto
  - [x] Verificar variables de entorno: `NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_ANON_KEY`
  - [x] Configurar instancia de `createClient()`

- [x] **Servicio de Autenticación**
  - [x] Crear servicio/hook para autenticación
  - [x] Implementar función para obtener token de sesión
  - [x] Implementar función para sincronizar con backend

### Implementación

- [x] **Hook de Autenticación**
  - [x] Crear `hooks/useAuth.ts` o similar
  - [x] Implementar función `syncUserWithBackend()`
  - [x] Manejar estados de carga y error
  - [x] Almacenar usuario en contexto/estado global

- [x] **Integración con Supabase Auth**
  - [x] Implementar login/signup con Supabase
  - [x] Obtener sesión después de autenticación exitosa
  - [x] Extraer `access_token` de la sesión
  - [x] Llamar a endpoint de sincronización

- [x] **Manejo de Respuestas**
  - [x] Procesar respuesta del backend
  - [x] Almacenar datos de usuario en estado
  - [x] Manejar errores de autenticación
  - [x] Redirigir según estado de autenticación

### Flujo de Usuario

1. Usuario hace login/signup con Supabase
2. Supabase retorna sesión con `access_token`
3. Frontend extrae token de la sesión
4. Frontend llama a `POST /api/v1/auth/sync` con token
5. Backend valida, sincroniza y retorna usuario
6. Frontend almacena usuario en estado/contexto
7. Usuario puede acceder a rutas protegidas

### Código de Referencia

```typescript
// hooks/useAuth.ts
import { createClient } from '@supabase/supabase-js'

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
)

export async function syncUserWithBackend() {
  try {
    // Obtener sesión actual
    const { data: { session }, error: sessionError } = await supabase.auth.getSession()
    
    if (sessionError || !session) {
      throw new Error('No active session')
    }

    const token = session.access_token

    // Sincronizar con backend
    const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/v1/auth/sync`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`
      }
    })

    if (!response.ok) {
      const error = await response.json()
      throw new Error(error.error || 'Sync failed')
    }

    const { user } = await response.json()
    return user
  } catch (error) {
    console.error('Error syncing user:', error)
    throw error
  }
}

// Uso en componente
useEffect(() => {
  const syncUser = async () => {
    try {
      const user = await syncUserWithBackend()
      setUser(user)
    } catch (error) {
      // Manejar error
    }
  }
  
  syncUser()
}, [])
```

---

## ✅ Casos de Uso

### Caso 1: Usuario Nuevo (Primera Vez)
1. Usuario se registra en Supabase
2. Supabase crea usuario en su sistema
3. Frontend obtiene token JWT
4. Frontend llama a `/api/v1/auth/sync`
5. Backend crea usuario en Rails
6. Backend asigna nivel "Cliente" por defecto
7. Backend retorna usuario completo

### Caso 2: Usuario Existente
1. Usuario hace login en Supabase
2. Supabase valida credenciales
3. Frontend obtiene token JWT
4. Frontend llama a `/api/v1/auth/sync`
5. Backend encuentra usuario por `supabase_uid`
6. Backend actualiza email si cambió
7. Backend retorna usuario existente

### Caso 3: Token Inválido
1. Frontend envía token inválido/expirado
2. Backend intenta decodificar JWT
3. Backend detecta error de decodificación
4. Backend retorna 401 Unauthorized
5. Frontend redirige a login

---

## 🎯 Próximos Pasos (Post-Implementación)

- [ ] Crear endpoint `GET /api/v1/auth/me` para obtener usuario actual
- [ ] Implementar middleware de autenticación para proteger rutas
- [ ] Crear sistema de autorización basado en roles
- [ ] Implementar refresh token si es necesario
- [ ] Agregar logging de eventos de autenticación
- [ ] Implementar rate limiting en endpoint de sync

---

## 📝 Notas Técnicas

### 🔄 Migración de HS256 a ES256

**¿Por qué cambiar?**

Supabase migró de HS256 (simétrico) a ES256 (asimétrico) por razones de seguridad:

| Aspecto | HS256 (Legacy) | ES256 (Actual) |
|---------|----------------|----------------|
| Tipo | Simétrico (mismo secret) | Asimétrico (clave pública/privada) |
| Seguridad | Menor (secret compartido) | Mayor (firma criptográfica) |
| Validación | Requiere secret en backend | Usa JWKS público |
| Estándar | Legacy | Moderno (RFC 7518) |

**Recomendación para QVITAL:**
- ✅ **Usar ES256** (sistema actual de Supabase)
- ❌ **NO regresar a HS256** (tecnología obsoleta)
- ❌ **NO usar Legacy JWT Secret**

### Principios de Diseño

- **Controllers Minimalistas**: Los controladores solo deben orquestar, la lógica va en interactors/services
- **Lógica en Interactors**: Usar interactors para encapsular lógica de negocio
- **DRY (Don't Repeat Yourself)**: Evitar duplicación de código
- **SOLID**: Aplicar principios SOLID en la arquitectura
- **Desacoplado**: Separar responsabilidades entre capas

### Consideraciones de Seguridad

- ✅ **Usar ES256 con JWKS** (sistema moderno de Supabase)
- ❌ **NO usar HS256 Legacy** (tecnología obsoleta)
- ❌ **NO guardar JWT Secret** en variables de entorno
- ✅ Validar siempre el JWT antes de procesar
- ✅ No confiar en datos del cliente sin validar
- ✅ Usar HTTPS en producción
- ✅ Implementar rate limiting
- ✅ Loggear intentos de autenticación fallidos
- ✅ Cachear JWKS para mejorar performance (opcional)

### 🔐 Configuración de Supabase

**Verificar en Supabase Dashboard:**
- Settings → API → Verificar que aparezca:
  - ✅ **Current key → ECC (P-256)**
  - 🔁 **Previous key → Legacy HS256** (no usar)

**Endpoint JWKS:**
```
https://TU_PROJECT_ID.supabase.co/auth/v1/.well-known/jwks.json
```

Este endpoint es público y seguro, contiene solo claves públicas.

### Testing

- [ ] Tests unitarios para interactor de sincronización
- [ ] Tests de integración para endpoint `/api/v1/auth/sync`
- [ ] Tests de casos edge (token inválido, usuario nuevo, usuario existente)
- [ ] Tests de frontend para flujo de autenticación completo
