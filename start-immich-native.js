import { spawn, execSync } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';

const APP_DIR = 'G:\\immich-app';
const SERVER_DIR = path.join(APP_DIR, 'server');
const ML_DIR = path.join(APP_DIR, 'machine-learning');
const STACK_DIR = path.join(APP_DIR, 'stack');
const LOG_FILE = path.join(STACK_DIR, 'immich-server.log');
const ERR_FILE = path.join(STACK_DIR, 'immich-server.err.log');
const ML_LOG = path.join(STACK_DIR, 'immich-ml.log');
const ML_ERR = path.join(STACK_DIR, 'immich-ml.err.log');
const DB_DIR = 'G:\\immich\\Database';
const PID_FILE = path.join(DB_DIR, 'postmaster.pid');
const PG_CTL = path.join(STACK_DIR, 'pgsql-14', 'bin', 'pg_ctl.exe');
const PG_LOG = path.join(STACK_DIR, 'pgsql.log');
const REDIS_EXE = path.join(STACK_DIR, 'redis', 'redis-server.exe');
const FFMPEG_BIN = path.join(STACK_DIR, 'ffmpeg', 'bin');
const BUN_EXE = 'C:\\Users\\1\\.bun\\bin\\bun.exe';
const PYTHON_EXE = path.join(STACK_DIR, 'python312', 'python.exe');
const ML_VENV = path.join(STACK_DIR, 'ml-venv');
const MODEL_CACHE = path.join(STACK_DIR, 'model-cache');

let mlProc = null;
let immichProc = null;

function log(msg) {
  const line = `[${new Date().toISOString()}] ${msg}\n`;
  try { fs.appendFileSync(LOG_FILE, line); } catch {}
  try { process.stdout.write(line); } catch {}
}

function run(cmd, opts = {}) {
  try {
    return execSync(cmd, { encoding: 'utf8', windowsHide: true, stdio: 'pipe', ...opts });
  } catch (err) {
    return err.stdout || '';
  }
}

log('=== STARTING IMMICH NATIVE SUPERVISOR (IMMICH + ML NATIVE ENGINE) ===');

// 1. Clean stale postmaster.pid
try {
  const psOut = run('tasklist /FI "IMAGENAME eq postgres.exe"');
  if (!psOut.includes('postgres.exe')) {
    if (fs.existsSync(PID_FILE)) {
      log('[PG] Stale postmaster.pid detected without postgres process. Removing...');
      try { fs.unlinkSync(PID_FILE); } catch {}
    }
  }
} catch (e) {
  if (fs.existsSync(PID_FILE)) {
    try { fs.unlinkSync(PID_FILE); } catch {}
  }
}

// 1.5 Strict Network Isolation: Port 2283 Open on LAN & Tailscale (SSO Protected), Postgres 5432 strictly local-only
try {
  run('netsh advfirewall firewall delete rule name="Immich-Block-LAN-2283"');
  run('netsh advfirewall firewall delete rule name="Immich-Tailscale-2283"');
  run('netsh advfirewall firewall delete rule name="ImmichPort2283"');
  run('netsh advfirewall firewall delete rule name="Immich Server (Port 2283)"');
  run('netsh advfirewall firewall add rule name="Immich Server (Port 2283)" dir=in action=allow protocol=TCP localport=2283 profile=any');
  run('netsh advfirewall firewall delete rule name="PostgreSQL-Block-External"');
  run('netsh advfirewall firewall add rule name="PostgreSQL-Block-External" dir=in action=block protocol=TCP localport=5432 remoteip=192.168.0.0/16,10.0.0.0/8,172.16.0.0/12,100.64.0.0/10,Internet profile=any');
  log('[FIREWALL] Enforced: Port 2283 open on LAN & Tailscale (SSO Protected); PostgreSQL 5432 strictly isolated.');
} catch (fwErr) {
  log(`[FIREWALL] Network rules notice: ${fwErr.message}`);
}

// 1.8 Tailscale Native HTTPS Reverse Proxy (Port 443 -> 2283)
try {
  const tsExe = 'C:\\Program Files\\Tailscale\\tailscale.exe';
  if (fs.existsSync(tsExe)) {
    log('[TAILSCALE] Enabling HTTPS reverse proxy (port 443 -> 2283)...');
    run(`"${tsExe}" serve --bg 2283`, { timeout: 15000 });
    log('[TAILSCALE] Tailscale HTTPS serve enabled on port 443 -> 2283.');
  }
} catch (tsErr) {
  log(`[TAILSCALE] Serve notice: ${tsErr.message}`);
}

