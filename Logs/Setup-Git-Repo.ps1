# Script: Configuração Automática de Git e GitHub
# Objetivo: Inicializar repositório, ignorar arquivos temporários e subir para o GitHub.

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "   CONFIGURAÇÃO DE REPOSITÓRIO GIT" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# Define a raiz do projeto (um nível acima da pasta Logs)
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptPath
Set-Location $projectRoot

Write-Host "📂 Diretório do Projeto: $projectRoot"

# 1. Inicializar Git
if (-not (Test-Path ".git")) {
    Write-Host "init: Inicializando repositório Git..."
    git init
} else {
    Write-Host "info: Repositório Git já existe."
}

# 2. Criar .gitignore (Ignorar binários pesados e logs)
Write-Host "config: Criando arquivo .gitignore..."
$gitignoreContent = @"
# TIA Portal Binaries (Pesados - Versionamos apenas os XMLs exportados)
*.ap20
*.ap19
*.al*
*.backup

# Executáveis e Bibliotecas
*.exe
*.dll
*.pdb

# Logs e Temporários
Logs/run_output_*.txt
Logs/*.log
"@
$gitignoreContent | Out-File ".gitignore" -Encoding UTF8

# 3. Adicionar e Commitar
Write-Host "action: Adicionando arquivos ao controle de versão..."
git add .
git commit -m "Initial commit: Ferramenta de Exportação TIA Portal e Documentação"

# 4. Configurar Remoto (GitHub)
Write-Host "`n-------------------------------------------------------"
Write-Host "PARA ENVIAR AO GITHUB:" -ForegroundColor Yellow
Write-Host "1. Crie um repositório vazio em https://github.com/new"
Write-Host "2. Copie a URL (ex: https://github.com/seu-usuario/seu-repo.git)"
$remoteUrl = Read-Host "Cole a URL do repositório aqui (ou pressione Enter para pular)"

if (-not [string]::IsNullOrWhiteSpace($remoteUrl)) {
    git branch -M main
    git remote add origin $remoteUrl
    git push -u origin main
}