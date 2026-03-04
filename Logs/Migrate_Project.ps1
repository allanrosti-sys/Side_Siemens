# Script: Migração de Projeto
# Objetivo: Mover o ecossistema de ferramentas para uma pasta definitiva e organizada.
# Autor: Gemini (Líder Técnico) & Allan Rostirolla

$ErrorActionPreference = "Stop"

$currentRoot = "C:\Users\Administrador\Documents\tirol-ipiranga-os18869_20260224_PE_V20"
$targetRoot = "C:\Projetos\TIA_Tools_Manager"

Write-Host "=== INICIANDO MIGRAÇÃO DE PROJETO ===" -ForegroundColor Cyan
Write-Host "Origem: $currentRoot"
Write-Host "Destino: $targetRoot"

# 1. Criar diretório de destino
if (-not (Test-Path $targetRoot)) {
    New-Item -ItemType Directory -Path $targetRoot -Force | Out-Null
    Write-Host "✓ Diretório criado: $targetRoot" -ForegroundColor Green
}

# 2. Copiar arquivos (Excluindo pastas de sistema desnecessárias se houver)
Write-Host "Copiando arquivos... (Isso pode levar alguns segundos)"
Copy-Item -Path "$currentRoot\*" -Destination $targetRoot -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "`n✅ MIGRAÇÃO CONCLUÍDA COM SUCESSO!" -ForegroundColor Green
Write-Host "Por favor, abra o VS Code na nova pasta: $targetRoot" -ForegroundColor Yellow
Write-Host "Comando: code $targetRoot" -ForegroundColor Gray