// 1.9 Native OpenSSH Server Setup (Port 22, Key Auth, Zero Window)
try {
  const sshDir = 'C:\\Program Files\\OpenSSH';
  const sshdExe = path.join(sshDir, 'sshd.exe');
  if (fs.existsSync(sshdExe)) {
    const scQuery = run('sc.exe query sshd');
    if (!scQuery.includes('RUNNING')) {
      log('[SSH] Setting up OpenSSH Server from ' + sshDir + '...');
      const psSetup = run('powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "cd \'C:\\Program Files\\OpenSSH\'; .\\install-sshd.ps1; .\\ssh-keygen.exe -A; .\\FixHostFilePermissions.ps1 -Confirm:\\$false"');
      log('[SSH] psSetup output: ' + psSetup);
      run('netsh advfirewall firewall delete rule name="OpenSSH-Server-In-TCP"');
      run('netsh advfirewall firewall add rule name="OpenSSH-Server-In-TCP" dir=in action=allow protocol=TCP localport=22 profile=any');
      run('sc.exe config sshd start= auto');
      const startOut = run('net start sshd');
      log('[SSH] net start sshd output: ' + startOut);
      run('reg.exe add "HKLM\\Software\\OpenSSH" /v DefaultShell /t REG_SZ /d "C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe" /f');
      log('[SSH] OpenSSH Server configured and started.');
    } else {
      log('[SSH] OpenSSH service is already running.');
    }
  }
} catch (sshErr) {
  log('[SSH] Notice: ' + sshErr.message);
}

// 2. Ensure Redis is running
try {
  const redisCheck = run('tasklist /FI "IMAGENAME eq redis-server.exe"');
  if (!redisCheck.includes('redis-server.exe')) {
    log('[REDIS] Launching Redis...');
    spawn(REDIS_EXE, ['--port', '6379', '--daemonize', 'no'], {
      detached: true,
      stdio: 'ignore',
      windowsHide: true,
    }).unref();
  } else {
    log('[REDIS] Redis is running.');
  }
} catch (e) {
  log(`[REDIS] Error: ${e.message}`);
}

// 3. Ensure PostgreSQL is running
try {
  const pgStatus = run(`"${PG_CTL}" -D "${DB_DIR}" status`);
  if (!pgStatus.includes('is running')) {
    log('[PG] Starting PostgreSQL...');
    run(`"${PG_CTL}" -D "${DB_DIR}" -l "${PG_LOG}" start`, { timeout: 15000 });
    log('[PG] PostgreSQL start initiated.');
  } else {
    log('[PG] PostgreSQL is running.');
  }
} catch (err) {
  log(`[PG] Start error: ${err.message}`);
}

// 4. Verify PostgreSQL is responding
let pgReady = false;
for (let i = 1; i <= 15; i++) {
  try {
    const net = await import('node:net');
    await new Promise((resolve, reject) => {
      const sock = net.createConnection({ host: '127.0.0.1', port: 5432 }, () => {
        sock.end();
        resolve(true);
      });
      sock.on('error', reject);
      setTimeout(() => { sock.destroy(); reject(new Error('timeout')); }, 1000);
    });
    pgReady = true;
    log('[PG] Port 5432 is responding to connections.');
    break;
  } catch (err) {
    Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, 1000);
  }
}

if (!pgReady) {
  log('[PG FATAL] PostgreSQL port 5432 failed to respond.');
  process.exit(1);
}

// 5. Clean up old Immich & ML workers and any older supervisor
log('[CLEANUP] Cleaning up old worker processes...');
try {
  const psOut = run('powershell -NoProfile -Command "Get-CimInstance Win32_Process | Where-Object { $_.Name -like \'*bun*\' -or $_.Name -like \'*python*\' } | Select-Object ProcessId, CommandLine"');
  for (const l of psOut.split('\n')) {
    if (
      l.includes('dist/main.js') ||
      l.includes('dist\\main.js') ||
      l.includes('workers\\api.js') ||
      l.includes('workers\\microservices.js') ||
      l.includes('immich_ml')
    ) {
      const match = l.match(/\s*(\d+)\s+/);
      if (match) {
        const pid = match[1];
        log(`[CLEANUP] Terminating stale worker PID ${pid}...`);
        try { run(`taskkill /F /PID ${pid}`); } catch {}
      }
    }
    if (l.includes('start-immich-native.js')) {
      const match = l.match(/\s*(\d+)\s+/);
      if (match && Number(match[1]) !== process.pid) {
        log(`[CLEANUP] Terminating older supervisor PID ${match[1]}...`);
        try { run(`taskkill /F /PID ${match[1]}`); } catch {}
      }
    }
  }
} catch (e) {}

