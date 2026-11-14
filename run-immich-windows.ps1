# ==============================================================================
# Immich Native Windows 10 Launcher (Zero Docker / Hyper-V Safe)
#
# Preserves Windows 10 Test Mode for kernel drivers (Sarine, Lexus, Helium).
# Runs 100% natively on Windows using portable PostgreSQL 16, Redis, Python 3.12,
# and Bun for instant, Docker-free execution.
# ==============================================================================

[CmdletBinding()]
param(
    [string]$UploadDir = "",
    [string]$PgDataDir = "",
    [string]$DbUser = "",
    [string]$DbPass = "",
    [string]$DbName = "",
    [int]$ServerPort = 2283,
    [int]$MlPort = 3003,
    [int]$DbPort = 5432,
    [int]$RedisPort = 6379
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

# Smart path detection for G:\immich (Desktop) vs M:\Workspace\immich (Laptop)
if ([string]::IsNullOrWhiteSpace($UploadDir)) {
    if (Test-Path "G:\immich\Photos") {
        $UploadDir = "G:\immich\Photos"
    } elseif (Test-Path "M:\Immich-Photos") {
        $UploadDir = "M:\Immich-Photos"
    } else {
        $UploadDir = Join-Path $ScriptDir "photos"
    }
}

# Smart database credentials from G:\immich\.env if present
if ([string]::IsNullOrWhiteSpace($DbUser)) {
    $MasterEnv = "G:\immich\.env"
    if (Test-Path $MasterEnv) {
        Get-Content $MasterEnv | ForEach-Object {
            if ($_ -match '^\s*DB_USERNAME\s*=\s*(.+)$') { $DbUser = $matches[1].Trim() }
            if ($_ -match '^\s*DB_PASSWORD\s*=\s*(.+)$') { $DbPass = $matches[1].Trim() }
            if ($_ -match '^\s*DB_DATABASE_NAME\s*=\s*(.+)$') { $DbName = $matches[1].Trim() }
        }
    }
}
if ([string]::IsNullOrWhiteSpace($DbUser)) { $DbUser = "postgres" }
if ([string]::IsNullOrWhiteSpace($DbPass)) { $DbPass = "postgres" }
if ([string]::IsNullOrWhiteSpace($DbName)) { $DbName = "immich" }
$env:PGPASSWORD = $DbPass

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  IMMICH NATIVE WINDOWS 10 RUNNER (ZERO DOCKER)" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Environment & Stack Directories
$StackDir = Join-Path $ScriptDir "stack"
$PgsqlDir = Join-Path $StackDir "pgsql"

if ([string]::IsNullOrWhiteSpace($PgDataDir)) {
    if (Test-Path "G:\immich\Database-Laptop-Latest\PG_VERSION") {
        $PgDataDir = "G:\immich\Database-Laptop-Latest"
    } else {
        $PgDataDir = Join-Path $StackDir "pgsql-data"
    }
}
$RedisDir = Join-Path $StackDir "redis"
$RedisExe = Join-Path $RedisDir "redis-server.exe"

if (!(Test-Path $StackDir)) { New-Item -ItemType Directory -Path $StackDir | Out-Null }
if (!(Test-Path $UploadDir)) { New-Item -ItemType Directory -Path $UploadDir -Force | Out-Null }

# 2. Check Prerequisites (Bun, Python, Node)
Write-Host "[1/5] Checking System Prerequisites..." -ForegroundColor Yellow

$BunCmd = Get-Command bun -ErrorAction SilentlyContinue
if (!$BunCmd) {
    Write-Error "Bun is not installed or not in PATH. Install Bun via: powershell -c ""irm bun.sh/install.ps1 | iex"""
    exit 1
}
$BunPath = $BunCmd.Source
Write-Host "  ✓ Bun found: $BunPath" -ForegroundColor Green

$PythonCmd = Get-Command python -ErrorAction SilentlyContinue
if (!$PythonCmd) {
    Write-Error "Python 3 is required for Machine Learning. Please install Python 3.11+."
    exit 1
}
$PythonPath = $PythonCmd.Source
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

# 4. Setup Portable PostgreSQL (Matching cluster version)
$PgVersion = 16
if (Test-Path (Join-Path $PgDataDir "PG_VERSION")) {
    $rawVer = (Get-Content (Join-Path $PgDataDir "PG_VERSION") -TotalCount 1).Trim()
    if ($rawVer -match '^\d+') {
        $PgVersion = [int]$matches[0]
    }
}
Write-Host "[3/5] Checking Portable PostgreSQL $PgVersion (Cluster requires PG $PgVersion)..." -ForegroundColor Yellow

$PgsqlDir = Join-Path $StackDir "pgsql-$PgVersion"
$InitDbExe = Join-Path $PgsqlDir "bin\initdb.exe"
$PgCtlExe = Join-Path $PgsqlDir "bin\pg_ctl.exe"

if (!(Test-Path $InitDbExe)) {
    Write-Host "  Downloading PostgreSQL $PgVersion portable binaries for Windows..." -ForegroundColor Cyan
    $PgZip = Join-Path $StackDir "pgsql-$PgVersion.zip"
    if ($PgVersion -eq 14) {
        $PgUrl = "https://sbp.enterprisedb.com/getfile.jsp?fileid=1260676" # PostgreSQL 14.25 Windows binaries
    } elseif ($PgVersion -eq 15) {
        $PgUrl = "https://sbp.enterprisedb.com/getfile.jsp?fileid=1260673" # PostgreSQL 15.20 Windows binaries
    } else {
        $PgUrl = "https://sbp.enterprisedb.com/getfile.jsp?fileid=1258894" # PostgreSQL 16.4 Windows binaries
    }
    
    Invoke-WebRequest -Uri $PgUrl -OutFile $PgZip -UseBasicParsing
    Expand-Archive -Path $PgZip -DestinationPath $StackDir -Force
    Remove-Item $PgZip -Force
    
    $DefaultExtracted = Join-Path $StackDir "pgsql"
    if ((Test-Path $DefaultExtracted) -and ($DefaultExtracted -ne $PgsqlDir)) {
        if (Test-Path $PgsqlDir) { Remove-Item $PgsqlDir -Recurse -Force }
        Rename-Item -Path $DefaultExtracted -NewName "pgsql-$PgVersion"
    }
    Write-Host "  ✓ PostgreSQL $PgVersion extracted to $PgsqlDir" -ForegroundColor Green
}

# Ensure matching pgvector is installed
$VectorDll = Join-Path $PgsqlDir "lib\vector.dll"
if (!(Test-Path $VectorDll)) {
    Write-Host "  Downloading pgvector extension for PostgreSQL $PgVersion..." -ForegroundColor Cyan
    $VectorZip = Join-Path $StackDir "pgvector.zip"
    $VectorUrl = "https://github.com/czkwg8/pgvector-windows-binary/releases/download/v0.8.7/pgvector-v0.8.7-pg$PgVersion-windows-x64.zip"
    Invoke-WebRequest -Uri $VectorUrl -OutFile $VectorZip -UseBasicParsing
    Expand-Archive -Path $VectorZip -DestinationPath $PgsqlDir -Force
    Remove-Item $VectorZip -Force
    
    $ExtDir = Join-Path $PgsqlDir "share\extension"
    if (!(Test-Path $ExtDir)) { New-Item -ItemType Directory -Path $ExtDir -Force | Out-Null }
    Copy-Item (Join-Path $PgsqlDir "lib\vector*.sql") $ExtDir -Force -ErrorAction SilentlyContinue
    Copy-Item (Join-Path $PgsqlDir "lib\vector.control") $ExtDir -Force -ErrorAction SilentlyContinue
    Write-Host "  ✓ pgvector extension installed for PG $PgVersion." -ForegroundColor Green
}

# Remove stale postmaster.pid if present (e.g. from cold copy)
$PidFile = Join-Path $PgDataDir "postmaster.pid"
if (Test-Path $PidFile) {
    Remove-Item $PidFile -Force -ErrorAction SilentlyContinue
}

# Sanitize postgresql.conf for Windows compatibility (strip BOM, fix posix shared memory, isolate to 127.0.0.1)
$ConfPath = Join-Path $PgDataDir "postgresql.conf"
if (Test-Path $ConfPath) {
    [byte[]]$bytes = [System.IO.File]::ReadAllBytes($ConfPath)
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        $bytes = $bytes[3..($bytes.Length - 1)]
    }
    $confText = [System.Text.Encoding]::UTF8.GetString($bytes)
    $confText = [regex]::Replace($confText, '(?m)^dynamic_shared_memory_type\s*=.*$', 'dynamic_shared_memory_type = windows')
    $confText = [regex]::Replace($confText, '(?m)^(lc_\w+\s*=\s*''[^'']*\.utf8'')', '#$1')
    $confText = [regex]::Replace($confText, '(?m)^listen_addresses\s*=.*$', "listen_addresses = '127.0.0.1'")
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($ConfPath, $confText, $utf8NoBom)
}

