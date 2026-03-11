# Script: Run-TiaMap-Dev.ps1
# Objetivo: iniciar ambiente de desenvolvimento do TIA Map (backend + frontend).

param(
    [string]$DataPath
)

$projectRoot = if ($PSScriptRoot) { Split-Path -Path $PSScriptRoot -Parent } else { (Get-Location).Path }
$backendPath = Join-Path $projectRoot "tia-map\backend"
$frontendPath = Join-Path $projectRoot "tia-map\frontend"

$backendPort = 8021
$frontendPort = 5173

Write-Host "=== TIA MAP LAUNCHER ===" -ForegroundColor Cyan
Write-Host "Projeto raiz: $projectRoot" -ForegroundColor DarkCyan
Write-Host "Verificando ambiente..." -ForegroundColor Yellow

function Resolve-PythonExe {
    $candidates = @(
        "python",
        "py -3",
        "C:\Users\Administrador\AppData\Local\Programs\Python\Python311\python.exe"
    )

    foreach ($candidate in $candidates) {
        try {
            if ($candidate -eq "py -3") {
                & py -3 --version *> $null
                if ($LASTEXITCODE -eq 0) { return "py -3" }
            } else {
                & $candidate --version *> $null
                if ($LASTEXITCODE -eq 0) { return $candidate }
            }
        } catch {
            continue
        }
    }
    return $null
}

function Resolve-NpmCmd {
    $npmCmd = Get-Command npm -ErrorAction SilentlyContinue
    if ($npmCmd) { return "npm" }

    $fallback = "C:\Program Files\nodejs\npm.cmd"
    if (Test-Path $fallback) { return $fallback }

    return $null
}

function Test-PortListening {
    param([int]$Port)
    $listening = netstat -ano | Select-String ":$Port\s+.*LISTENING"
    return ($null -ne $listening)
}

function Stop-ProcessOnPort {
    param([int]$Port)
    $conn = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($conn -and $conn.OwningProcess -gt 0) {
        try {
            Stop-Process -Id $conn.OwningProcess -Force -ErrorAction Stop
            Write-Host "Processo na porta $Port encerrado (PID $($conn.OwningProcess))." -ForegroundColor Yellow
            Start-Sleep -Seconds 1
        } catch {
            Write-Warning "Falha ao encerrar processo da porta ${Port}: $($_.Exception.Message)"
        }
    }
}

function Stop-UvicornBackend {
    param([int]$Port)
    $targets = Get-CimInstance Win32_Process | Where-Object {
        ($_.Name -match 'python|py.exe') -and
        ($_.CommandLine -match "uvicorn") -and
        ($_.CommandLine -match "main:app") -and
        ($_.CommandLine -match "--port\\s+$Port")
    }
    foreach ($proc in $targets) {
        try {
            Stop-Process -Id $proc.ProcessId -Force -ErrorAction Stop
            Write-Host "Processo uvicorn encerrado: PID $($proc.ProcessId)." -ForegroundColor Yellow
        } catch {
            Write-Warning "Falha ao encerrar PID $($proc.ProcessId): $($_.Exception.Message)"
        }
    }
}

function Assert-PathExists {
    param([string]$Path, [string]$Label)
    if (-not (Test-Path $Path)) {
        Write-Error "$Label nao encontrado: $Path"
        exit 1
    }
}

Assert-PathExists -Path $backendPath -Label "Pasta backend"
Assert-PathExists -Path $frontendPath -Label "Pasta frontend"

$pythonExe = Resolve-PythonExe
if (-not $pythonExe) {
    Write-Error "Python nao encontrado. Instale Python 3.11 e tente novamente."
    exit 1
}

$npmExe = Resolve-NpmCmd
if (-not $npmExe) {
    Write-Error "npm nao encontrado. Instale Node.js LTS e tente novamente."
    exit 1
}

Write-Host "Verificacao concluida." -ForegroundColor Green
Write-Host "Python: $pythonExe" -ForegroundColor DarkGreen
Write-Host "NPM: $npmExe" -ForegroundColor DarkGreen

# Garante PATH do node para subprocessos iniciados.
$nodePath = "C:\Program Files\nodejs"
$effectivePath = if ($env:Path -like "*$nodePath*") { $env:Path } else { "$nodePath;$env:Path" }

$backendUp = Test-PortListening -Port $backendPort
$frontendUp = Test-PortListening -Port $frontendPort

# Quando DataPath for informado, reinicia o backend para garantir que a nova origem seja aplicada.
if (-not [string]::IsNullOrWhiteSpace($DataPath)) {
    if (Test-Path $DataPath) {
        Write-Host "Origem de dados solicitada: $DataPath" -ForegroundColor Cyan
    } else {
        Write-Warning "DataPath informado nao existe: $DataPath. Sera usada a origem padrao."
    }
    Stop-UvicornBackend -Port $backendPort
    Stop-ProcessOnPort -Port $backendPort
    $backendUp = $false
}

if ($backendUp) {
    Write-Host "Backend ja ativo na porta $backendPort. Nao sera reiniciado." -ForegroundColor DarkYellow
} else {
    Write-Host "Iniciando backend (FastAPI) na porta $backendPort..." -ForegroundColor Yellow
    $backendDataPath = ""
    if (-not [string]::IsNullOrWhiteSpace($DataPath) -and (Test-Path $DataPath)) {
        $backendDataPath = $DataPath
    }
    $backendCmd = "cd '$backendPath'; `$env:Path='$effectivePath'; `$env:TIA_MAP_DATA_PATH='$backendDataPath'; $pythonExe -m uvicorn main:app --reload --port $backendPort"
    Start-Process powershell -ArgumentList "-NoExit", "-Command", $backendCmd
}

if ($frontendUp) {
    Write-Host "Frontend ja ativo na porta $frontendPort. Nao sera reiniciado." -ForegroundColor DarkYellow
} else {
    Write-Host "Iniciando frontend (Vite) na porta $frontendPort..." -ForegroundColor Yellow
    $frontendCmd = "cd '$frontendPath'; `$env:Path='$effectivePath'; & '$npmExe' run dev"
    Start-Process powershell -ArgumentList "-NoExit", "-Command", $frontendCmd
}

Write-Host ""
Write-Host "Servicos iniciados em novas janelas do PowerShell." -ForegroundColor Green
Write-Host "Frontend: http://localhost:$frontendPort" -ForegroundColor Green
Write-Host "Backend docs: http://localhost:$backendPort/docs" -ForegroundColor Green
Write-Host "Se alguma janela fechar, copie o erro e me envie." -ForegroundColor Yellow
