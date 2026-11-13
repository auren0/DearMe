; DearMe Windows installer (Inno Setup 6.3+)
;
; Build the Windows release first:
;   flutter build windows --release
;
; Then compile this file with Inno Setup:
;   iscc installer.iss
;
; Output:
;   build\windows\installer\DearMe-<version>-windows-x64-setup.exe
;
; Keep MyAppVersion in sync with `version:` in pubspec.yaml. The installer
; copies the complete Flutter release bundle, including data\ and plugin DLLs.

#define MyAppName "DearMe"
#define MyAppVersion "1.0.0"
#define MyAppVersionInfo "1.0.0.0"
#define MyAppPublisher "DearMe"
#define MyAppExeName "DearMe.exe"
#define MyAppAumid "DearMe.App"
#define MyAppToastClsid "F7D9A3C2-6C1E-4D7A-9F2B-8E4A1C5B7D30"
#define BuildDir "build\windows\x64\runner\Release"
#define OutputDir "build\windows\installer"
#define SetupIcon "windows\runner\resources\app_icon.ico"

[Setup]
; Stable identity for upgrades and uninstall. Do not regenerate this GUID.
AppId={{657A7471-C795-44B9-B9F9-5CCFA05E8746}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppComments=Letters to your future self
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
DisableWelcomePage=no
AllowNoIcons=yes
LicenseFile=
OutputDir={#OutputDir}
OutputBaseFilename=DearMe-{#MyAppVersion}-windows-x64-setup
SetupIconFile={#SetupIcon}
UninstallDisplayIcon={app}\{#MyAppExeName}
Compression=lzma2/max
SolidCompression=yes
LZMAUseSeparateProcess=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
CloseApplications=yes
RestartApplications=no
VersionInfoVersion={#MyAppVersionInfo}
VersionInfoCompany={#MyAppPublisher}
VersionInfoDescription=DearMe installer
VersionInfoProductName={#MyAppName}
VersionInfoProductVersion={#MyAppVersionInfo}
VersionInfoCopyright=Copyright (C) 2026 DearMe
ShowLanguageDialog=auto

[Languages]
Name: "russian"; MessagesFile: "compiler:Languages\Russian.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[InstallDelete]
; Upgrade from the pre-DearMe executable name without leaving a stale copy.
Type: files; Name: "{app}\dearme.exe"

[Files]
Source: "{#BuildDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs; Excludes: "*.pdb,*.ilk"
; The app itself creates its database in the user's application-support
; directory; no writable data is installed into Program Files.

[Icons]
; The same AppUserModelID is used by WindowsInitializationSettings in
; lib/core/services/local_notification_service.dart. Matching it here gives
; unpackaged installations the correct notification identity.
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; WorkingDir: "{app}"; Comment: "Letters to your future self"; AppUserModelID: "{#MyAppAumid}"; AppUserModelToastActivatorCLSID: "{#MyAppToastClsid}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; WorkingDir: "{app}"; Comment: "Letters to your future self"; Tasks: desktopicon; AppUserModelID: "{#MyAppAumid}"; AppUserModelToastActivatorCLSID: "{#MyAppToastClsid}"

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent
