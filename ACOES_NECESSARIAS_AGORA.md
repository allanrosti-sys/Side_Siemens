# 🚨 AÇÕES NECESSÁRIAS AGORA

## Bloqueador Identificado: PROJECT LOCK

**Status:** ❌ Bloqueado  
**Causa:** TIA Portal GUI no VMPUCHTA-25 tem o projeto aberto  
**Evidência:** Erro do exporter: "project cannot be accessed. Already opened by user Administrador on VMPUCHTA-25"

---

## Instruções para Desbloqueio

### **Passo 1️⃣ : FECHAR TIA PORTAL**
- **Via GUI:**
  - Clique no "X" da janela TIA Portal (canto superior direito)
  - OU: Menu File → Exit
  - Aguarde até que TODAS as janelas TIA desapareçam
  
- **Via PowerShell (se necessário):**
  ```powershell
  Stop-Process -Name "Siemens.Automation.Portal" -Force -ErrorAction SilentlyContinue
  Write-Host "✓ Portal processes encerrados"
  ```

### **Passo 2️⃣ : AGUARDAR LIBERAÇÃO DO LOCK (2-3 minutos)**
- Windows mantém lock do projeto por até 2 minutos após fechamento
- **NÃO execute nada** durante este tempo
- Configurar timer:
  ```powershell
  Start-Sleep -Seconds 180  # Aguardar 3 minutos
  Write-Host "✓ Tempo de espera concluído"
  ```

### **Passo 3️⃣ : VERIFICAR QUE TUDO FOI FECHADO**
```powershell
Get-Process | Where-Object { $_.Name -like "*Siemens*" -or $_.Name -like "*Portal*" }
# Resultado esperado: Nenhuma linha (ou apenas processos de sistema)
```

### **Passo 4️⃣ : REEXECUTAR O EXPORTER**

```powershell
# Navegar até o diretório
cd 'c:\Users\Administrador\Documents\tirol-ipiranga-os18869_20260224_PE_V20'

# Executar a exportação
.\Logs\TiaProjectExporter_v20.exe `
  .\tirol-ipiranga-os18869_20260224_PE_V20.ap20 `
  .\Logs\ControlModules_Export

# ✓ NÃO deve aparecer popup "Grant Access" (já foi aprovado)
# ✓ Deve executar sem timeout
# ✓ Pode demorar 30-60 segundos
```

**Saída Esperada:**
```
Iniciating TiaOpenness export tool...
Connecting to instances...
Compiling software (Rebuild All)...
[Progress...]
✓ Export complete!
```

### **Passo 5️⃣ : VALIDAR RESULTADO**

```powershell
# Contar XMLs gerados
(Get-ChildItem '.\Logs\ControlModules_Export\*.xml' -Recurse).Count

# Exibir primeiros 10
Get-ChildItem '.\Logs\ControlModules_Export\*.xml' -Recurse | Select-Object -First 10 | %{ $_.FullName }

# Verificar hierarquia
Get-ChildItem '.\Logs\ControlModules_Export\' -Recurse | Where-Object {$_.PSIsContainer -eq $false} | Group-Object -Property Extension
```

**Resultado Esperado:**
```
Count: 150+  (ou qualquer número > 0)
Padrão de nomes:
  OB_MainCycle.xml
  FB_DriveControl.xml
  FC_SafetyCheck.xml
  [subfolders]/OB_*.xml
  [subfolders]/FB_*.xml
  ...
```

## Se algo der errado...

### **Erro: "Still timeout"?**
→ Significa que outro Portal process ainda está rodando
→ Executar: `Get-Process -Name "Siemens.Automation.Portal" | Stop-Process -Force`

### **Erro: "Relative path"?**
→ Usar caminhos absolutos:
```powershell
$proj = "C:\Users\Administrador\Documents\tirol-ipiranga-os18869_20260224_PE_V20\tirol-ipiranga-os18869_20260224_PE_V20.ap20"
$export = "C:\Users\Administrador\Documents\tirol-ipiranga-os18869_20260224_PE_V20\Logs\ControlModules_Export"
.\Logs\TiaProjectExporter_v20.exe $proj $export
```

### **Erro: "No XML files after export"?**
→ Verificar o arquivo de log mais recente:
```powershell
Get-Content ".\Logs\run_output_latest.txt" | Select-Object -Last 20
```

---

## Cronograma

| Ação | Tempo | Tempo Total |
|------|-------|------------|
| Fechar Portal | 1 min | 1 min |
| Esperar lock | 3 min | 4 min |
| Verificar | 1 min | 5 min |
| Reexecutar | 1 min | 6 min |
| Exportação | 1 min | 7 min |
| Validação | 2 min | 9 min |

**Total Estimado: 9-15 minutos**

---

## Após Confirmação de Sucesso

Uma vez que XMLs forem confirmados, as IAs executarão:

1. **Copilot:** Contará e listará primeiros 5 XMLs
2. **Codex:** Validará estrutura e qualidade de export
3. **Gemini:** Gerará código de IMPORT para reconstruir blocos em novo projeto

---

## Contacto / Suporte

**Monitor em tempo real:** AI_SYNC.md (atualiza automaticamente)  
**Loop:** Contínuo, 5 segundos de check  
**Tempo de resposta IAs:** <30 segundos  

---

**Criado em:** 27/02/2026 15:58  
**Status:** 🔴 Aguardando Ação do Usuário
