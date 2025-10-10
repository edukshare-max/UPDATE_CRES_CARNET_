# 🏥 Configuración del Contenedor de Vacunación en Cosmos DB

## 📦 Nuevo Contenedor: `tarjeta_vacunacion`

### Estructura del Contenedor
- **Nombre:** `tarjeta_vacunacion`
- **Partition Key:** `/matricula`
- **Propósito:** Almacenar el historial de vacunación de cada estudiante

### Documento Tipo
```json
{
  "id": "vacuna_202012345_1728547200000",
  "matricula": "202012345",  // ← Partition key
  "nombreEstudiante": "Juan Pérez González",
  "campana": "Campaña Influenza 2025",
  "vacuna": "Influenza (Gripe)",
  "dosis": 1,
  "lote": "ABC123",
  "aplicadoPor": "Dra. María López",
  "fechaAplicacion": "2025-10-10T10:30:00.000Z",
  "observaciones": "Sin reacciones adversas",
  "timestamp": "2025-10-10T10:30:15.000Z",
  "tipo": "aplicacion_vacuna"
}
```

## 🚀 Pasos para Configurar

### 1. Crear Contenedor en Azure Portal

```bash
1. Ve a Azure Portal → Tu cuenta de Cosmos DB
2. Selecciona la base de datos SASU
3. Click en "New Container"
4. Configuración:
   - Container ID: tarjeta_vacunacion
   - Partition key: /matricula
   - Throughput: 400 RU/s (compartido con la DB)
5. Click "OK"
```

### 2. Agregar Variable de Entorno en Render.com

**Opción A: En el Dashboard de Render**
```
1. Ve a https://dashboard.render.com
2. Selecciona tu servicio: fastapi-backend-o7ks
3. Ve a "Environment"
4. Agregar nueva variable:
   - Key: COSMOS_CONTAINER_VACUNACION
   - Value: tarjeta_vacunacion
5. Click "Save Changes"
6. Render redeplegará automáticamente
```

**Opción B: Actualizar render.yaml (opcional)**
```yaml
services:
  - type: web
    name: fastapi-backend-o7ks
    env: python
    envVars:
      # ... variables existentes ...
      - key: COSMOS_CONTAINER_VACUNACION
        value: "tarjeta_vacunacion"
```

### 3. Para Desarrollo Local

Crear archivo `.env` en `temp_backend/`:
```env
COSMOS_ENDPOINT=https://tu-cuenta.documents.azure.com:443/
COSMOS_KEY=tu-key-primaria-o-secundaria
COSMOS_DB=SASU
COSMOS_CONTAINER_CARNETS=carnets
COSMOS_CONTAINER_NOTAS=notas
COSMOS_CONTAINER_CITAS=citas_id
COSMOS_CONTAINER_VACUNACION=tarjeta_vacunacion
COSMOS_CONTAINER_PROMOCIONES_SALUD=promociones_salud
COSMOS_CONTAINER_USUARIOS=usuarios
COSMOS_CONTAINER_AUDITORIA=auditoria
```

## 📡 Endpoints Disponibles

### POST /carnet/{matricula}/vacunacion
Registra una aplicación de vacuna.

**Request:**
```json
{
  "matricula": "202012345",
  "nombreEstudiante": "Juan Pérez",
  "campana": "Campaña Influenza 2025",
  "vacuna": "Influenza (Gripe)",
  "dosis": 1,
  "lote": "ABC123",
  "aplicadoPor": "Dra. María López",
  "fechaAplicacion": "2025-10-10T10:30:00.000Z",
  "observaciones": "Sin reacciones"
}
```

**Response:**
```json
{
  "message": "Vacunación registrada exitosamente",
  "id": "vacuna_202012345_1728547200000",
  "matricula": "202012345"
}
```

### GET /carnet/{matricula}/vacunacion
Obtiene el historial completo de vacunación de un estudiante.

**Response:**
```json
[
  {
    "id": "vacuna_202012345_1728547200000",
    "matricula": "202012345",
    "vacuna": "Influenza (Gripe)",
    "dosis": 1,
    "fechaAplicacion": "2025-10-10T10:30:00.000Z",
    ...
  },
  {
    "id": "vacuna_202012345_1728547800000",
    "matricula": "202012345",
    "vacuna": "COVID-19",
    "dosis": 1,
    "fechaAplicacion": "2025-09-15T11:00:00.000Z",
    ...
  }
]
```

### GET /vacunacion/estadisticas
Estadísticas globales de vacunación.

