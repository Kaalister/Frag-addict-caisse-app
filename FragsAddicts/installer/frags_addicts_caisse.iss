#define AppName "Frags Addicts Caisse"
#define AppVersion GetEnv("APP_VERSION")
#if AppVersion == ""
  #define AppVersion "1.0.0"
#endif
#define AppExeName "frags_addicts_caisse.exe"

[Setup]
AppId={{6F24919C-9C7D-42AC-8DF2-690A7A7E8B2A}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher=Frags Addicts
DefaultDirName={autopf}\{#AppName}
DefaultGroupName={#AppName}
OutputDir=..\dist
OutputBaseFilename=FragsAddictsCaisseSetup-{#AppVersion}
Compression=lzma
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64

[Languages]
Name: "french"; MessagesFile: "compiler:Languages\French.isl"

[Tasks]
Name: "desktopicon"; Description: "Créer un raccourci sur le bureau"; GroupDescription: "Raccourcis :"; Flags: unchecked

[Files]
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\{#AppExeName}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#AppExeName}"; Description: "Lancer {#AppName}"; Flags: nowait postinstall skipifsilent
