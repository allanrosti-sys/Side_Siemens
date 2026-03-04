# Script: Run-Full-Cycle
# Objetivo: Export -> Git commit -> Import

$ErrorActionPreference = 'Stop'

Write-Host '========================================' -ForegroundColor Magenta
Write-Host '  INICIANDO CICLO COMPLETO DE SINCRONIA' -ForegroundColor Magenta
Write-Host '========================================' -ForegroundColor Magenta

$scriptRoot = 'C:\Users\Administrador\Documents\tirol-ipiranga-os18869_20260224_PE_V20\Logs'
$exportScript = Join-Path $scriptRoot 'RunExporterWithAttach.ps1'
$importScript = Join-Path $scriptRoot 'Import-New-Blocks.ps1'
$projectRoot = 'C:\Users\Administrador\Documents\tirol-ipiranga-os18869_20260224_PE_V20'

# ETAPA 1: EXPORT
Write-Host "`n[1/3] EXPORTANDO..." -ForegroundColor Cyan
powershell -ExecutionPolicy Bypass -File $exportScript
if ($LASTEXITCODE -ne 0) {
    throw 'Falha na etapa de exportacao.'
}
Write-Host 'Exportacao concluida.' -ForegroundColor Green

# ETAPA 2: GIT COMMIT
Write-Host "`n[2/3] COMMIT GIT..." -ForegroundColor Cyan
Set-Location $projectRoot
try {
    git rev-parse --is-inside-work-tree *> $null
    if ($LASTEXITCODE -eq 0) {
        git add .
        $msg = 'Ciclo automatico: ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
        git commit -m $msg *> $null
        if ($LASTEXITCODE -eq 0) {
            Write-Host 'Commit realizado com sucesso.' -ForegroundColor Green
        } else {
            Write-Host 'Sem alteracoes para commit (ou commit nao realizado).' -ForegroundColor Yellow
        }
    } else {
        Write-Host 'Repositorio git nao inicializado. Pulando commit.' -ForegroundColor Yellow
    }
}
catch {
    Write-Host ('Aviso no commit git: ' + $_.Exception.Message) -ForegroundColor Yellow
}

# ETAPA 3: IMPORT
Write-Host "`n[3/3] IMPORTANDO BLOCOS..." -ForegroundColor Cyan
powershell -ExecutionPolicy Bypass -File $importScript -Headless
if ($LASTEXITCODE -ne 0) {
    throw 'Falha na etapa de importacao.'
}
Write-Host 'Importacao concluida.' -ForegroundColor Green

Write-Host "`n========================================" -ForegroundColor Magenta
Write-Host '  CICLO COMPLETO FINALIZADO' -ForegroundColor Magenta
Write-Host '========================================' -ForegroundColor Magenta
