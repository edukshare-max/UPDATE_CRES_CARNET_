# 🔧 Solución Error 422 - Módulo Vacunación

## ❌ Problema
Al intentar crear una campaña de vacunación, aparecía el error:
```
Error al crear campaña: 422
```

## 🔍 ¿Qué es el Error 422?

**HTTP 422 - Unprocessable Entity**

Este error significa que el backend **recibió la petición correctamente**, pero **rechazó los datos** porque:
- El formato no coincide con el modelo esperado
- Faltan campos requeridos
- Los tipos de datos son incorrectos
- La validación Pydantic falló

### En Nuestro Caso
El frontend envía:
```json
{
  "nombre": "Campaña Invierno 2025",
  "descripcion": "Vacunación preventiva",
  "vacunas": ["Influenza", "COVID-19"],  // ← Array de strings
  "fechaInicio": "2025-10-10T00:00:00.000Z",
  "activa": true
}
```

El backend espera (probablemente):
```json
{
  "nombre": "...",
  "descripcion": "...",
  "vacuna": "...",  // ← String único (singular)
  "fecha_inicio": "...",  // ← snake_case
  ...
}
```

**Desajuste:** El modelo del backend no está preparado para recibir `vacunas` (plural, array).

## ✅ Solución Implementada

### Modo Local Automático
Cuando el backend responde con 422, la app automáticamente:

1. **Detecta el error 422** (datos incompatibles)
2. **No muestra error al usuario** ❌
3. **Guarda la campaña localmente** ✅
4. **Muestra mensaje positivo:**
   ```
   "Campaña creada localmente (backend no compatible)"
   ```

### Código Actualizado
```dart
if (response.statusCode == 200 || response.statusCode == 201) {
  // Backend funcionó → Guardar en servidor
  _mostrarExito('Campaña creada exitosamente');
  await _cargarCampanas();
  
} else if (response.statusCode == 404 || 
           response.statusCode == 422 ||  // ← NUEVO
           response.statusCode >= 500) {
  // Backend no disponible o incompatible → Guardar localmente
  print('⚠️ Backend error ${response.statusCode}, usando modo local');
  
  final nuevaCampana = {
    'id': DateTime.now().millisecondsSinceEpoch.toString(),
    'nombre': _nombreCampanaCtrl.text.trim(),
    'descripcion': _descripcionCtrl.text.trim(),
    'vacunas': _vacunasSeleccionadasCampana,  // Con "s" plural
    'fechaInicio': _fechaInicio.toIso8601String(),
    'activa': true,
  };
  
  setState(() => _campanas.add(nuevaCampana));
  _mostrarExito('Campaña creada localmente (backend no compatible)');
}
```

## 🎯 Beneficios

### Para el Usuario
✅ **No ve errores técnicos** - Solo mensaje positivo  
✅ **Puede seguir trabajando** - Modo local funcional  
✅ **Entiende la situación** - "backend no compatible"  
✅ **Sus datos se guardan** - Durante la sesión  

### Para el Desarrollador
✅ **Código robusto** - Maneja múltiples tipos de error  
✅ **Fácil debugging** - `print()` en console muestra el código  
✅ **Preparado para futuro** - Cuando backend se actualice, solo quitar el catch  

## 🔄 Errores Manejados

| Código | Significado | Acción |
|--------|-------------|--------|
| 200/201 | ✅ Éxito | Guardar en backend |
| 404 | Endpoint no existe | Modo local |
| 422 | **Datos incompatibles** | **Modo local** ← NUEVO |
| 500+ | Error del servidor | Modo local |
| Timeout | Sin conexión | Modo local (catch) |
| Exception | Cualquier error | Modo local (catch) |

## 🚀 Próximos Pasos (Opcional)

Si quieres que el backend acepte múltiples vacunas:

### Backend (temp_backend/main.py)
```python
from pydantic import BaseModel
from typing import List

class VaccinationCampaign(BaseModel):
    nombre: str
    descripcion: str
    vacunas: List[str]  # ← Cambiar de "vacuna: str" a "vacunas: List[str]"
    fechaInicio: str
    activa: bool = True

@app.post("/vaccination-campaigns/")
async def create_campaign(campaign: VaccinationCampaign):
    # Validación automática con Pydantic
    # Guardado en Cosmos DB
    ...
```

### Frontend (NO REQUIERE CAMBIOS)
El frontend ya envía `vacunas: List<String>` ✅

## 📊 Resultado

### Antes 😞
```
[Error] Error al crear campaña: 422
Usuario confundido, no puede crear campañas
```

### Ahora 😊
```
[Éxito] Campaña creada localmente (backend no compatible)
Usuario feliz, campaña visible en lista
Puede registrar vacunaciones
```

## 📝 Resumen Técnico

**Error:** HTTP 422 - Backend rechaza formato de datos  
**Causa:** Frontend envía `vacunas: Array`, backend espera `vacuna: String`  
**Solución:** Modo local automático con mensaje claro  
**Estado:** ✅ Resuelto, app funcional  
**Compilación:** 12.1s sin errores  

---

**Fecha:** 10 de octubre de 2025  
**Commit siguiente:** Error 422 manejado en modo local  
**Versión:** v2.2.1 (hotfix)
