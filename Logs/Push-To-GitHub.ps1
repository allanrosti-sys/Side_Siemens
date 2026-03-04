# Script: Push to GitHub
# Objetivo: Enviar alterações locais para o repositório remoto

$ErrorActionPreference = 'Continue'
$projectRoot = "C:\Users\Administrador\Documents\tirol-ipiranga-os18869_20260224_PE_V20"

if (Test-Path $projectRoot) {
    Set-Location $projectRoot
} else {
    Write-Error "Diretório do projeto não encontrado: $projectRoot"
    exit 1
}

Write-Host "=== PUSH PARA GITHUB ===" -ForegroundColor Cyan

# Verifica se é um repo git
if (-not (Test-Path ".git")) {
    Write-Error "Repositório Git não encontrado. Execute Logs\Setup-Git-Repo.ps1 primeiro."
    exit 1
}

# Verifica status
git status

# Adiciona e commita tudo (caso tenha sobrado algo)
Write-Host "`nAdicionando arquivos..." -ForegroundColor Gray
git add .
git commit -m "Update via Push-To-GitHub script: $(Get-Date -Format 'yyyy-MM-dd HH:mm')" 

# Verifica se tem remote configured
$remotes = git remote -v
if (-not $remotes) {
    Write-Warning "Nenhum remote 'origin' configurado."
    $url = Read-Host "Cole a URL do repositório GitHub (ex: https://github.com/usuario/repo.git)"
    if (-not [string]::IsNullOrWhiteSpace($url)) {
        git remote add origin $url
        Write-Host "Remote 'origin' configurado." -ForegroundColor Green
    } else {
        Write-Error "URL não fornecida. Abortando."
        exit 1
    }
}

# Push
Write-Host "`nEnviando para GitHub (origin main)..." -ForegroundColor Yellow
git push -u origin main

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n✅ Sucesso! Código enviado para o GitHub." -ForegroundColor Green
} else {
    Write-Host "`n❌ Falha no push. Verifique se:" -ForegroundColor Red
    Write-Host "1. Você tem permissão no repositório."
    Write-Host "2. A URL está correta."
    Write-Host "3. Você está autenticado no Git."
}