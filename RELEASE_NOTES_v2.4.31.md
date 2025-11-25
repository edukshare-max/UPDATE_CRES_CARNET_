# CRES Carnets v2.4.31 - Búsqueda en Administrar Expedientes

**Fecha de lanzamiento**: 24 de noviembre de 2025

## 🎯 Nueva Funcionalidad

### Búsqueda en Página "Administrar Expedientes"

Ahora puedes buscar expedientes directamente desde la página de listado:

- ✅ **Búsqueda por matrícula**: Escribe números como `2021001`
- ✅ **Búsqueda por nombre**: Escribe texto como `Juan Pérez` o `María`
- ✅ **Búsqueda parcial**: Escribe solo parte del nombre (ej: `Juan`)
- ✅ **No distingue mayúsculas/minúsculas**: `JUAN` = `juan` = `Juan`
- ✅ **Filtrado en tiempo real**: Los resultados aparecen mientras escribes
- ✅ **Botón para limpiar**: Icono ❌ para borrar rápidamente la búsqueda

## 📦 Información del Paquete

- **Archivo**: `CRES_Carnets_Windows_v2.4.31.zip`
- **Tamaño**: 15.87 MB
- **Versión anterior**: 2.4.30
- **Build number**: 31

## 🔧 Cambios Técnicos

### Frontend (lib/screens/list_screen.dart)
- Convertido de StatelessWidget a StatefulWidget
- Agregado TextEditingController para el campo de búsqueda
- Implementado método `_filterRecords()` para filtrado local
- Campo de búsqueda con diseño responsivo (móvil/desktop)

### Backend (temp_backend/main.py)
- Endpoint `/carnet/search` desplegado en producción
- Query Cosmos DB con CONTAINS() case-insensitive
- Filtros para excluir citas y documentos con rangos de fechas

## 📥 Instalación

1. **Descargar**: `CRES_Carnets_Windows_v2.4.31.zip`
2. **Extraer**: Descomprimir en cualquier carpeta
3. **Ejecutar**: Doble clic en `cres_carnets_ibmcloud.exe`

O si tienes v2.4.30 instalada, la app detectará la actualización automáticamente.

## ✅ Verificación

Para confirmar que tienes la versión correcta:
1. Abre la aplicación
2. Ve a **Administrar Expedientes**
3. Deberías ver un campo de búsqueda con el texto: "Buscar por matrícula o nombre"

## 🐛 Solución de Problemas

**"No aparece el campo de búsqueda"**
- Verifica que estás en la página "Administrar Expedientes" (no en "Nueva Nota")
- Reinicia la aplicación

**"La búsqueda no encuentra resultados"**
- Verifica que existen expedientes con ese nombre/matrícula
- Intenta con búsqueda parcial (solo parte del nombre)

## 📞 Soporte

Si encuentras algún problema, reporta:
- Versión de la app (debe decir 2.4.31)
- Descripción del problema
- Pasos para reproducirlo
