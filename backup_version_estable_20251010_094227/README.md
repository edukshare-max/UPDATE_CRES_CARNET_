
# CRES Carnets — Flutter + SQLite (Offline) + IBM Cloudant (Sync)

## Qué es
Software instalable (Windows/Android/Linux/macOS) con base local **SQLite** y sincronización a **IBM Cloudant** usando `_bulk_docs` (API CouchDB).

## Configuración rápida
1) Crea una instancia **Cloudant** en IBM Cloud. Desde el panel, crea la base **`cres_salud`**.
2) Genera una **API Key** (Service credentials). Copia:
   - `url`: `https://<ACCOUNT>.cloudantnosqldb.appdomain.cloud`
   - `apikey`: `bluemix-xxxxxx-xxxxxx`
3) Edita `lib/data/sync_cloudant.dart` y reemplaza:
```dart
const String kCloudantBaseUrl = 'https://<ACCOUNT>.cloudantnosqldb.appdomain.cloud';
const String kCloudantDbName = 'cres_salud';
const String kCloudantApiKey = '<API_KEY>';
```
4) Ejecuta la app:
```bash
flutter pub get
flutter run -d windows   # o android / macos / linux
```

## Cómo funciona el sync
- La app guarda localmente. Un ciclo cada 15s toma los pendientes (`synced=false`) y hace POST a `/{db}/_bulk_docs` en Cloudant con Basic Auth (`apikey:<API_KEY>`).
- Si Cloudant responde 2xx, marca los registros como `synced=true`.

## Ver tus datos
En Cloudant Dashboard, abre la base `cres_salud` y verás documentos tipo:
```json
{ "_id": "carnet:MATRICULA:123", "type": "registro", "nombre_completo": "...", ... }
```

## Notas de seguridad
- Compila la app para escritorio o Android (el API key irá embebido; si necesitas mayor seguridad, usa un proxy propio o IAM con tokens temporales).
- Usa HTTPS (Cloudant ya lo provee).

## Deployment Automatizado (Render)

### Configuración inicial
1) **Render Dashboard** → Activar **Blueprints** apuntando a este repositorio
2) **Crear secretos en Render**:
   - `COSMOS_ENDPOINT`: URL de Azure Cosmos DB
   - `COSMOS_KEY`: Clave primaria de Cosmos DB 
   - `RENDER_DEPLOY_HOOK`: URL del webhook de deploy del servicio

### Redeploy automático
```bash
# Desde GitHub → Actions → "Render Redeploy" → Run workflow
```

### Verificación post-deploy
```powershell
# 1. Diagnóstico
Invoke-RestMethod -Uri 'https://fastapi-backend-o7ks.onrender.com/_diag/citas'
# Esperado: {"db":"SASU","container":"citas_id","pk":"/id","can_read":true}

# 2. Crear cita de prueba
Invoke-RestMethod -Uri 'https://fastapi-backend-o7ks.onrender.com/citas' -Method POST -ContentType 'application/json' -Body '{"matricula":"2025","inicio":"2025-10-04T09:00:00Z","fin":"2025-10-04T09:30:00Z","motivo":"SEGUIMIENTO"}'

# 3. Listar citas por matrícula
Invoke-RestMethod -Uri 'https://fastapi-backend-o7ks.onrender.com/citas/por-matricula/2025?t=1'
```

**Logs esperados**: `APP_BOOT db=SASU container_citas=citas_id pk=/id`

**Azure Cosmos**: Verificar documentos en DB `SASU` → contenedor `citas_id`

## Extensiones
- Adjuntos: guarda archivos en IBM Cloud Object Storage y almacena las URLs en `expedienteAdjuntos`.
- Autenticación por departamento: añade campos y controla en Cloudant por base o separando por `type` y vistas.