// 5.5 Spawn Machine Learning Service on Port 3003
function startMlService() {
  if (!fs.existsSync(PYTHON_EXE)) {
    log('[ML WARN] Python executable not found at ' + PYTHON_EXE);
    return;
  }
  log('[ML] Launching Machine Learning Service (port 3003)...');
  const mlOut = fs.openSync(ML_LOG, 'a');
  const mlErr = fs.openSync(ML_ERR, 'a');
  const certPath = path.join(ML_VENV, 'Lib', 'site-packages', 'certifi', 'cacert.pem');

  mlProc = spawn(PYTHON_EXE, [
    '-m', 'uvicorn',
    'immich_ml.main:app',
    '--host', '127.0.0.1',
    '--port', '3003',
    '--workers', '1',
  ], {
    cwd: ML_DIR,
    detached: true,
    stdio: ['ignore', mlOut, mlErr],
    windowsHide: true,
    env: {
      ...process.env,
      PYTHONPATH: `${ML_DIR};${path.join(ML_VENV, 'Lib', 'site-packages')}`,
      IMMICH_PORT: '3003',
      IMMICH_HOST: '127.0.0.1',
      MACHINE_LEARNING_CACHE_FOLDER: MODEL_CACHE,
      MACHINE_LEARNING_MODEL_TTL: '0',
      NO_PROXY: '*',
      no_proxy: '*',
      HTTP_PROXY: '',
      HTTPS_PROXY: '',
      http_proxy: '',
      https_proxy: '',
      SSL_CERT_FILE: certPath,
      REQUESTS_CA_BUNDLE: certPath,
      PATH: `${path.join(STACK_DIR, 'python312')};${path.join(ML_VENV, 'Scripts')};${FFMPEG_BIN};${process.env.PATH}`,
    },
  });

  mlProc.unref();
  log(`[ML] Machine Learning Service detached with PID ${mlProc.pid}.`);
}

// 6. Spawn Immich Server
function startImmichServer() {
  log('[IMMICH] Launching Immich Server (dist/main.js)...');
  const outStream = fs.openSync(LOG_FILE, 'a');
  const errStream = fs.openSync(ERR_FILE, 'a');

  immichProc = spawn(BUN_EXE, ['--env-file=.env', 'dist/main.js'], {
    cwd: SERVER_DIR,
    detached: true,
    stdio: ['ignore', outStream, errStream],
    windowsHide: true,
    env: {
      ...process.env,
      IMMICH_MACHINE_LEARNING_URL: 'http://127.0.0.1:3003',
      NO_PROXY: '*',
      no_proxy: '*',
      HTTP_PROXY: '',
      HTTPS_PROXY: '',
      http_proxy: '',
      https_proxy: '',
      PATH: `${FFMPEG_BIN};C:\\Users\\1\\.bun\\bin;${process.env.PATH}`,
    },
  });

  immichProc.unref();
  log(`[IMMICH] Immich Server detached with PID ${immichProc.pid}.`);
}

startMlService();
startImmichServer();

// 7. Verify Health (Immich Port 2283 + ML Port 3003)
log('[HEALTH] Polling health endpoints...');
let immichHealthy = false;
let mlHealthy = false;

for (let i = 1; i <= 90; i++) {
  Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, 1000);
  
  if (!mlHealthy) {
    try {
      const mlRes = await fetch('http://127.0.0.1:3003/ping');
      if (mlRes.status === 200) {
        log('[HEALTH] ML Service Port 3003 OK! (pong)');
        mlHealthy = true;
      }
    } catch {}
  }

  if (!immichHealthy) {
    try {
      const res = await fetch('http://127.0.0.1:2283/api/server/ping');
      if (res.status === 200) {
        const data = await res.json();
        log(`[HEALTH] Immich Server HTTP 200 OK! Response: ${JSON.stringify(data)}`);
        immichHealthy = true;
      }
    } catch {}
  }

  if (immichHealthy && mlHealthy) {
    break;
  }
}

if (immichHealthy) {
  log(`=== IMMICH STACK IS FULLY ONLINE! (ML Healthy: ${mlHealthy}) ===`);
  log('[SUPERVISOR] Entering persistent monitor loop (checking health every 30s)...');
  
  setInterval(async () => {
    // Monitor ML
    try {
      const mlRes = await fetch('http://127.0.0.1:3003/ping');
      if (mlRes.status !== 200) {
        log('[SUPERVISOR WARN] ML health check returned status ' + mlRes.status);
      }
    } catch (e) {
      log('[SUPERVISOR WARN] ML service unreachable: ' + e.message + ', restarting ML...');
      startMlService();
    }

    // Monitor Immich Server
    try {
      const res = await fetch('http://127.0.0.1:2283/api/server/ping');
      if (res.status !== 200) {
        log('[SUPERVISOR WARN] Immich health check returned status ' + res.status);
      }
    } catch (e) {
      log('[SUPERVISOR WARN] Immich server unreachable: ' + e.message + ', restarting Immich...');
      startImmichServer();
    }
  }, 30000);
} else {
  log('[HEALTH ERROR] Timed out waiting for Immich server to respond.');
  process.exit(1);
}
