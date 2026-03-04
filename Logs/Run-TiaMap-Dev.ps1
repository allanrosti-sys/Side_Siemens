# Script: Run-TiaMap-Dev.ps1
# Objetivo: iniciar ambiente de desenvolvimento do TIA Map (backend + frontend).

$projectRoot = if ($PSScriptRoot) { Split-Path -Path $PSScriptRoot -Parent } else { (Get-Location).Path }
$backendPath = Join-Path $projectRoot "tia-map\backend"
$frontendPath = Join-Path $projectRoot "tia-map\frontend"

$backendPort = 8001
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

function Test-PortAvailable {
    param([int]$Port)
    $listening = netstat -ano | Select-String ":$Port\s+.*LISTENING"
    if ($listening) {
        Write-Error "Porta $Port ja esta em uso. Feche o processo atual dessa porta e tente novamente."
        exit 1
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

Test-PortAvailable -Port $backendPort
Test-PortAvailable -Port $frontendPort

Write-Host "Verificacao concluida." -ForegroundColor Green
Write-Host "Python: $pythonExe" -ForegroundColor DarkGreen
Write-Host "NPM: $npmExe" -ForegroundColor DarkGreen

# Garante PATH do node para subprocessos iniciados.
$nodePath = "C:\Program Files\nodejs"
$effectivePath = if ($env:Path -like "*$nodePath*") { $env:Path } else { "$nodePath;$env:Path" }

Write-Host "Iniciando backend (FastAPI) na porta $backendPort..." -ForegroundColor Yellow
$backendCmd = "cd '$backendPath'; `$env:Path='$effectivePath'; $pythonExe -m uvicorn main:app --reload --port $backendPort"
Start-Process powershell -ArgumentList "-NoExit", "-Command", $backendCmd

Write-Host "Iniciando frontend (Vite) na porta $frontendPort..." -ForegroundColor Yellow
$frontendCmd = "cd '$frontendPath'; `$env:Path='$effectivePath'; & '$npmExe' run dev"
Start-Process powershell -ArgumentList "-NoExit", "-Command", $frontendCmd

Write-Host ""
Write-Host "Servicos iniciados em novas janelas do PowerShell." -ForegroundColor Green
Write-Host "Frontend: http://localhost:$frontendPort" -ForegroundColor Green
Write-Host "Backend docs: http://localhost:$backendPort/docs" -ForegroundColor Green
Write-Host "Se alguma janela fechar, copie o erro e me envie." -ForegroundColor Yellow
