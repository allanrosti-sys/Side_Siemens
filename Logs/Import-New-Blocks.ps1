# Script: Importar Novos Blocos SCL (Import-New-Blocks.ps1)
# Objetivo: Ler arquivos .scl/.udt de uma pasta de origem e injetar no TIA Portal.
# Autor: Equipe de IAs (Gemini/Codex/Copilot)

param(
    [string]$SourcePath, # Caminho opcional da pasta contendo os arquivos fonte
    [string]$TargetProjectPath, # Caminho opcional para o arquivo .ap20 alvo
    [switch]$Headless    # Modo sem interface grafica (para automacao)
)

$ErrorActionPreference = "Stop"

# --- Definicao de Caminhos Base ---
$projectRoot = if ($PSScriptRoot) { Split-Path -Parent $PSScriptRoot } else { (Get-Location).Path }
$logsDir = Join-Path $projectRoot "Logs"
$exePath = Join-Path $logsDir "TiaBlockImporter_v20.exe"
$buildScript = Join-Path $logsDir "Build_Importer.ps1"

# Resolve projeto alvo: usa parametro quando informado, senao tenta localizar um .ap20 na raiz do projeto.
if (-not [string]::IsNullOrWhiteSpace($TargetProjectPath)) {
    $projPath = $TargetProjectPath
} else {
    $projPath = (Get-ChildItem -Path $projectRoot -Filter *.ap20 -File -ErrorAction SilentlyContinue | Select-Object -First 1).FullName
}

if ([string]::IsNullOrWhiteSpace($projPath) -or -not (Test-Path $projPath)) {
    Write-Host "ERRO: Projeto .ap20 nao encontrado. Informe -TargetProjectPath." -ForegroundColor Red
    exit 1
}

# --- Logica Principal ---
# Define a pasta de origem: usa o parametro se informado, senao usa o padrao 'Logs\NewBlocks'
if (-not [string]::IsNullOrWhiteSpace($SourcePath)) {
    $sclDir = $SourcePath
} else {
    $sclDir = Join-Path $logsDir "NewBlocks"
}

Write-Host "=== IMPORTACAO DE BLOCOS SCL ===" -ForegroundColor Cyan
Write-Host ("MODO: " + ($(if ($Headless) { "Headless" } else { "Attach" }))) -ForegroundColor Yellow
Write-Host "Origem dos arquivos: $sclDir" -ForegroundColor Cyan

# Cria a pasta de origem se ela nao existir, para evitar erros em execucoes automatizadas.
if (-not (Test-Path $sclDir)) {
    New-Item -ItemType Directory -Path $sclDir | Out-Null
    Write-Host "Pasta de origem criada (estava ausente): $sclDir" -ForegroundColor Yellow
}

# Logica de fallback: Se a pasta de origem estiver vazia, copia arquivos de exemplo da pasta Logs.
if ((Get-ChildItem -Path $sclDir -Filter *.scl -ErrorAction SilentlyContinue | Measure-Object).Count -eq 0) {
    $fallbackScls = Get-ChildItem -Path $logsDir -Filter *.scl -File -ErrorAction SilentlyContinue
    foreach ($f in $fallbackScls) {
        Copy-Item -Path $f.FullName -Destination (Join-Path $sclDir $f.Name) -Force
    }

    if ($fallbackScls.Count -gt 0) {
        Write-Host "Pasta de origem estava vazia. Copiados $($fallbackScls.Count) arquivo(s) .scl de exemplo." -ForegroundColor Yellow
    }
}

# Validacao final: Aborta se, mesmo apos o fallback, nao houver arquivos para importar.
if ((Get-ChildItem -Path $sclDir -Filter *.scl -ErrorAction SilentlyContinue | Measure-Object).Count -eq 0) {
    Write-Host "ERRO: Nenhum arquivo .scl encontrado em: $sclDir" -ForegroundColor Red
    Write-Host "Adicione arquivos .scl e execute novamente." -ForegroundColor Red
    exit 1
}

# Compila o importador C# para garantir que esta atualizado
& $buildScript
if ($LASTEXITCODE -ne 0) {
    Write-Host "Falha ao compilar importador." -ForegroundColor Red
    exit 1
}

Write-Host "`nImportando de: $sclDir"
# Prepara a lista de argumentos para o executavel C#.
$arguments = @($sclDir, $projPath)
if ($Headless) {
    $arguments += "--headless"
}

# Verifica se o executavel existe antes de tentar chama-lo.
if (-not (Test-Path $exePath)) {
    Write-Host "Executavel nao encontrado: $exePath" -ForegroundColor Red
    exit 1
}

# Executa a ferramenta de importacao C# e verifica o codigo de saida.
& $exePath $arguments
if ($LASTEXITCODE -ne 0) {
    Write-Host "Importador retornou codigo de erro: $LASTEXITCODE" -ForegroundColor Red
    exit $LASTEXITCODE
}

Write-Host "`nVerifique no TIA Portal: External Sources e Program Blocks." -ForegroundColor Green
