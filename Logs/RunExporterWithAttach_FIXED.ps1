# Script: Run Exporter with Open TIA Instance
# Purpose: Ensure TIA Portal is running and accessible during export

Write-Host "================================"
Write-Host "TIA Exporter - Attach Mode"
Write-Host "================================"

$projPath = "C:\Users\Administrador\Documents\tirol-ipiranga-os18869_20260224_PE_V20\tirol-ipiranga-os18869_20260224_PE_V20.ap20"
$exportPath = "C:\Users\Administrador\Documents\tirol-ipiranga-os18869_20260224_PE_V20\Logs\ControlModules_Export"
$exePath = "C:\Users\Administrador\Documents\tirol-ipiranga-os18869_20260224_PE_V20\Logs\TiaProjectExporter_v20_FIXED.exe"
$logPath = "C:\Users\Administrador\Documents\tirol-ipiranga-os18869_20260224_PE_V20\Logs\run_output_attach_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

# Step 1: Check if TIA is running
Write-Host "`n[1/5] Verificando instâncias do TIA Portal..."
$tiaProcess = Get-Process -Name "Siemens.Automation.Portal" -ErrorAction SilentlyContinue
if ($tiaProcess) {
    Write-Host "✓ TIA Portal encontrado (PID: $($tiaProcess.Id))"
} else {
    Write-Host "✗ TIA Portal não está rodando"
    Write-Host "⚠ Você DEVE abrir o TIA Portal e carregar o projeto manualmente"
    Write-Host "   Depois, execute este script novamente"
    exit 1
}

# Step 2: Clear old exports
Write-Host "`n[2/5] Limpando exports anteriores..."
if (Test-Path $exportPath) {
    Remove-Item -Path $exportPath -Recurse -Force
    Write-Host "✓ Diretório de export limpo"
} else {
    Write-Host "✓ Nenhum export anterior"
}

# Step 3: Create export dir
New-Item -Path $exportPath -ItemType Directory -Force | Out-Null

# Step 4: Run exporter with attach mode
Write-Host "`n[3/5] Executando exporter com modo ATTACH..."
Write-Host "Comando: $exePath"
Write-Host "Saída: $logPath"
Write-Host ""

& $exePath $projPath $exportPath 2>&1 | Tee-Object -FilePath $logPath

# Step 5: Validate results
Write-Host "`n[4/5] Validando resultado..."
$xmlCount = (Get-ChildItem -Path $exportPath -Filter "*.xml" -Recurse -ErrorAction SilentlyContinue | Measure-Object).Count

if ($xmlCount -gt 0) {
    Write-Host "✓✓✓ SUCESSO! ✓✓✓" -ForegroundColor Green
    Write-Host "Total de XMLs gerados: $xmlCount" -ForegroundColor Green
    Write-Host "`nPrimeiros 10 arquivos:"
    Get-ChildItem -Path $exportPath -Filter "*.xml" -Recurse | Select-Object -First 10 | ForEach-Object { Write-Host "  • $($_.FullName)" }
} else {
    Write-Host "✗ FALHA: Nenhum XML foi gerado" -ForegroundColor Red
    Write-Host "Verifique o log: $logPath"
}

Write-Host "`n[5/5] Concluído"
Write-Host "Log salvo em: $logPath"