# Sanitize pg_hba.conf: strictly allow local loopback only (block Tailscale / internet / remote LAN)
$HbaPath = Join-Path $PgDataDir "pg_hba.conf"
if (Test-Path $HbaPath) {
    $hbaText = [System.IO.File]::ReadAllText($HbaPath)
    $hbaText = [regex]::Replace($hbaText, '(?m)^(host\s+all\s+all\s+all\s+.*)$', '# [Remote blocked for security] $1')
    if ($hbaText -notmatch '127\.0\.0\.1/32') {
        $hbaText += "`nhost    all             all             127.0.0.1/32            trust`n"
    }
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($HbaPath, $hbaText, $utf8NoBom)
}

# Initialize Postgres cluster if not exists
if (!(Test-Path (Join-Path $PgDataDir "PG_VERSION"))) {
    Write-Host "  Initializing new PostgreSQL database cluster..." -ForegroundColor Cyan
    & $InitDbExe -D $PgDataDir -U $DbUser -A trust -E UTF8
    Write-Host "  ✓ Database cluster initialized." -ForegroundColor Green
}

# 5. Configure Server Environment (.env)
Write-Host "[4/5] Preparing Immich Environment Variables..." -ForegroundColor Yellow
$BuildDir = Join-Path $StackDir "build"
$GeodataDir = Join-Path $BuildDir "geodata"
$WwwDir = Join-Path $BuildDir "www"
if (!(Test-Path $GeodataDir)) { New-Item -ItemType Directory -Path $GeodataDir -Force | Out-Null }
if (!(Test-Path $WwwDir)) { New-Item -ItemType Directory -Path $WwwDir -Force | Out-Null }
$DateFile = Join-Path $GeodataDir "geodata-date.txt"
if (!(Test-Path $DateFile)) { Set-Content -Path $DateFile -Value "2026-11-14" -Encoding UTF8 }

