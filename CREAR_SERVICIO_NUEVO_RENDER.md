# Crear Servicio Nuevo en Render

## 🚨 Situación
El servicio `fastapi-backend-o7ks` tiene un bug irrecuperable donde está atascado con código viejo. Después de 8+ deploys, Clear Cache, y Suspend+Resume, sigue sin actualizar.

## ✅ Solución: Crear Servicio Nuevo

### Paso 1: Anotar Variables de Entorno Actuales

Antes de nada, **copia TODAS las environment variables** del servicio viejo:

1. Dashboard → `fastapi-backend-o7ks` → **Environment**
2. **Copia cada variable** (nombre y valor):
   - `COSMOS_ENDPOINT`
   - `COSMOS_KEY`
   - `COSMOS_DATABASE_NAME`
   - `COSMOS_CONTAINER_NAME`
   - Y todas las demás...

### Paso 2: Crear Servicio Nuevo

1. Dashboard → **New +** → **Web Service**

2. **Connect Repository**:
   - Busca: `edukshare-max/fastapi-backend`
   - Branch: `main`

3. **Configuración Básica**:
   - **Name**: `fastapi-backend-new` (o el nombre que prefieras)
   - **Region**: Same as current (USA East o el que tengas)
   - **Branch**: `main`
   - **Root Directory**: (DEJAR VACÍO)
   - **Runtime**: `Python 3`

4. **Build & Deploy**:
   - **Build Command**: (DEJAR VACÍO - usa requirements.txt automático)
   - **Start Command**: `gunicorn -k uvicorn.workers.UvicornWorker main:app`

5. **Plan**: Selecciona el mismo plan pagado que tienes

6. **Environment Variables**:
   - Click **Add Environment Variable**
   - Agrega TODAS las variables que copiaste en Paso 1

7. **Create Web Service**

### Paso 3: Verificar Deploy

Espera 2-3 minutos. Ve a **Logs** y DEBES VER:

```
🚀 FASTAPI STARTING - Version check for /carnet/search endpoint
   Git commit: 32039f3
```

### Paso 4: Probar Endpoints

```powershell
# Probar health
Invoke-RestMethod -Uri "https://TU-NUEVO-SERVICIO.onrender.com/health"

# Probar /carnet/search (DEBE FUNCIONAR)
Invoke-WebRequest -Uri "https://TU-NUEVO-SERVICIO.onrender.com/carnet/search?nombre=test"
```

### Paso 5: Actualizar Cliente

Si el servicio nuevo funciona, actualiza la URL en el cliente:

**Archivo**: `lib/data/api_service.dart`

```dart
// Cambiar de:
static const String baseUrl = 'https://fastapi-backend-o7ks.onrender.com';

// A:
static const String baseUrl = 'https://TU-NUEVO-SERVICIO.onrender.com';
```

Recompila v2.4.33 y distribuye.

### Paso 6: Eliminar Servicio Viejo

Una vez que el nuevo funciona y lo has probado:

1. Dashboard → `fastapi-backend-o7ks` → **Settings**
2. Scroll al final → **Delete Service**
3. Confirma

## 🎯 Por Qué Esto Va a Funcionar

- Servicio nuevo = Sin cache corrupto
- Parte desde cero con el commit correcto de GitHub
- No hereda ningún problema del servicio viejo

## ⚠️ Importante

- Guarda bien todas las environment variables ANTES de crear el nuevo
- Prueba el nuevo ANTES de borrar el viejo
- Actualiza la URL en el cliente solo cuando confirmes que funciona
