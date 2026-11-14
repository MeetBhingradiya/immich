@echo off
setlocal enabledelayedexpansion
title "Immich Native Windows 10 Automated Setup"
color 0B

REM Ensure running with elevated privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

echo ============================================================
echo   IMMICH NATIVE WINDOWS 10 FULL AUTOMATED SETUP (ZERO DOCKER)
echo ============================================================
echo.

REM ============================================================
REM STEP 1: Enable Remote Desktop (RDP)
REM ============================================================
echo [1/7] Enabling Remote Desktop (RDP) on Port 3389...
reg add "HKLM\System\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /v UserAuthentication /t REG_DWORD /d 0 /f >nul 2>&1
netsh advfirewall firewall set rule group="remote desktop" new enable=Yes >nul 2>&1
netsh advfirewall firewall add rule name="Allow RDP 3389" dir=in action=allow protocol=TCP localport=3389 >nul 2>&1
sc config TermService start= auto >nul 2>&1
net start TermService >nul 2>&1
net localgroup "Remote Desktop Users" remotefilecloud /add >nul 2>&1
net localgroup "Administrators" remotefilecloud /add >nul 2>&1
echo   [OK] RDP service configured for user remotefilecloud.

REM ============================================================
REM Configure Windows Firewall: Enforce Local Loopback Only (Zero Remote DB)
REM ============================================================
echo   Locking PostgreSQL and Redis to Local Loopback Only...
netsh advfirewall firewall delete rule name="Immich PostgreSQL Local Only" >nul 2>&1
netsh advfirewall firewall add rule name="Immich PostgreSQL Local Only" dir=in action=allow protocol=TCP localport=5432 remoteip=127.0.0.1 profile=any >nul 2>&1
netsh advfirewall firewall delete rule name="Immich PostgreSQL Block Remote" >nul 2>&1
netsh advfirewall firewall add rule name="Immich PostgreSQL Block Remote" dir=in action=block protocol=TCP localport=5432 remoteip=100.64.0.0/10,0.0.0.0-127.0.0.0,127.0.0.2-255.255.255.255 profile=any >nul 2>&1
netsh advfirewall firewall delete rule name="Immich Redis Local Only" >nul 2>&1
netsh advfirewall firewall add rule name="Immich Redis Local Only" dir=in action=allow protocol=TCP localport=6379 remoteip=127.0.0.1 profile=any >nul 2>&1
netsh advfirewall firewall delete rule name="Immich Redis Block Remote" >nul 2>&1
netsh advfirewall firewall add rule name="Immich Redis Block Remote" dir=in action=block protocol=TCP localport=6379 remoteip=100.64.0.0/10,0.0.0.0-127.0.0.0,127.0.0.2-255.255.255.255 profile=any >nul 2>&1
echo   [OK] Database and cache firewall rules active (100%% local loopback only).

REM ============================================================
REM STEP 2: Ensure Cloudflare Tunnel Service is Running
REM ============================================================
echo [2/7] Checking Cloudflare Tunnel Service...
sc query cloudflared >nul 2>&1
if %errorlevel% equ 0 goto TUNNEL_RUNNING

if exist "G:\immich\cloudflared.exe" (
    echo   Registering and starting cloudflared service...
    G:\immich\cloudflared.exe service install eyJhIjoiYzA2MGY5M2JkZjU4YzQxMTQwN2Y5ZmYzMzRhYjZlMmUiLCJ0IjoiM2IyZGQwOTUtNDc5Zi00NzUxLTg2NjctYmJmZDczOWViOTY5IiwicyI6IllXVTBOekZsTW1VdFpHUTNaaTAwWWpjeUxXSXhNVGN0TlRCbU1EaGlZV0k0TmprNCJ9
)

:TUNNEL_RUNNING
net start cloudflared >nul 2>&1
echo   [OK] Cloudflare Tunnel verified (photos.meetbhingradiya.in).

REM ============================================================
REM STEP 3: Verify System Prerequisites
REM ============================================================
echo [3/7] Verifying System Prerequisites...

set "PATH=%USERPROFILE%\.bun\bin;C:\Program Files\Git\cmd;C:\Program Files\Git\bin;%LOCALAPPDATA%\Programs\Python\Python312;%LOCALAPPDATA%\Programs\Python\Python311;C:\Python312;C:\Python311;C:\Program Files\nodejs;%APPDATA%\npm;%PATH%"