$WebBuild = Join-Path $ScriptDir "web\build"
if ((Test-Path (Join-Path $WebBuild "index.html")) -and !(Test-Path (Join-Path $WwwDir "index.html"))) {
    Copy-Item -Path "$WebBuild\*" -Destination $WwwDir -Recurse -Force
}

$EnvPath = Join-Path $ScriptDir "server\.env"
$EnvContent = @"
NODE_ENV=production
IMMICH_PORT=$ServerPort
IMMICH_HOST=0.0.0.0
DB_HOSTNAME=127.0.0.1
DB_PORT=$DbPort
DB_USERNAME=$DbUser
DB_PASSWORD=$DbPass
DB_DATABASE_NAME=$DbName
REDIS_HOSTNAME=127.0.0.1
REDIS_PORT=$RedisPort
UPLOAD_LOCATION=$UploadDir
IMMICH_MACHINE_LEARNING_URL=http://127.0.0.1:$MlPort
IMMICH_CHUNK_SIZE_MB=50
IMMICH_ALLOW_REVERSE_PROXY=true
IMMICH_BUILD_DATA=$BuildDir
"@

Set-Content -Path $EnvPath -Value $EnvContent -Encoding UTF8
Write-Host "  ✓ Generated $EnvPath (50MB chunking enabled)" -ForegroundColor Green

# Ensure workspace dependencies are installed
$NodeModules = Join-Path $ScriptDir "node_modules"
$ServerNodeModules = Join-Path $ScriptDir "server\node_modules\@immich\plugin-sdk"
if (!(Test-Path $NodeModules) -or !(Test-Path $ServerNodeModules)) {
    Write-Host "  Installing monorepo dependencies via pnpm..." -ForegroundColor Cyan
    Set-Location $ScriptDir
    if (Get-Command pnpm -ErrorAction SilentlyContinue) {
        pnpm install
    } else {
        bun install
    }
}

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

# Clean up any dangling processes from previous runs
Get-Process redis-server, postgres -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 500

# Start Redis
$RedisProcess = Start-Process -FilePath $RedisExe -ArgumentList "--port $RedisPort --daemonize no" -PassThru -NoNewWindow
Write-Host "  ✓ Redis started on port $RedisPort (PID: $($RedisProcess.Id))" -ForegroundColor Green

