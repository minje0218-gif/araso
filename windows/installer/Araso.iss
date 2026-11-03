; Araso-Setup.exe: installs the Windows input method into Program Files, registers its text
; service (x64, x86 and, on ARM64 Windows, ARM64) and adds it to the user's input methods.
; Built by .github/workflows/windows.yml from the staged folder (/DStage=…, /DVersion=…).
; Saved as UTF-8 with a BOM: Inno Setup reads the Korean text right only so.
;   iscc /DStage=build\stage /DVersion=0.2.4 windows\installer\Araso.iss

#ifndef Version
  #define Version "0.0.0"
#endif
#ifndef Stage
  #define Stage "..\..\build\stage"
#endif

[Setup]
AppId={{8B4F5812-54E9-4A07-887F-51BB2264B600}
AppName=Hanyeong
AppVersion={#Version}
AppVerName=Hanyeong {#Version}
AppPublisher=minje0218-gif (from nytta studio's Araso)
AppPublisherURL=https://github.com/minje0218-gif/araso
DefaultDirName={autopf}\Hanyeong
DisableDirPage=yes
DisableProgramGroupPage=yes
PrivilegesRequired=admin
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
OutputBaseFilename=Araso-Setup
SetupIconFile=..\Resources\Araso.ico
UninstallDisplayIcon={app}\ArasoHost.exe
WizardStyle=modern
Compression=lzma2/max
SolidCompression=yes
CloseApplications=no
MinVersion=10.0.17763

[Languages]
; Korean when this Inno Setup has its translation (6.3 and later do).
#if FileExists(AddBackslash(CompilerPath) + "Languages\Korean.isl")
Name: "korean"; MessagesFile: "compiler:Languages\Korean.isl"
#endif
Name: "english"; MessagesFile: "compiler:Default.isl"

[CustomMessages]
#if FileExists(AddBackslash(CompilerPath) + "Languages\Korean.isl")
korean.DeleteData=설정과 학습한 단어도 지울까요?%n(%APPDATA%\Hanyeong)
korean.AddedNote=Hanyeong을 입력기 목록에 추가했습니다. 작업 표시줄의 입력 표시기(ENG)에서 Hanyeong을 고르세요.
#endif
english.DeleteData=Also delete settings and learned words?%n(%APPDATA%\Hanyeong)
english.AddedNote=Hanyeong was added to your input methods. Pick it in the taskbar's input indicator (ENG).

[Files]
; The host and the Swift core it loads, with the Swift runtime beside them.
Source: "{#Stage}\ArasoHost.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#Stage}\*.dll"; Excludes: "ArasoTip.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#Stage}\Resources\*"; Excludes: "Dictionary"; DestDir: "{app}\Resources"; Flags: ignoreversion recursesubdirs
; The text service, loaded into every app: one per architecture. A copy in use is replaced at the
; next restart.
Source: "{#Stage}\ArasoTip.dll"; DestDir: "{app}"; Flags: ignoreversion regserver restartreplace uninsrestartdelete
Source: "{#Stage}\x86\ArasoTip.dll"; DestDir: "{app}\x86"; Flags: ignoreversion regserver 32bit restartreplace uninsrestartdelete
; ARM64: ArasoTip.dll is an ARM64X forwarder to ArasoTipArm64.dll (ARM64 apps) and ArasoTipX64.dll
; (x64 apps under emulation), which share the one registration.
Source: "{#Stage}\arm64\*.dll"; DestDir: "{app}\arm64"; Flags: ignoreversion restartreplace uninsrestartdelete; Check: IsArm64

[Registry]
; The host starts at sign-in for every user.
Root: HKLM; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; ValueType: string; ValueName: "Hanyeong"; ValueData: """{app}\ArasoHost.exe"" --server"; Flags: uninsdeletevalue

[Run]
Filename: "{sys}\regsvr32.exe"; Parameters: "/s ""{app}\arm64\ArasoTip.dll"""; Flags: runhidden waituntilterminated; Check: IsArm64
Filename: "{app}\ArasoHost.exe"; Parameters: "--register"; Flags: runasoriginaluser runhidden waituntilterminated
Filename: "{app}\ArasoHost.exe"; Parameters: "--server"; Flags: runasoriginaluser nowait

[UninstallRun]
; The uninstaller runs elevated, as the user who installed it (runasoriginaluser is for [Run] only).
Filename: "{app}\ArasoHost.exe"; Parameters: "--unregister"; Flags: runhidden waituntilterminated; RunOnceId: "Unregister"
Filename: "{sys}\regsvr32.exe"; Parameters: "/u /s ""{app}\arm64\ArasoTip.dll"""; Flags: runhidden waituntilterminated; Check: IsArm64; RunOnceId: "UnregisterArm64"
Filename: "{sys}\taskkill.exe"; Parameters: "/F /IM ArasoHost.exe"; Flags: runhidden waituntilterminated; RunOnceId: "StopHost"

[Code]
procedure StopHost();
var
  Code: Integer;
begin
  // The host holds the Swift core and the data files; a new copy can't replace them while it runs.
  Exec(ExpandConstant('{sys}\taskkill.exe'), '/F /IM ArasoHost.exe', '', SW_HIDE, ewWaitUntilTerminated, Code);
end;

function PrepareToInstall(var NeedsRestart: Boolean): String;
begin
  StopHost();
  Result := '';
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if (CurStep = ssDone) and not WizardSilent() then
    MsgBox(CustomMessage('AddedNote'), mbInformation, MB_OK);
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  if CurUninstallStep = usUninstall then
    StopHost();
  if (CurUninstallStep = usPostUninstall) and not UninstallSilent() then
    if MsgBox(CustomMessage('DeleteData'), mbConfirmation, MB_YESNO or MB_DEFBUTTON2) = IDYES then
      DelTree(ExpandConstant('{userappdata}\Hanyeong'), True, True, True);
end;
