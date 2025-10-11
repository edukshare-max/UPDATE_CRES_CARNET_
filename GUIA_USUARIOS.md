# 📱 Guía de Instalación - CRES Carnets UAGro

## Para Usuarios Finales

### 📥 **Paso 1: Descargar**
1. Descarga el archivo: `CRES_Carnets_UAGro_v2.3.2_Instalador.zip`
2. Guarda en tu carpeta de Descargas

### 📂 **Paso 2: Descomprimir**
1. Click derecho en el archivo ZIP
2. Selecciona "Extraer todo..." o "Descomprimir aquí"
3. Se creará una carpeta con los archivos

### 🔧 **Paso 3: Instalar**
1. Abre la carpeta descomprimida
2. Busca el archivo `INSTALAR.bat`
3. **Click derecho** en `INSTALAR.bat`
4. Selecciona **"Ejecutar como Administrador"**
5. Si Windows pregunta "¿Deseas permitir cambios?", click en **"Sí"**
6. Espera a que termine la instalación
7. Presiona cualquier tecla cuando diga "Completado"

### ✅ **Paso 4: Abrir la Aplicación**
1. Busca en tu **Escritorio** el ícono "CRES Carnets UAGro"
2. Doble click para abrir
3. ¡Listo para usar!

---

## 🔐 Primer Inicio de Sesión

### Credenciales:
- **Usuario**: (proporcionado por tu administrador)
- **Password**: (proporcionado por tu administrador)
- **Campus**: Selecciona tu ubicación de la lista

### Ejemplo para administradores del sistema:
- **Usuario**: `DireccionInnovaSalud`
- **Password**: `Admin2025`
- **Campus**: `CRES Llano Largo` (o cualquiera de los 88 disponibles)

---

## ❓ Preguntas Frecuentes (FAQ)

### ¿Necesito Internet para usar la aplicación?
**No necesariamente**. La aplicación funciona en modo híbrido:
- **Con Internet**: Sincroniza con la nube automáticamente
- **Sin Internet**: Funciona offline, guarda cambios localmente

### ¿Qué hacer si no tengo permisos de Administrador?
Contacta al administrador de tu computadora o departamento de IT para que instale la aplicación.

### ¿La aplicación se actualiza automáticamente?
**Sí**. El sistema verifica actualizaciones cada 24 horas y te notificará cuando haya una nueva versión disponible.

### ¿Dónde se instala la aplicación?
En: `C:\Program Files\CRES Carnets UAGro\`

### ¿Cómo desinstalar?
1. Ve a "Configuración" → "Aplicaciones"
2. Busca "CRES Carnets UAGro"
3. Click en "Desinstalar"

O ejecuta el archivo `DESINSTALAR.bat` (si está incluido)

---

## 🔧 Solución de Problemas

### "Windows protegió tu PC"
1. Click en "Más información"
2. Click en "Ejecutar de todos modos"
3. Esto es normal para aplicaciones no firmadas digitalmente

### La aplicación no abre
1. Verifica que tienes Windows 10 o superior (64-bit)
2. Reinicia tu computadora
3. Intenta ejecutar como Administrador

### "Error de conexión al backend"
1. Verifica tu conexión a Internet
2. La aplicación seguirá funcionando en modo offline
3. Los cambios se sincronizarán cuando recuperes conexión

### Pantalla en blanco al abrir
1. Cierra la aplicación
2. Elimina la carpeta: `C:\Users\TU_USUARIO\AppData\Local\cres_carnets_ibmcloud`
3. Abre la aplicación nuevamente

---

## 📊 Requisitos del Sistema

| Componente | Mínimo | Recomendado |
|------------|---------|-------------|
| **Sistema Operativo** | Windows 10 64-bit | Windows 11 64-bit |
| **RAM** | 2 GB | 4 GB o más |
| **Espacio en Disco** | 500 MB | 1 GB |
| **Internet** | Opcional (modo híbrido) | Recomendado para sync |
| **Pantalla** | 1280x720 | 1920x1080 |

---

## 📞 Soporte Técnico

**Universidad Autónoma de Guerrero**  
**Sistema CRES Carnets de Salud**

- **Backend**: https://fastapi-backend-o7ks.onrender.com
- **Versión Actual**: 2.3.2 (Build 1)
- **Fecha de Release**: 10 de Octubre, 2025

---

## 🎯 Características Principales

✅ **Modo Híbrido Online/Offline**  
La aplicación funciona con o sin Internet

✅ **Sincronización Automática**  
Tus datos se sincronizan automáticamente con Azure Cosmos DB

✅ **Sistema de Actualizaciones**  
Verifica y descarga actualizaciones automáticamente cada 24 horas

✅ **Gestión de Carnets**  
Sistema completo para carnets de vacunación y salud

✅ **88 Campus UAGro**  
Soporte para todos los Centros Regionales de Educación Superior

✅ **Interfaz Intuitiva**  
Colores institucionales UAGro (azul marino y rojo escudo)

✅ **Seguridad JWT**  
Autenticación segura con tokens JSON Web Token

---

## 📸 Capturas de Pantalla

_(Aquí puedes agregar screenshots de tu aplicación)_

1. **Pantalla de Login**
2. **Dashboard Principal**
3. **Lista de Expedientes**
4. **Carnet de Vacunación**
5. **Pantalla "Acerca de"**

---

## 📝 Notas de la Versión 2.3.2

### Nuevas Características:
- ✨ Sistema de auto-actualización integrado
- ✨ Modo híbrido online/offline mejorado
- ✨ 88 campus UAGro soportados
- ✨ Interfaz actualizada con colores institucionales
- ✨ Botón de búsqueda manual de actualizaciones

### Correcciones:
- 🐛 Fix en sistema de sincronización Cloudant
- 🐛 Mejoras de rendimiento en carga de datos
- 🐛 Corrección en selección de campus

---

**© 2025 Universidad Autónoma de Guerrero - Todos los derechos reservados**