# Start PostgreSQL
& $PgCtlExe -D $PgDataDir -l (Join-Path $StackDir "pgsql.log") start
Start-Sleep -Seconds 3

# Verify PostgreSQL started
$pgStatus = & $PgCtlExe -D $PgDataDir status 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "  [-] PostgreSQL failed to start. Last log lines:" -ForegroundColor Red
    $logPath = Join-Path $StackDir "pgsql.log"
    if (Test-Path $logPath) {
        Get-Content $logPath -Tail 10 | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkRed }
    }
    exit 1
}
Write-Host "  ✓ PostgreSQL engine running (bound strictly to 127.0.0.1)." -ForegroundColor Green

# Ensure database exists and verify credentials
$PsqlExe = Join-Path $PgsqlDir "bin\psql.exe"
$CreatedbExe = Join-Path $PgsqlDir "bin\createdb.exe"
$raw = & $PsqlExe -h 127.0.0.1 -p $DbPort -U $DbUser -d $DbName -t -c "SELECT 1;" 2>$null
if (!$raw -or $raw.Trim() -ne "1") {
    # Check if we can connect as postgres or template1
    $raw = & $PsqlExe -h 127.0.0.1 -p $DbPort -U postgres -d postgres -t -c "SELECT 1;" 2>$null
    if ($raw -and $raw.Trim() -eq "1") {
        # Create DbUser role if it doesn't exist
        $hasUser = & $PsqlExe -h 127.0.0.1 -p $DbPort -U postgres -d postgres -t -c "SELECT 1 FROM pg_roles WHERE rolname='$DbUser';" 2>$null
        if (!$hasUser -or $hasUser.Trim() -ne "1") {
            & $PsqlExe -h 127.0.0.1 -p $DbPort -U postgres -d postgres -c "CREATE ROLE $DbUser WITH SUPERUSER LOGIN PASSWORD '$DbPass';" 2>$null
        }
    }
}

# Ensure postgres superuser role exists for tooling/pgAdmin compatibility
$hasPg = & $PsqlExe -h 127.0.0.1 -p $DbPort -U $DbUser -d $DbName -t -c "SELECT 1 FROM pg_roles WHERE rolname='postgres';" 2>$null
if (!$hasPg -or $hasPg.Trim() -ne "1") {
    & $PsqlExe -h 127.0.0.1 -p $DbPort -U $DbUser -d $DbName -c "CREATE ROLE postgres WITH SUPERUSER LOGIN PASSWORD '$DbPass';" 2>$null
}

# Verify database exists
$dbExists = & $PsqlExe -h 127.0.0.1 -p $DbPort -U $DbUser -d $DbName -t -c "SELECT 1 FROM pg_database WHERE datname='$DbName';" 2>$null
if ($dbExists -and $dbExists.Trim() -eq "1") {
    Write-Host "  ✓ Database '$DbName' verified." -ForegroundColor Green
} else {
    & $CreatedbExe -h 127.0.0.1 -p $DbPort -U $DbUser $DbName 2>$null
    Write-Host "  ✓ Created database '$DbName'" -ForegroundColor Green
}

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  IMMICH STACK RUNNING NATIVELY (ZERO DOCKER)" -ForegroundColor Cyan
Write-Host "  Local Web URL: http://localhost:$ServerPort" -ForegroundColor Cyan
Write-Host "  Cloudflare:    https://photos.meetbhingradiya.in" -ForegroundColor Cyan
Write-Host "  Storage Vault: $UploadDir" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "Press Ctrl+C to cleanly shut down all services." -ForegroundColor Yellow

# Start Immich Server
try {
    Set-Location (Join-Path $ScriptDir "server")
    if (Get-Command node -ErrorAction SilentlyContinue) {
        Write-Host "Starting Immich Server via Node.js (dist/main.js)..." -ForegroundColor Green
        node --env-file=.env dist\main.js
    } else {
        Write-Host "Starting Immich Server via Bun (dist/main.js)..." -ForegroundColor Green
        $bunCmd = Get-Command bun -ErrorAction SilentlyContinue
        if ($bunCmd) {
            $bunPath = $bunCmd.Source
        } elseif (Test-Path "$env:USERPROFILE\.bun\bin\bun.exe") {
            $bunPath = "$env:USERPROFILE\.bun\bin\bun.exe"
        } else {
            $bunPath = "bun"
        }
        & $bunPath --env-file=.env dist\main.js
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
