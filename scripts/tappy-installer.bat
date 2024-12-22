@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

:: Variables
set "tempDir=%TEMP%\ReadyOrNotModPack"
set "modpackUrl=https://github.com/wasinvalid/tappy-installer/raw/refs/heads/main/resources/tappy-modpack.zip"
set "modpackName=mods.zip"
set "defaultFolder=C:\Program Files (x86)\Steam\steamapps\common\Ready Or Not\ReadyOrNot\Content\Paks"
set "steamLibraryPattern=\SteamLibrary\steamapps\common\Ready Or Not\ReadyOrNot\Content\Paks"
set "modFolder="
set "modCheckFile=mods"  :: Replace with a file or folder that exists in the mod
set "statusMessage="
set "scriptAuthor=TheWever"

:: Clean temporary directory
if exist "%tempDir%" rd /s /q "%tempDir%"
mkdir "%tempDir%"

:: Check default folder
if exist "%defaultFolder%" (
    set "modFolder=%defaultFolder%"
    echo Mod-Ordner gefunden: "%defaultFolder%"
) else (
    echo Standard-Mod-Ordner nicht gefunden: "%defaultFolder%"
)

:: Search all drives if default folder not found
if not defined modFolder (
    echo Suche nach Mod-Ordner in allen Laufwerken...
    for /f "delims=" %%d in ('wmic logicaldisk get caption ^| findstr ":"') do (
        rem Trim all whitespace (spaces or tabs) from %%d
        for /f "tokens=* delims= " %%x in ("%%d") do (
            set "drive=%%x"
            set "drive=!drive: =!"
            set "currentPath=!drive!!steamLibraryPattern!"
            echo Prüfe Laufwerk: !currentPath!
            if exist "!currentPath!" (
                set "modFolder=!currentPath!"
                echo Mod-Ordner gefunden: "!modFolder!"
                goto FolderFound
            )
        )
    )
)

:: Stop if no folder found
if not defined modFolder (
    set "statusMessage=Fehler: Kein Mod-Ordner gefunden."
    echo !statusMessage!
    goto EndScript
)

:FolderFound
:: Check if mod is already installed
if exist "%modFolder%\%modCheckFile%" (
    set "statusMessage=Mod ist bereits installiert."
    echo !statusMessage!
    goto EndScript
)

:: Download modpack
echo Lade Modpack herunter...
powershell -Command "Invoke-WebRequest -Uri '%modpackUrl%' -OutFile '%tempDir%\%modpackName%'"

:: Verify download success
if not exist "%tempDir%\%modpackName%" (
    set "statusMessage=Fehler: Download fehlgeschlagen."
    echo !statusMessage!
    goto EndScript
)

echo Download abgeschlossen.

:: Move modpack
echo Verschiebe Modpack in den Mod-Ordner...
move /Y "%tempDir%\%modpackName%" "%modFolder%"

:: Extract modpack
echo Extrahiere Modpack...
powershell -Command "Expand-Archive -Path '%modFolder%\%modpackName%' -DestinationPath '%modFolder%' -Force"

:: Verify extraction
if errorlevel 1 (
    set "statusMessage=Fehler: Konnte Modpack nicht extrahieren."
    echo %statusMessage%
    goto EndScript
)

:: Clean up mods.zip
echo Entferne Modpack ZIP-Datei...
del "%modFolder%\%modpackName%"

:: Final message for success
set "statusMessage=Modpack erfolgreich installiert."
echo !statusMessage!

:EndScript
:: Show a custom message box using the Msg command
powershell -Command ^
"[void][System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms');^
[System.Windows.Forms.MessageBox]::Show('%statusMessage%', 'TheWever''s Tappy++ Installer', 'OK', 'Information')"

pause
exit /b
