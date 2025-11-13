; Script de Inno Setup para CRES Carnets
; Versión 2.4.8 - Verificación exhaustiva + delay flush

#define MyAppName "CRES Carnets"
#define MyAppVersion "2.4.8"
#define MyAppPublisher "UAGRO"
#define MyAppExeName "cres_carnets_ibmcloud.exe"
#define MyAppId "{{8B5E5F7C-9D4A-4E2B-8C3F-1A2B3C4D5E6F}"

[Setup]
AppId={#MyAppId}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
; Instalar en LocalAppData (no requiere permisos admin)
DefaultDirName={localappdata}\{#MyAppName}
DisableProgramGroupPage=yes
AllowNoIcons=yes
OutputDir=..\releases\installers
OutputBaseFilename=CRES_Carnets_Setup_v{#MyAppVersion}
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
ArchitecturesInstallIn64BitMode=x64
; NO requiere permisos de administrador
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
UninstallDisplayIcon={app}\{#MyAppExeName}

; Icono del instalador (opcional)
; SetupIconFile=..\assets\icon.ico

[Languages]
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"

[Tasks]
Name: "desktopicon"; Description: "Crear icono en el escritorio"; GroupDescription: "Iconos adicionales:"
Name: "quicklaunchicon"; Description: "Crear icono en inicio rápido"; GroupDescription: "Iconos adicionales:"; Flags: unchecked

[Files]
; Copiar todos los archivos del build
Source: "..\releases\windows\cres_carnets_windows_20251013_145607\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
; Menú de inicio
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
; Escritorio (opcional)
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "Ejecutar {#MyAppName}"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
Type: filesandordirs; Name: "{app}"

[Code]
// Verificar si hay una versión anterior instalada
function InitializeSetup(): Boolean;
var
  OldVersion: String;
  Uninstaller: String;
  ResultCode: Integer;
begin
  Result := True;
  
  // Buscar versión anterior
  if RegQueryStringValue(HKLM, 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{#MyAppId}_is1', 
    'DisplayVersion', OldVersion) then
  begin
    // Hay una versión anterior instalada
    if MsgBox('Se detectó {#MyAppName} versión ' + OldVersion + ' instalada.' + #13#10 + 
              '¿Deseas desinstalarla antes de continuar?', 
              mbConfirmation, MB_YESNO) = IDYES then
    begin
      // Obtener ruta del desinstalador
      if RegQueryStringValue(HKLM, 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{#MyAppId}_is1',
        'UninstallString', Uninstaller) then
      begin
        // Ejecutar desinstalador en modo silencioso
        Exec(RemoveQuotes(Uninstaller), '/SILENT', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
        
        // Esperar un momento para que termine la desinstalación
        Sleep(2000);
      end;
    end;
  end;
end;

// Mostrar mensaje de éxito personalizado
procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
  begin
    // Aquí puedes agregar acciones post-instalación si es necesario
  end;
end;
