# Quadro Oficial de Tarefas (Team Lead: Gemini / Allan Rostirolla)

## STATUS DO PROJETO: 🏁 ENTREGUE (v1.0)

- Fonte oficial de status: `Logs/AI_SYNC.md`.
- Quadro oficial de execucao: este arquivo.
- Toda atualizacao deve usar portugues e conter evidencia de validacao.

## Sprint Atual: Executavel Robusto v20

| ID | Tarefa | Dono | Status | Criterio de Aceite |
|---|---|---|---|---|
| T1 | Definir binario oficial unico | Codex | Concluido | Nome unico do exe confirmado no AI_SYNC |
| T2 | Definir script oficial unico de execucao | Codex | Concluido | Um unico `.ps1` oficial confirmado |
| T3 | Validar export real no filesystem | Codex | Concluido | `Logs/ControlModules_Export` com XML > 0 |
| T4 | Padronizar caminho de saida na documentacao | Gemini | Concluido | Documentacao aponta `Logs/ControlModules_Export` |
| T5 | Revisar mensagens do console para portugues claro | Codex | Concluido | Build e execucao com logs claros em PT-BR |
| T6 | Fechar checklist de release operacional | Gemini/Codex | Em andamento | Checklist final preenchido e validado |
| T7 | Configurar repositorio Git local | Gemini | Concluido | Script `Setup-Git-Repo.ps1` criado |
| T8 | Push para GitHub | Usuario | Entregue | Repositorio configurado no script de setup |
| T9 | Importar novos blocos SCL (VS Code -> TIA) | Gemini | Concluido | Scripts de importacao criados |
| T10 | Criar script de ciclo completo (Export->Commit->Import) | Gemini | Concluido | `Run-Full-Cycle.ps1` criado |
| T11 | Criar pacote de Release v1.0 | Gemini | Concluido | `Create-Release-Package.ps1` criado |
| T12 | Migrar projeto para C:\Projetos | Gemini | Concluido | Script de migração criado |
| T13 | Criar Documentação de Estudos Iniciais | Gemini | Concluido | `ESTUDOS_INICIAIS.md` criado |
| T14 | Criar Interface Gráfica (Launcher) | Copilot | Concluido | `Launcher_GUI.ps1` aprimorado (v2) |
| T15 | Criar Interface Web (Browser) | Copilot | Concluido | `WebServer.ps1` e `index.html` criados |
| T16 | Popup Mermaid de estrutura do projeto | Codex | Concluido | Botao Web + endpoint `/api/mermaid` funcionais |
| T17 | Melhorar usabilidade do Mermaid (Zoom/Pan) | Gemini | Concluido | Biblioteca `svg-pan-zoom` integrada |
| T18 | Base de requisitos e roadmap para GitHub | Codex/Gemini | Em andamento | Documento de arquitetura e backlog consolidado |

## Definicoes Oficiais (vigentes)
- Binario oficial: `Logs/TiaProjectExporter_v20.exe`
- Script oficial de execucao: `Logs/RunExporterWithAttach.ps1`

## Evidencia Atual
- Export validado: `15` XML em `Logs/ControlModules_Export`.
- Ultimo log validado: `Logs/run_output_attach_20260227_181404.txt`.
- Build validado:
  - Exporter: `Logs/Build_Exporter.ps1` compila `Logs/using Siemens.cs` com sucesso.
  - Importer: `Logs/Build_Importer.ps1` compila `Logs/using Siemens_Import.cs` com sucesso.
- Import validado: `Logs/Import-New-Blocks.ps1 -Headless` gerou blocos com fallback automatico para attach.

## Formato Obrigatorio de Resposta no AI_SYNC
```text
## [AAAA-MM-DD HH:MM] [IA] -> [Destinatarios]
- Escopo:
- Arquivos alterados:
- Validacao executada:
- Resultado:
- Proximo passo:
```
