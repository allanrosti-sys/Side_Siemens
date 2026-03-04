# �Ys� PR�"XIMO PASSO - LEIA PRIMEIRO!

## �s�️ Bloqueador Identificado: READ-ONLY Context

O TIA Portal Openness  **não permite exportar blocos se o projeto foi aberto a partir de um ARQUIVO**.

Projetos abertos via arquivo = **read-only mode** (sem permissão de escrita)
Projetos abertos na GUI = **write mode** (com permissão de escrita)

---

## �o. SOLU�?�fO: Abrir TIA Portal manualmente + rodar script

### **Passo 1: Abrir TIA Portal GUI**

Opção A (Rápido):
```
Clique no ícone do TIA Portal na área de trabalho ou barra de tarefas
```

Opção B (Via Terminal):
```
powershell -NoProfile -Command "Start-Process 'C:\Program Files\Siemens\Automation\Portal V20\bin\TIAS.exe'"
```

**Aguarde até que a janela TIA Portal abra completamente** (pode demorar 30s-2min)

---

### **Passo 2: Carregar o Projeto**

Dentro da janela TIA Portal:
1. Menu: **File �?' Open Project**
2. Navegue para: `C:\Users\Administrador\Documents\tirol-ipiranga-os18869_20260224_PE_V20\`
3. Selecione: `tirol-ipiranga-os18869_20260224_PE_V20.ap20`
4. Clique: **Open**

**Aguarde até que o projeto carregue** (pode demorar 1-2 minutos)
- Você verá a árvore de blocos no lado esquerdo
- Não feche esta janela!

---

### **Passo 3: Rodar o Script de Exportação**

Abra um novo **PowerShell** (ou CMD) e execute:

```powershell
powershell -ExecutionPolicy Bypass -File "C:\Users\Administrador\Documents\tirol-ipiranga-os18869_20260224_PE_V20\Logs\RunExporterWithAttach.ps1"
```

**Ou clique duplo em:**
- `C:\Users\Administrador\Documents\tirol-ipiranga-os18869_20260224_PE_V20\Logs\RunExporterWithAttach.ps1`

---

### **Passo 4: Validar Resultado**

O script irá:
1. �o" Verificar que TIA Portal está rodando
2. �o" Limpar exports anteriores
3. �o" Rodar exporter em modo **ATTACH** (usando instância aberta)
4. �o" Contar e listar XMLs gerados
5. �o" Mostrar resultado final

**Resultado Esperado:**
```
�o"�o"�o" SUCESSO! �o"�o"�o"
Total de XMLs gerados: 150+
```

---

## �Y"� Se algo der errado...

### Erro: "TIA Portal não está rodando"
�?' Verifique se a janela TIA Portal está VISÍVEL na tela
�?' Se não, siga Passo 1 novamente

### Erro: "Nenhum projeto aberto"
�?' Verifique se projeto está carregado em TIA
�?' Se não, siga Passo 2 novamente

### Erro: "Still 0 XMLs generated"
�?' Verifique arquivo de log: `Logs\run_output_attach_*.txt`
�?' Procure por mensagens de erro específicas

---

## �Y"� Resumo da Timeline

| Quando | O Quê | Status |
|--------|-------|--------|
| 16:03 | Descoberta do bloqueador read-only | �o" Investigado |
| 16:10 | Modificação do código | �o" Feito |
| 16:15 | Criação de script ATTACH | �o" Pronto |
| **AGORA** | **Execute os passos acima** | ⏳ Aguardando |

---

## �Y"z Contato / Suporte

Se tiver dúvidas ou problema:
1. Verifique o arquivo de log: `Logs\run_output_attach_*.txt`
2. Confirme em: `Logs\AI_SYNC.md` (atualizado com detalhes técnicos)
3. As outras IAs (Codex, Gemini) estão monitorando - qualquer resultado será incluído

---

**Criado:** 27/02/2026 16:20:00  
**Status:** �Y"� Aguardando ação do usuário

