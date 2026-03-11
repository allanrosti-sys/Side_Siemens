# Script: Start-WebPanel.ps1
# Objetivo: iniciar o painel web oficial em porta dedicada e evitar conflito de instancias antigas.

param(
    [int]$Port = 8099
)

$projectRoot = if ($PSScriptRoot) { Split-Path -Parent $PSScriptRoot } else { (Get-Location).Path }
$webServerScript = Join-Path $projectRoot 'Logs\WebServer.ps1'

if (-not (Test-Path $webServerScript)) {
    Write-Error "WebServer.ps1 nao encontrado em: $webServerScript"
    exit 1
}

# Encerra instancias antigas do mesmo script para evitar confusao de versao.
$running = Get-CimInstance Win32_Process |
    Where-Object { $_.Name -eq 'powershell.exe' -and $_.CommandLine -match 'Logs\\WebServer.ps1' }

foreach ($proc in $running) {
    if ($proc.ProcessId -ne $PID) {
        try {
            Stop-Process -Id $proc.ProcessId -Force -ErrorAction Stop
            Write-Host "Instancia antiga encerrada: PID $($proc.ProcessId)" -ForegroundColor Yellow
        } catch {
            Write-Warning "Falha ao encerrar PID $($proc.ProcessId): $($_.Exception.Message)"
        }
    }
}

# Garante que a porta escolhida esteja livre para evitar "Failed to fetch".
function Get-AvailablePort {
    param([int]$PreferredPort)
    $candidates = @($PreferredPort, 8099, 8080, 8081, 8090, 8091)
    foreach ($candidate in $candidates | Select-Object -Unique) {
        $inUse = Get-NetTCPConnection -LocalPort $candidate -ErrorAction SilentlyContinue | Where-Object { $_.State -in @("Listen","Established") }
        if (-not $inUse) { return $candidate }
    }
    return $PreferredPort
}

$selectedPort = Get-AvailablePort -PreferredPort $Port
if ($selectedPort -ne $Port) {
    Write-Warning "Porta $Port em uso. Usando porta disponivel: $selectedPort"
}

$argList = @(
    '-NoProfile',
    '-ExecutionPolicy', 'Bypass',
    '-File', $webServerScript,
    '-Port', $selectedPort
)
# Inicia o servidor em janela oculta para nao incomodar o usuario final.
Start-Process powershell -WorkingDirectory $projectRoot -ArgumentList $argList -WindowStyle Hidden

Start-Sleep -Seconds 2

try {
    $version = Invoke-WebRequest -Uri ("http://localhost:{0}/api/version" -f $selectedPort) -UseBasicParsing -TimeoutSec 5
    Write-Host "Painel iniciado com sucesso: http://localhost:$selectedPort" -ForegroundColor Green
    Write-Host "Resposta /api/version: $($version.Content)" -ForegroundColor DarkGreen
    Start-Process ("http://localhost:{0}" -f $selectedPort)
} catch {
    Write-Warning "Painel iniciado, mas /api/version nao respondeu ainda: $($_.Exception.Message)"
    Write-Host "Acesse manualmente: http://localhost:$selectedPort" -ForegroundColor Cyan
}
