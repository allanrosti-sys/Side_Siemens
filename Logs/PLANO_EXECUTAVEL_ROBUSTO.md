# Plano de Ação: Gerador de Executável Robusto (TIA Portal V20)

## 1. Objetivo
Gerar um executável único e confiável (`TiaProjectExporter_v20.exe`) que possa ser rodado por qualquer engenheiro para extrair o código do PLC, lidando automaticamente com:
- Instâncias abertas do TIA Portal (Attach).
- Bloqueios de segurança (Openness).
- Compilação de software (Rebuild All).

## 2. Componentes Oficiais

| Componente | Arquivo Fonte | Responsável |
|------------|---------------|-------------|
| **Código Fonte C#** | `Logs/using Siemens.cs` | Gemini/Codex |
| **Script de Build** | `Logs/Build_Exporter.ps1` | Gemini/Copilot |
| **Wrapper de Execução** | `Logs/RunExporterWithAttach.ps1` | Copilot |
| **Documentação** | `DOCUMENTACAO_PROJETO_PT.md` | Gemini |

## 3. Fluxo de Trabalho (Pipeline)

### Etapa A: Preparação do Código (Gemini/Codex)
- [x] Garantir lógica de "Attach" prioritária.
- [x] Garantir compilação `ICompilable.Compile()` antes de exportar.
- [ ] Revisar mensagens de console para Português claro.

### Etapa B: Compilação (Copilot)
- Executar `Logs/Build_Exporter.ps1`.
- Valida automaticamente `csc.exe` e DLL V20.
- Gera: `Logs/TiaProjectExporter_v20.exe`.

### Etapa C: Execução Assistida (User + Copilot)
- Usuário abre projeto no TIA Portal.
- Usuário roda `RunExporterWithAttach.ps1`.
- Script verifica processos, limpa duplicatas (opcional), conecta e exporta.

## 4. Critérios de Sucesso (Definição de Pronto)
1. **Zero Configuração:** O usuário não precisa instalar SDKs, apenas ter o TIA Portal.
2. **Feedback Visual:** O console mostra progresso claro em Português.
3. **Resiliência:** Se o TIA pedir permissão, o script aguarda ou avisa.
4. **Resultado:** Pasta `C:\TiaExports\ControlModules` populada com XMLs válidos.

---
**Status:** Pronto para Compilação. Script de build criado.