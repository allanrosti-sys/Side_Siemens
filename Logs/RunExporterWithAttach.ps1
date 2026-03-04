# Script oficial de execucao (Attach)
$ErrorActionPreference = "Stop"

$projPath = "C:\Users\Administrador\Documents\tirol-ipiranga-os18869_20260224_PE_V20\tirol-ipiranga-os18869_20260224_PE_V20.ap20"
$exportPath = "C:\Users\Administrador\Documents\tirol-ipiranga-os18869_20260224_PE_V20\Logs\ControlModules_Export"
$exePath = "C:\Users\Administrador\Documents\tirol-ipiranga-os18869_20260224_PE_V20\Logs\TiaProjectExporter_v20.exe"
$logPath = "C:\Users\Administrador\Documents\tirol-ipiranga-os18869_20260224_PE_V20\Logs\run_output_attach_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

Write-Host "[1/5] Verificando executavel..."
if (-not (Test-Path $exePath)) {
    throw "Executavel nao encontrado: $exePath"
}

Write-Host "[2/5] Verificando TIA Portal..."
$tia = Get-Process -Name "Siemens.Automation.Portal" -ErrorAction SilentlyContinue
if (-not $tia) {
    throw "TIA Portal nao esta rodando. Abra o projeto e execute novamente."
}
Write-Host ("Instancias encontradas: " + (($tia | Select-Object -ExpandProperty Id) -join ', '))

Write-Host "[3/5] Preparando pasta de export..."
if (Test-Path $exportPath) {
    Remove-Item -Recurse -Force $exportPath
}
New-Item -ItemType Directory -Path $exportPath | Out-Null

Write-Host "[4/5] Executando exportacao..."
& $exePath $projPath $exportPath 2>&1 | Tee-Object -FilePath $logPath

Write-Host "[5/5] Validando resultado..."
$xmlCount = (Get-ChildItem $exportPath -Filter *.xml -Recurse -ErrorAction SilentlyContinue | Measure-Object).Count
if ($xmlCount -le 0) {
    throw "Nenhum XML gerado. Verifique o log: $logPath"
}

Write-Host ("Sucesso: " + $xmlCount + " XML gerados.") -ForegroundColor Green
Get-ChildItem $exportPath -Filter *.xml -Recurse | Select-Object -First 10 | ForEach-Object { Write-Host (" - " + $_.FullName) }
Write-Host ("Log: " + $logPath)
