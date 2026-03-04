# Script: Criar Pacote de Release
# Objetivo: Coletar binários, scripts e docs em uma pasta limpa para distribuição.

$ErrorActionPreference = "Stop"

$projectRoot = "C:\Users\Administrador\Documents\tirol-ipiranga-os18869_20260224_PE_V20"
$logsDir = Join-Path $projectRoot "Logs"
$releaseDir = Join-Path $projectRoot "Release_v1.0"

Write-Host "=== CRIANDO PACOTE DE RELEASE v1.0 ===" -ForegroundColor Cyan

# 1. Limpar/Criar diretório de release
if (Test-Path $releaseDir) {
    Remove-Item -Recurse -Force $releaseDir
}
New-Item -ItemType Directory -Path $releaseDir | Out-Null
New-Item -ItemType Directory -Path (Join-Path $releaseDir "Bin") | Out-Null
New-Item -ItemType Directory -Path (Join-Path $releaseDir "Source") | Out-Null

# 2. Copiar Executáveis (Bin)
Write-Host "Copiando ferramentas..."
Copy-Item (Join-Path $logsDir "TiaProjectExporter_v20.exe") -Destination (Join-Path $releaseDir "Bin")
Copy-Item (Join-Path $logsDir "TiaBlockImporter_v20.exe") -Destination (Join-Path $releaseDir "Bin")

# 3. Copiar Scripts Operacionais (Raiz do Release)
Write-Host "Copiando scripts..."
Copy-Item (Join-Path $logsDir "RunExporterWithAttach.ps1") -Destination $releaseDir
Copy-Item (Join-Path $logsDir "Import-New-Blocks.ps1") -Destination $releaseDir
Copy-Item (Join-Path $logsDir "Run-Full-Cycle.ps1") -Destination $releaseDir
Copy-Item (Join-Path $projectRoot "Generate-Documentation.ps1") -Destination $releaseDir

# 4. Copiar Código Fonte SCL/UDT (Source)
Write-Host "Copiando biblioteca SCL..."
Copy-Item (Join-Path $logsDir "NewBlocks\*") -Destination (Join-Path $releaseDir "Source")

# 5. Copiar Documentação
Write-Host "Copiando documentação..."
if (Test-Path (Join-Path $projectRoot "DocumentacaoDoProjeto.html")) {
    Copy-Item (Join-Path $projectRoot "DocumentacaoDoProjeto.html") -Destination $releaseDir
}
Copy-Item (Join-Path $projectRoot "DOCUMENTACAO_PROJETO_PT.md") -Destination $releaseDir

# 6. Criar README
$readme = @"
PACOTE DE FERRAMENTAS TIA PORTAL v20 - AUTOMAÇÃO DE ENGENHARIA
==============================================================
Projeto: Tirol / Ipiranga
Versão: 1.0 (Release Oficial)
Data: $(Get-Date -Format 'dd/MM/yyyy')

---

## 📋 DESCRIÇÃO
Este pacote contém ferramentas para automatizar a exportação, importação e documentação
de blocos de software (OB, FB, FC) do TIA Portal v20.

## 🚀 COMO USAR (INTERFACE GRÁFICA)
1. Abra a pasta deste pacote.
2. Clique com o botão direito em 'Launcher_GUI.ps1' e selecione "Executar com o PowerShell".
3. Use os botões do painel para controlar todas as funções.

## 🛠️ FERRAMENTAS INCLUÍDAS

1. EXPORTAÇÃO (Backup)
   - Script: RunExporterWithAttach.ps1
   - Função: Conecta ao TIA Portal aberto e salva todo o código em XML na pasta 'ControlModules_Export'.

2. IMPORTAÇÃO (Novos Blocos)
   - Script: Import-New-Blocks.ps1
   - Função: Lê arquivos .scl/.udt da pasta 'Source' e injeta no projeto TIA.

3. CICLO COMPLETO (DevOps)
   - Script: Run-Full-Cycle.ps1
   - Função: Realiza Exportação -> Commit no Git -> Importação em sequência.

4. DOCUMENTAÇÃO
   - Script: Generate-Documentation.ps1
   - Função: Gera um relatório HTML detalhado dos blocos exportados.

## ⚠️ REQUISITOS
- TIA Portal v20 instalado.
- TIA Openness habilitado (aceitar prompts de segurança).
- Windows PowerShell 5.1 ou superior.
"@
$readme | Out-File (Join-Path $releaseDir "LEIA_ME.txt") -Encoding UTF8

Write-Host "`n✅ PACOTE CRIADO COM SUCESSO EM: $releaseDir" -ForegroundColor Green
Invoke-Item $releaseDir