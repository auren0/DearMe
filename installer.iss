; Inno Setup Script for DearMe
; Production Windows x64 Installer
;
; Build the Windows release bundle first:
;   flutter build windows --release
;
; Compile the installer with Inno Setup:
;   iscc installer.iss
;
; Result:
;   dist\DearMe-Setup.exe

#define MyAppName "DearMe"
#define MyAppVersion "1.2.0"
#define MyAppPublisher "DearMe"
#define MyAppExeName "DearMe.exe"
#define MyAppId "{{657A7471-C795-44B9-B9F9-5CCFA05E8746}"
#define MyAppAumid "DearMe.App"
#define MyAppToastClsid "F7D9A3C2-6C1E-4D7A-9F2B-8E4A1C5B7D30"
#define BuildDir "build\windows\x64\runner\Release"
#define OutputDir "dist"
#define AppIcon "windows\runner\resources\app_icon.ico"

[Setup]
; Persistent application identity for clean upgrades and seamless uninstall
AppId={#MyAppId}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppComments=Letters to your future self
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
DisableDirPage=no

; Minimum supported OS: Windows 10 (version 10.0) 64-bit
MinVersion=10.0
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

; Per-user installation by default without requiring administrator privileges,
; with elevation dialog option if all-users installation is desired
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog

; Output executable configuration
OutputDir={#OutputDir}
OutputBaseFilename=DearMe-Setup
SetupIconFile={#AppIcon}
UninstallDisplayIcon={app}\{#MyAppExeName}
UninstallDisplayName={#MyAppName}

; Compression: LZMA2 solid compression for minimal distribution size
Compression=lzma2/max
SolidCompression=yes
LZMAUseSeparateProcess=yes

; Visual styling
WizardStyle=modern

; Safe update handling: close running instances via Windows Restart Manager
CloseApplications=yes
CloseApplicationsFilter=*.exe,*.dll
RestartApplications=no

; Upgrade preservation: maintain previous user directory, language and settings
UsePreviousAppDir=yes
UsePreviousLanguage=yes
UsePreviousPrivileges=yes
UsePreviousTasks=yes

[Languages]
; Russian is default, English is secondary
Name: "russian"; MessagesFile: "compiler:Languages\Russian.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[CustomMessages]
russian.CreateDesktopIcon=Создать ярлык на Рабочем столе
english.CreateDesktopIcon=Create a desktop shortcut
russian.AdditionalIcons=Дополнительные значки:
english.AdditionalIcons=Additional shortcuts:
russian.LaunchProgram=Запустить DearMe
english.LaunchProgram=Launch DearMe

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[InstallDelete]
; Clean up any legacy lowercase executable if updating from older builds
Type: files; Name: "{app}\dearme.exe"

[Files]
; Main Flutter runner executable
Source: "{#BuildDir}\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion
; Dynamic libraries (Flutter engine and plugins)
Source: "{#BuildDir}\*.dll"; DestDir: "{app}"; Flags: ignoreversion
; Native assets configuration (if present in build)
Source: "{#BuildDir}\native_assets.json"; DestDir: "{app}"; Flags: ignoreversion skipifsourcedoesntexist
; Application data, fonts, shaders, and assets
Source: "{#BuildDir}\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs
; Note: User database and preferences in %APPDATA% / %LOCALAPPDATA% are strictly untouched

[Icons]
; Start Menu shortcut with Toast notification registration
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; WorkingDir: "{app}"; Comment: "Letters to your future self"; AppUserModelID: "{#MyAppAumid}"; AppUserModelToastActivatorCLSID: "{#MyAppToastClsid}"
; Desktop shortcut (optional task)
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; WorkingDir: "{app}"; Comment: "Letters to your future self"; Tasks: desktopicon; AppUserModelID: "{#MyAppAumid}"; AppUserModelToastActivatorCLSID: "{#MyAppToastClsid}"

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram}"; Flags: nowait postinstall skipifsilent

[Code]
// Gracefully request running instances of DearMe to close before replacing binaries
function PrepareToInstall(var NeedsRestart: Boolean): String;
var
  ResultCode: Integer;
begin
  Result := '';
  // taskkill without /F sends WM_CLOSE, allowing the application to close cleanly
  Exec('taskkill.exe', '/im {#MyAppExeName}', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  Sleep(500);
end;
