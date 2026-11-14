# ==============================================================================
# Immich Native Windows 10 Launcher (Zero Docker / Hyper-V Safe)
#
# Preserves Windows 10 Test Mode for kernel drivers (Sarine, Lexus, Helium).
# Runs 100% natively on Windows using portable PostgreSQL 16, Redis, Python 3.12,
# and Bun for instant, Docker-free execution.
# ==============================================================================

[CmdletBinding()]
param(
    [string]$UploadDir = "M:\Immich-Photos",
    [int]$ServerPort = 2283,
    [int]$MlPort = 3003,
    [int]$DbPort = 5432,
    [int]$RedisPort = 6379
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  IMMICH NATIVE WINDOWS 10 RUNNER (ZERO DOCKER)" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Environment & Stack Directories
$StackDir = Join-Path $ScriptDir "stack"
$PgsqlDir = Join-Path $StackDir "pgsql"
$PgDataDir = Join-Path $StackDir "pgsql-data"
$RedisDir = Join-Path $StackDir "redis"
$RedisExe = Join-Path $RedisDir "redis-server.exe"

if (!(Test-Path $StackDir)) { New-Item -ItemType Directory -Path $StackDir | Out-Null }
if (!(Test-Path $UploadDir)) { New-Item -ItemType Directory -Path $UploadDir -Force | Out-Null }

# 2. Check Prerequisites (Bun, Python, Node)
Write-Host "[1/5] Checking System Prerequisites..." -ForegroundColor Yellow

$BunPath = (Get-Command bun -ErrorAction SilentlyContinue)?.Source
if (!$BunPath) {
    Write-Error "Bun is not installed or not in PATH. Install Bun via: powershell -c ""irm bun.sh/install.ps1 | iex"""
    exit 1
}
Write-Host "  ✓ Bun found: $BunPath" -ForegroundColor Green

$PythonPath = (Get-Command python -ErrorAction SilentlyContinue)?.Source
if (!$PythonPath) {
    Write-Error "Python 3 is required for Machine Learning. Please install Python 3.11+."
    exit 1
}
Write-Host "  ✓ Python found: $PythonPath" -ForegroundColor Green

# 3. Setup Portable Redis if not present
Write-Host "[2/5] Checking Portable Redis..." -ForegroundColor Yellow
if (!(Test-Path $RedisExe)) {
    Write-Host "  Downloading portable Redis for Windows..." -ForegroundColor Cyan
    New-Item -ItemType Directory -Path $RedisDir -Force | Out-Null
    $RedisZip = Join-Path $RedisDir "redis.zip"
    $RedisUrl = "https://github.com/tporadowski/redis/releases/download/v5.0.14.1/Redis-x64-5.0.14.1.zip"
    
    Invoke-WebRequest -Uri $RedisUrl -OutFile $RedisZip -UseBasicParsing
    Expand-Archive -Path $RedisZip -DestinationPath $RedisDir -Force
    Remove-Item $RedisZip -Force
    Write-Host "  ✓ Redis downloaded & extracted to $RedisDir" -ForegroundColor Green
} else {
    Write-Host "  ✓ Portable Redis binary verified." -ForegroundColor Green
}

# 4. Setup Portable PostgreSQL 16 if not present
Write-Host "[3/5] Checking Portable PostgreSQL 16..." -ForegroundColor Yellow
$InitDbExe = Join-Path $PgsqlDir "bin\initdb.exe"
$PgCtlExe = Join-Path $PgsqlDir "bin\pg_ctl.exe"

if (!(Test-Path $InitDbExe)) {
    Write-Host "  Downloading PostgreSQL 16 portable binaries for Windows..." -ForegroundColor Cyan
    $PgZip = Join-Path $StackDir "pgsql.zip"
    $PgUrl = "https://sbp.enterprisedb.com/getfile.jsp?fileid=1258894" # PostgreSQL 16.4 Windows binaries
    
    Invoke-WebRequest -Uri $PgUrl -OutFile $PgZip -UseBasicParsing
    Expand-Archive -Path $PgZip -DestinationPath $StackDir -Force
    Remove-Item $PgZip -Force
    Write-Host "  ✓ PostgreSQL extracted to $PgsqlDir" -ForegroundColor Green
}

# Initialize Postgres cluster if not exists
if (!(Test-Path (Join-Path $PgDataDir "PG_VERSION"))) {
    Write-Host "  Initializing new PostgreSQL database cluster..." -ForegroundColor Cyan
    & $InitDbExe -D $PgDataDir -U postgres -A trust -E UTF8
    Write-Host "  ✓ Database cluster initialized." -ForegroundColor Green
}

# 5. Configure Server Environment (.env)
Write-Host "[4/5] Preparing Immich Environment Variables..." -ForegroundColor Yellow
$EnvPath = Join-Path $ScriptDir "server\.env"
$EnvContent = @"
NODE_ENV=production
IMMICH_PORT=$ServerPort
IMMICH_HOST=0.0.0.0
DB_HOSTNAME=127.0.0.1
DB_PORT=$DbPort
DB_USERNAME=postgres
DB_PASSWORD=postgres
DB_DATABASE_NAME=immich
REDIS_HOSTNAME=127.0.0.1
REDIS_PORT=$RedisPort
UPLOAD_LOCATION=$UploadDir
IMMICH_MACHINE_LEARNING_URL=http://127.0.0.1:$MlPort
IMMICH_CHUNK_SIZE_MB=50
IMMICH_ALLOW_REVERSE_PROXY=true
"@

Set-Content -Path $EnvPath -Value $EnvContent -Encoding UTF8
Write-Host "  ✓ Generated $EnvPath (50MB chunking enabled)" -ForegroundColor Green

# 5. Build Server if not already built
$ServerDist = Join-Path $ScriptDir "server\dist\main.js"
if (!(Test-Path $ServerDist)) {
    Write-Host "  Building Immich Server production bundle..." -ForegroundColor Cyan
    if (Get-Command pnpm -ErrorAction SilentlyContinue) {
        pnpm --filter immich build
    } else {
        bun --cwd (Join-Path $ScriptDir "server") run build
    }
}

# 6. Service Launchers
Write-Host "[5/5] Launching Native Services..." -ForegroundColor Yellow

# Start Redis
$RedisProcess = Start-Process -FilePath $RedisExe -ArgumentList "--port $RedisPort --daemonize no" -PassThru -NoNewWindow
Write-Host "  ✓ Redis started on port $RedisPort (PID: $($RedisProcess.Id))" -ForegroundColor Green

# Start PostgreSQL
& $PgCtlExe -D $PgDataDir -l (Join-Path $StackDir "pgsql.log") start
Start-Sleep -Seconds 2

# Ensure database 'immich' exists
$PsqlExe = Join-Path $PgsqlDir "bin\psql.exe"
& $PsqlExe -U postgres -p $DbPort -c "SELECT 1 FROM pg_database WHERE datname='immich'" | Out-Null
if ($LASTEXITCODE -ne 0) {
    & $PsqlExe -U postgres -p $DbPort -c "CREATE DATABASE immich;"
    Write-Host "  ✓ Created database 'immich'" -ForegroundColor Green
}

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  IMMICH STACK RUNNING NATIVELY (ZERO DOCKER)" -ForegroundColor Cyan
Write-Host "  Local Web URL: http://localhost:$ServerPort" -ForegroundColor Cyan
Write-Host "  Cloudflare:    https://photos.meetbhingradiya.in" -ForegroundColor Cyan
Write-Host "  Storage Vault: $UploadDir" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "Press Ctrl+C to cleanly shut down all services." -ForegroundColor Yellow

# Start Immich Server using Bun
try {
    Set-Location (Join-Path $ScriptDir "server")
    if (Test-Path $ServerDist) {
        Write-Host "Starting Immich Server via Bun (dist/main.js)..." -ForegroundColor Green
        bun run dist\main.js
    } elseif (Get-Command pnpm -ErrorAction SilentlyContinue) {
        Write-Host "Starting Immich Server via pnpm..." -ForegroundColor Green
        pnpm run start
    } else {
        bun run start
    }
} finally {
    Write-Host "`nShutting down native services..." -ForegroundColor Red
    if ($RedisProcess -and !$RedisProcess.HasExited) {
        Stop-Process -Id $RedisProcess.Id -Force
        Write-Host "  ✓ Redis stopped." -ForegroundColor Red
    }
    & $PgCtlExe -D $PgDataDir stop -m fast
    Write-Host "  ✓ PostgreSQL stopped." -ForegroundColor Red
    Set-Location $ScriptDir
}
