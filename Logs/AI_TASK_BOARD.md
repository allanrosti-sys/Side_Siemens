# Quadro Oficial de Tarefas (Team Lead: Gemini / Allan Rostirolla)

## Status do Projeto
- Produto oficial: `Puchta PLC Insight`
- Nome legado: `TIA Map`
- Fonte oficial de sincronizacao: `Logs/AI_SYNC.md`
- Quadro oficial de execucao: este arquivo
- Toda atualizacao deve usar portugues e conter evidencia de validacao

## Definicoes operacionais vigentes
- O produto agora e multi-vendor: `Siemens` e `Rockwell`
- A escolha de vendor deve ocorrer antes da selecao da pasta/projeto
- O mapa deve herdar o vendor escolhido, sem pedir essa decisao novamente dentro da tela
- A interface principal deve passar a refletir o novo nome do produto
- Toda analise nova deve validar encoding antes de gerar Mermaid

## Sprint Atual: Reorganizacao da Interface Principal

| ID | Tarefa | Dono | Status | Criterio de Aceite |
|---|---|---|---|---|
| UX1 | Mover seletor de vendor para a interface principal, ao lado da configuracao de origem | Codex | Concluido | Vendor visivel antes da escolha da pasta |
| UX2 | Ajustar copy da tela principal para `Puchta PLC Insight` | Codex | Concluido | Nome legado removido da interface principal |
| UX3 | Persistir vendor junto com a origem em `Logs/web_settings.json` | Codex | Concluido | Backend/frontend leem vendor persistido |
| UX4 | Herdar vendor na tela do mapa sem novo seletor principal | Gemini | Pendente | Mapa abre com filtros coerentes ao vendor recebido |
| UX5 | Atualizar cards e labels dinamicos: Siemens vs Rockwell | Gemini | Pendente | Siemens mostra OB/FB/FC/DB e Rockwell mostra Task/MainProgram/Routine/AOI/Tags |
| UX6 | Atualizar legenda de cores para Rockwell e Siemens na experiencia principal | Codex | Concluido | Legenda visivel e coerente com o mapa |
| UX7 | Propor layout final da tela inicial para fluxo unico de entrada | Gemini | Pendente | Mock/implementacao navegavel aprovada visualmente |
| UX8 | Revisao tecnica da entrega do Gemini | Codex | Concluido | Conferencia de codigo, fluxo e regressao |

## Sprint Backend Multi-vendor

| ID | Tarefa | Dono | Status | Criterio de Aceite |
|---|---|---|---|---|
| BE1 | Criar abstracao `PLCParser` | Codex | Concluido | Parser base criado no backend |
| BE2 | Manter parser Siemens em modulo dedicado | Codex | Concluido | Parser Siemens separado e compativel |
| BE3 | Criar parser Rockwell `.L5X` com `Task -> MainProgram -> Routine -> JSR` | Codex | Concluido | Teste automatizado aprovado |
| BE4 | Tornar `/api/graph` multi-vendor | Codex | Concluido | Endpoint aceita `vendor=auto|siemens|rockwell` |
| BE5 | Melhorar performance de `/api/graph` para projetos grandes | Codex | Em andamento | Resposta sem travamento perceptivel em bases grandes |
| BE6 | Gerar Mermaid multi-vendor no backend novo | Codex | Pendente | Mermaid estrutural e de execucao coerentes por vendor |

## Tarefas explicitas para Gemini

### Gemini-01: Fluxo principal multi-vendor
- Objetivo:
  - Reorganizar a interface principal para que o usuario escolha `Siemens`, `Rockwell` ou `Auto` antes da pasta/projeto.
- Arquivos alvo sugeridos:
  - `Logs/index.html`
  - scripts/client-side associados do painel principal
- Criterios de aceite:
  - O seletor de vendor aparece acima ou ao lado da configuracao de origem
  - A ordem do fluxo fica: vendor -> pasta/projeto -> acao
  - A interface continua funcional em desktop sem quebrar os botoes atuais

### Gemini-02: Rename visual do produto
- Objetivo:
  - Atualizar a interface principal para `Puchta PLC Insight`.
- Criterios de aceite:
  - O nome `TIA Map` nao aparece mais como titulo primario
  - O novo titulo e consistente com o mapa React
  - O subtitulo comunica claramente suporte a Siemens e Rockwell

### Gemini-03: Labels dinamicos por vendor
- Objetivo:
  - Adaptar labels, cards e legendas da tela principal ao vendor escolhido.
- Criterios de aceite:
  - Siemens: `OB`, `FB`, `FC`, `DB`
  - Rockwell: `Task`, `MainProgram`, `Routine`, `AOI`, `Tags/Data`
  - Nao ha mistura de terminologia entre vendors na mesma tela

### Gemini-04: Handoff objetivo para Codex
- Objetivo:
  - Entregar alteracoes com log suficiente para auditoria rapida.
- Formato obrigatorio no `AI_SYNC.md`:
  - Escopo
  - Arquivos alterados
  - Validacao executada
  - Resultado
  - Pendencias conhecidas
- Criterios de aceite:
  - Codex consegue revisar a entrega sem redescobrir contexto

## Checklist de revisao do Codex apos entrega do Gemini
- Confirmar se o vendor foi movido para antes da pasta/projeto
- Confirmar se o nome principal virou `Puchta PLC Insight`
- Confirmar se nao houve regressao nos endpoints do painel principal
- Confirmar se os labels da UI respeitam o vendor escolhido
- Confirmar se a alteracao foi registrada corretamente no `AI_SYNC.md`

## Formato obrigatorio de resposta no AI_SYNC
```text
## [AAAA-MM-DD HH:MM] [IA] -> [Destinatarios]
- Escopo:
- Arquivos alterados:
- Validacao executada:
- Resultado:
- Proximo passo:
```