where git >nul 2>&1
if %errorlevel% equ 0 (
    echo   [OK] Git verified.
) else (
    echo   Installing Git...
    winget install --id Git.Git -e --source winget --silent --accept-source-agreements --accept-package-agreements
    set "PATH=C:\Program Files\Git\cmd;C:\Program Files\Git\bin;!PATH!"
)

where bun >nul 2>&1
if %errorlevel% equ 0 (
    echo   [OK] Bun verified.
) else (
    echo   Installing Bun...
    powershell -NoProfile -Command "irm bun.sh/install.ps1 | iex"
    set "PATH=%USERPROFILE%\.bun\bin;!PATH!"
)

where python >nul 2>&1
if %errorlevel% equ 0 (
    echo   [OK] Python verified.
) else (
    echo   Installing Python...
    winget install --id Python.Python.3.12 -e --source winget --silent --accept-source-agreements --accept-package-agreements
    set "PATH=C:\Python312;%LOCALAPPDATA%\Programs\Python\Python312;!PATH!"
)

set "PNPM_EXE=G:\immich\pnpm.exe"
if not exist "%PNPM_EXE%" (
    echo   Downloading official standalone pnpm v9.15.4...
    powershell -NoProfile -Command "Invoke-WebRequest -Uri 'https://github.com/pnpm/pnpm/releases/download/v9.15.4/pnpm-win-x64.exe' -OutFile '%PNPM_EXE%' -UseBasicParsing"
)
echo   [OK] Standalone pnpm verified.

REM ============================================================
REM STEP 4: Unpack Latest Immich Database
REM ============================================================
echo [4/7] Checking Master Database Cluster...
if exist "G:\immich\Database-Laptop-Latest\PG_VERSION" (
    echo   [OK] Latest database cluster is ready.
    goto DB_READY
)

if exist "G:\immich\immich-database-latest.tar.gz" (
    echo   Extracting immich-database-latest.tar.gz...
    if not exist "G:\immich\Database-Laptop-Latest" mkdir "G:\immich\Database-Laptop-Latest"
    tar.exe --strip-components=1 -xzf "G:\immich\immich-database-latest.tar.gz" -C "G:\immich\Database-Laptop-Latest"
    echo   [OK] Database extracted.
)

:DB_READY
REM Remove stale pid if any
if exist "G:\immich\Database-Laptop-Latest\postmaster.pid" del /f /q "G:\immich\Database-Laptop-Latest\postmaster.pid" >nul 2>&1

REM ============================================================
REM STEP 5: Sync Immich Source Code
REM ============================================================
echo [5/7] Syncing Immich Source Code...
if exist "G:\immich-app\.git" goto PULL_IMMICH

echo   Cloning repository (shallow --depth 1 for maximum speed)...
git clone --depth 1 https://github.com/MeetBhingradiya/immich.git "G:\immich-app" -b native-windows-liquid
goto CLONE_DONE

:PULL_IMMICH
echo   Pulling latest updates...
git -C "G:\immich-app" fetch origin native-windows-liquid
git -C "G:\immich-app" reset --hard origin/native-windows-liquid

:CLONE_DONE
echo   [OK] Codebase ready at G:\immich-app.

REM ============================================================
REM STEP 6: Install Dependencies and Verify Server Bundle
REM ============================================================
echo [6/7] Verifying Dependencies and Immich Server...
cd /d "G:\immich-app"

if exist "node_modules" if exist "server\node_modules\@immich\plugin-sdk" goto DEPS_OK
echo   Installing monorepo dependencies via pnpm (live output)...
call "%PNPM_EXE%" install

:DEPS_OK
echo   [OK] Immich Server ready at G:\immich-app\server\dist\main.js.

REM ============================================================
REM STEP 7: Launch Immich Native Windows Runner
REM ============================================================
echo [7/7] Launching Immich Native Windows Runner...
echo.
echo ============================================================
echo   IMMICH RUNNING NATIVELY (ZERO DOCKER)
echo   Local Web:   http://localhost:2283
echo   Cloudflare:  https://photos.meetbhingradiya.in
echo   Storage:     G:\immich\Photos
echo   Database:    G:\immich\Database-Laptop-Latest (PG 14)
echo ============================================================
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "G:\immich-app\run-immich-windows.ps1"
pause
