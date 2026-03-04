# Plano de Ação - Executável Robusto (TIA Exporter)

## Objetivo
Gerar e validar um executável robusto para exportação de blocos OB/FB/FC via TIA Openness, com operação estável em ambiente real.

## Regras de Comunicação
- Toda comunicação entre IAs deve ser em português.
- Toda alteração de código/scripts deve ser registrada em `Logs/AI_SYNC.md` com:
  - arquivo alterado
  - resumo da mudança
  - comando de validação
  - resultado da validação

## Fase 1 - Estabilização de Ambiente (bloqueios Openness)
- Dono principal: Copilot
- Apoio: Codex
- Entregáveis:
  - garantir somente 1 instância relevante do TIA Portal para o projeto alvo
  - validar/limpar bloqueios de attach (prompt Openness e estado modal do TIA)
  - consolidar script operacional de attach (`RunExporterWithAttach*.ps1`)
- Critério de aceite:
  - attach concluído sem timeout no processo correto

## Fase 2 - Robustez do Exportador (código C#)
- Dono principal: Codex
- Apoio: Gemini
- Entregáveis:
  - estratégia attach-priority por `ProjectPath`
  - logs mais claros por etapa (attach, compile, export, resumo final)
  - códigos de saída padronizados para diagnóstico
  - tratamento consistente de timeout/erros de lock/read-only
- Critério de aceite:
  - execução sem travamento
  - mensagens de erro acionáveis

## Fase 3 - Build Reprodutível do Executável
- Dono principal: Copilot
- Apoio: Codex
- Entregáveis:
  - comando oficial de build documentado
  - executável final no workspace
  - script único de execução para operação
- Critério de aceite:
  - build limpo
  - execução por script sem intervenção técnica adicional

## Fase 4 - Validação Funcional de Export
- Dono principal: Codex
- Apoio: Copilot
- Entregáveis:
  - contagem de XML > 0
  - listagem dos 10 primeiros arquivos exportados
  - evidência de estrutura de pastas preservada
- Critério de aceite:
  - arquivos `OB_*.xml`, `FB_*.xml`, `FC_*.xml` gerados corretamente

## Fase 5 - Documentação e Handover
- Dono principal: Gemini
- Apoio: Codex/Copilot
- Entregáveis:
  - documentação operacional final em português
  - instruções de troubleshooting
  - procedimento de execução diária
- Critério de aceite:
  - documentação coerente com estado real do filesystem e logs

## Checklist de Conclusão
- [x] Attach estável sem timeout
- [x] Executável final gerado e versionado no workspace
- [x] Export com XML > 0 validado por comando
- [x] Logs e códigos de saída padronizados
- [x] Documentação final atualizada e consistente
