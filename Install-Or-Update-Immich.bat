@echo off
setlocal enabledelayedexpansion
title Immich Native Control Center
color 0A
cd /d "G:\immich-app"

set BUN_EXE=C:\Users\1\.bun\bin\bun.exe
set VBS_SCRIPT=G:\immich-app\start-immich-silent.vbs
set JS_SCRIPT=G:\immich-app\start-immich-native.js
set PG_CTL=G:\immich-app\stack\pgsql-14\bin\pg_ctl.exe
set DB_DIR=G:\immich\Database

:MENU
cls
echo ============================================================
echo           IMMICH NATIVE CONTROL CENTER (ZERO DOCKER)
echo ============================================================
echo   [1] Start / Ensure Running (Silent Background Mode)
echo   [2] Restart Immich Stack (Immich + ML + Postgres + Redis)
echo   [3] Check Service Health (Ports 2283, 3003, 5432, 6379)
echo   [4] Stop All Immich Services Cleanly
echo   [5] Update Immich from Git and Rebuild
echo   [0] Exit
echo ============================================================
echo.

choice /C 123450 /N /T 10 /D 1 /M "Select an option [Default=1 in 10s]: "
set CHOICE_ERR=!errorlevel!

if "!CHOICE_ERR!"=="1" goto START_SERVER
if "!CHOICE_ERR!"=="2" goto RESTART_SERVER
if "!CHOICE_ERR!"=="3" goto CHECK_STATUS
if "!CHOICE_ERR!"=="4" goto STOP_SERVER
if "!CHOICE_ERR!"=="5" goto UPDATE_SERVER
if "!CHOICE_ERR!"=="6" goto EXIT_SCRIPT

:START_SERVER
echo.
echo [*] Checking if Immich Server is already online...
curl.exe -s -m 3 http://127.0.0.1:2283/api/server/ping >nul 2>&1
if !errorlevel! equ 0 (
    echo [OK] Immich Server is already online and responding!
    goto SHOW_PING
)

echo [*] Launching Immich Stack silently via VBS supervisor...
if exist "%VBS_SCRIPT%" (
    start "" wscript.exe "%VBS_SCRIPT%"
    echo [*] Launcher invoked. Waiting 10 seconds for initial startup...
    timeout /t 10 /nobreak >nul
    goto CHECK_STATUS
) else (
    echo [ERROR] %VBS_SCRIPT% not found!
    pause
    goto MENU
)

:RESTART_SERVER
echo.
echo [*] Stopping existing Immich and ML workers...
taskkill /F /FI "IMAGENAME eq bun.exe" >nul 2>&1
taskkill /F /FI "IMAGENAME eq python.exe" >nul 2>&1
timeout /t 2 /nobreak >nul
echo [*] Restarting stack...
goto START_SERVER

:CHECK_STATUS
echo.
echo ==================== STATUS SUMMARY ====================
echo --- Immich API (Port 2283) ---
curl.exe -s -m 4 http://127.0.0.1:2283/api/server/ping
if !errorlevel! equ 0 (
    echo  [ONLINE]
) else (
    echo  [OFFLINE / STARTING]
)

echo.
echo --- Immich ML Engine (Port 3003) ---
curl.exe -s -m 4 http://127.0.0.1:3003/ping
if !errorlevel! equ 0 (
    echo  [ONLINE]
) else (
    echo  [OFFLINE / STARTING]
)

echo.
echo --- Active Processes ---
tasklist /FI "IMAGENAME eq postgres.exe" /NH 2>nul | findstr /i "postgres.exe" >nul && echo PostgreSQL: RUNNING || echo PostgreSQL: NOT RUNNING
tasklist /FI "IMAGENAME eq redis-server.exe" /NH 2>nul | findstr /i "redis-server.exe" >nul && echo Redis: RUNNING || echo Redis: NOT RUNNING
tasklist /FI "IMAGENAME eq bun.exe" /NH 2>nul | findstr /i "bun.exe" >nul && echo Bun (Immich): RUNNING || echo Bun (Immich): NOT RUNNING
tasklist /FI "IMAGENAME eq python.exe" /NH 2>nul | findstr /i "python.exe" >nul && echo Python (ML): RUNNING || echo Python (ML): NOT RUNNING
echo ========================================================
echo.
pause
goto MENU

:SHOW_PING
echo.
echo Immich ping response:
curl.exe -s http://127.0.0.1:2283/api/server/ping
echo.
echo Immich version:
curl.exe -s http://127.0.0.1:2283/api/server/version
echo.
pause
goto MENU

:STOP_SERVER
echo.
echo [*] Stopping Immich and ML workers...
taskkill /F /FI "IMAGENAME eq bun.exe" >nul 2>&1
taskkill /F /FI "IMAGENAME eq python.exe" >nul 2>&1
echo [*] Stopping PostgreSQL...
if exist "%PG_CTL%" (
    "%PG_CTL%" -D "%DB_DIR%" stop >nul 2>&1
)
echo [*] Stopping Redis...
taskkill /F /FI "IMAGENAME eq redis-server.exe" >nul 2>&1
echo [OK] All Immich services stopped.
pause
goto MENU

:UPDATE_SERVER
echo.
echo ============================================================
echo   Updating Immich Monorepo from Git
echo ============================================================
git fetch origin
git status
echo.
set /p DO_PULL="Pull latest changes from origin? (y/n): "
if /i "!DO_PULL!"=="y" (
    git pull
    echo [*] Running bun install...
    "%BUN_EXE%" install
    echo [*] Building server...
    cd /d "G:\immich-app\server"
    "%BUN_EXE%" run build
    cd /d "G:\immich-app"
    echo [OK] Build completed.
)
pause
goto MENU

:EXIT_SCRIPT
exit /b 0