**Response:**
```json
{
  "totalAplicaciones": 450,
  "estudiantesVacunados": 320,
  "porVacuna": {
    "Influenza (Gripe)": 150,
    "COVID-19": 200,
    "Hepatitis B": 100
  },
  "porCampana": {
    "Campaña Influenza 2025": 150,
    "Campaña COVID Otoño": 200,
    "Campaña Hepatitis": 100
  }
}
```

## 🔄 Flujo de Sincronización

### Con Internet (Modo Online)
```
Usuario registra vacuna
         ↓
App llama ApiService.guardarAplicacionVacuna()
         ↓
POST /carnet/202012345/vacunacion
         ↓
Backend guarda en Cosmos DB (tarjeta_vacunacion)
         ↓
✅ Response 201 Created
         ↓
App muestra: "Vacunación registrada en expediente"
```

### Sin Internet (Modo Offline)
```
Usuario registra vacuna
         ↓
App llama ApiService.guardarAplicacionVacuna()
         ↓
Error de conexión / timeout
         ↓
App guarda en SQLite local (tabla vacunaciones_pendientes)
         ↓
💾 App muestra: "Guardada localmente - se sincronizará cuando haya conexión"
         ↓
Usuario recupera internet
         ↓
App detecta conexión (al abrir vacunación o manualmente)
         ↓
Llama syncVacunacionesPendientes()
         ↓
Por cada registro pendiente:
  - POST /carnet/{matricula}/vacunacion
  - Si éxito: marca como synced en SQLite
         ↓
🔄 App muestra: "X vacunaciones sincronizadas"
```

## 📊 Beneficios del Contenedor Dedicado

### ✅ Ventajas

1. **Partition Key por Estudiante**
   - Consultas ultra-rápidas por matrícula
   - Escalabilidad óptima
   - RU's eficientes

2. **Historial Completo**
   - Todas las vacunas del estudiante en un solo lugar
   - Fácil de consultar para tarjeta digital
   - Ordenado por fecha

3. **Separación de Responsabilidades**
   - No mezcla con carnets o notas
   - Esquema limpio y específico
   - Fácil de mantener

4. **Estadísticas Globales**
   - Análisis de cobertura de vacunación
   - Reportes por vacuna/campaña
   - Toma de decisiones informada

### 📈 Consultas Optimizadas

**Por estudiante (ultra-rápido - usa partition key):**
```sql
SELECT * FROM c 
WHERE c.matricula = '202012345' 
AND c.tipo = 'aplicacion_vacuna' 
ORDER BY c.fechaAplicacion DESC
```

**Por vacuna (cross-partition):**
```sql
SELECT c.matricula, c.nombreEstudiante, c.fechaAplicacion 
FROM c 
WHERE c.vacuna = 'Influenza (Gripe)' 
AND c.tipo = 'aplicacion_vacuna'
```

**Estudiantes sin vacunar (join con carnets):**
```sql
-- Requiere lógica en backend para comparar
-- carnets vs tarjeta_vacunacion
```

## 🔐 Seguridad y Privacidad

- ✅ Partition key por matrícula (aislamiento)
- ✅ Solo el estudiante ve su historial
- ✅ Personal médico autorizado puede consultar
- ✅ Auditoría de accesos (usar sistema de auth JWT)
- ✅ No expone datos sensibles en endpoints públicos

## 🧪 Testing

### Probar Endpoint con curl
```bash
# Guardar vacunación
curl -X POST "https://fastapi-backend-o7ks.onrender.com/carnet/202012345/vacunacion" \
  -H "Content-Type: application/json" \
  -d '{
    "matricula": "202012345",
    "nombreEstudiante": "Juan Pérez",
    "campana": "Prueba",
    "vacuna": "Influenza",
    "dosis": 1,
    "fechaAplicacion": "2025-10-10T10:00:00Z"
  }'

# Obtener historial
curl "https://fastapi-backend-o7ks.onrender.com/carnet/202012345/vacunacion"

# Estadísticas
curl "https://fastapi-backend-o7ks.onrender.com/vacunacion/estadisticas"
```

### Probar desde la App
```
1. Registrar vacunación (sin conexión)
   → Se guarda en SQLite local
   → Badge rojo con número aparece en toolbar

2. Recuperar conexión

3. Click en botón de sincronización (☁️ con badge)
   → Sincroniza todas las pendientes
   → Badge desaparece
   → Snackbar: "X vacunaciones sincronizadas"

4. Abrir vacunación nuevamente
   → Intenta sincronizar automáticamente al inicio
```

---

**Fecha:** 10 de octubre de 2025  
**Estado:** ✅ Backend actualizado, endpoints listos  
**Pendiente:** Crear contenedor en Azure + agregar variable de entorno en Render  
**Versión:** v2.3.0-vaccination-sync
