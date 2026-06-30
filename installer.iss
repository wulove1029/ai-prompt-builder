; Inno Setup 安裝檔腳本 —— AI Prompt Builder
; 每位使用者安裝（免系統管理員 / 免 UAC），安裝到 %LocalAppData%\Programs\AI Prompt Builder。
; 由 PyInstaller 的 onedir 產物（dist\AI Prompt Builder）打包而成。

#define MyAppName "AI Prompt Builder"
#ifndef MyAppVersion
  #define MyAppVersion "0.1.8"
#endif
#define MyAppPublisher "Jerry"
#define MyAppExeName "AI Prompt Builder.exe"
#ifndef MySourceDir
  #define MySourceDir "dist\AI Prompt Builder"
#endif

[Setup]
; 固定 AppId —— 升級時會覆蓋同一份安裝，不要更改。
AppId={{C7E2A9F4-3B6D-4E81-9A52-7F0C1D8B4E63}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
AllowNoIcons=yes
OutputDir=installer_output
OutputBaseFilename=AI_Prompt_Builder_Setup_v{#MyAppVersion}
SetupIconFile=app_icon.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
; 每位使用者安裝：免系統管理員權限，自動更新時不會跳 UAC。
PrivilegesRequired=lowest
ArchitecturesInstallIn64BitMode=x64compatible
; 更新時若舊版仍在執行，自動關閉它再覆蓋。
CloseApplications=yes
RestartApplications=no

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "建立桌面捷徑"; GroupDescription: "額外圖示："; Flags: unchecked

[Files]
Source: "{#MySourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\解除安裝 {#MyAppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "立即啟動 {#MyAppName}"; Flags: nowait postinstall skipifsilent
