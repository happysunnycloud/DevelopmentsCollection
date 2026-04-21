@echo off
setlocal enabledelayedexpansion

REM === Пути ===
set SRC_DIR=Src
set OUT_DIR=Build
set JAR_DIR=out
set DEX_DIR=Dex

set ANDROID_SDK=C:\Program Files (x86)\Android\android-sdk
set BUILD_TOOLS=%ANDROID_SDK%\build-tools\35.0.0
set PLATFORM_JAR=%ANDROID_SDK%\platforms\android-35\android.jar

REM === CHECK ===
if not exist "%PLATFORM_JAR%" (
    echo ERROR: android.jar not found
    pause
    exit /b 1
)

if not exist "%BUILD_TOOLS%\d8.bat" (
    echo ERROR: d8.bat not found
    pause
    exit /b 1
)

REM === folders ===
if not exist "%OUT_DIR%" mkdir "%OUT_DIR%"
if not exist "%JAR_DIR%" mkdir "%JAR_DIR%"
if not exist "%DEX_DIR%" mkdir "%DEX_DIR%"

REM =========================
REM 1. COMPILE
REM =========================
javac --release 8 ^
-classpath "%PLATFORM_JAR%" ^
-d "%OUT_DIR%" ^
%SRC_DIR%\com\alarmbroadcastreceiver\*.java

if errorlevel 1 (
    echo ERROR: compile failed
    pause
    exit /b 1
)

REM =========================
REM 2. CREATE JAR (КЛЮЧЕВОЙ ШАГ)
REM =========================
jar cf "%JAR_DIR%\alarm.jar" -C "%OUT_DIR%" .

if errorlevel 1 (
    echo ERROR: jar failed
    pause
    exit /b 1
)

REM =========================
REM 3. DEX
REM =========================
call "%BUILD_TOOLS%\d8.bat" ^
--output "%DEX_DIR%" ^
--lib "%PLATFORM_JAR%" ^
"%JAR_DIR%\alarm.jar"

if errorlevel 1 (
    echo ERROR: dex failed
    pause
    exit /b 1
)

echo DONE
echo RESULT: %DEX_DIR%\classes.dex

endlocal