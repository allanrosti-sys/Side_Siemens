# Script: Start-WebPanel.ps1
# Objetivo: iniciar o painel web oficial em porta dedicada e evitar conflito de instancias antigas.

param(
    [int]$Port = 8090
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

$cmd = "Set-Location '$projectRoot'; powershell -ExecutionPolicy Bypass -File '$webServerScript' -Port $Port"
Start-Process powershell -ArgumentList '-NoExit', '-Command', $cmd

Start-Sleep -Seconds 2

try {
    $version = Invoke-WebRequest -Uri ("http://localhost:{0}/api/version" -f $Port) -UseBasicParsing -TimeoutSec 5
    Write-Host "Painel iniciado com sucesso: http://localhost:$Port" -ForegroundColor Green
    Write-Host "Resposta /api/version: $($version.Content)" -ForegroundColor DarkGreen
    Start-Process ("http://localhost:{0}" -f $Port)
} catch {
    Write-Warning "Painel iniciado, mas /api/version nao respondeu ainda: $($_.Exception.Message)"
    Write-Host "Acesse manualmente: http://localhost:$Port" -ForegroundColor Cyan
}
