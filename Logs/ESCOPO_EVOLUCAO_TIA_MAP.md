# Escopo de Evolucao TIA Map (Objetivo Real)

## Problema Atual
- O mapa de execucao no Web Manager mostra poucos blocos porque o dataset atual de exportacao possui apenas 1 XML (`OB_Main`).
- O TIA Map em `localhost:5173` aparentava nao responder na busca por falta de dados carregados em runtime (CORS e backend nao acessivel em alguns cenarios).
- A interface visual estava com aparencia basica por uso de classes sem pipeline CSS completo.

## Objetivo de Produto
- Replicar a leitura de "Call Structure" do TIA Portal com fidelidade operacional:
  - `OB -> FC/FB -> DB`
  - sinalizar blocos externos/nao exportados
  - permitir busca, filtro e detalhe tecnico por bloco

## Entregas Prioritarias (Sprint)
1. Cobertura de dados:
- Reexecutar exportacao para gerar conjunto completo de XMLs (meta: >150 blocos).
- Exibir contador de cobertura no painel (XML lidos, OB/FC/FB/DB).

2. Motor de sequencia:
- Consolidar grafo de execucao por cadeia, iniciando em OBs ciclicos.
- Marcar nos desconectados e externos com legenda.

3. UX profissional:
- Padrao visual unico entre Web Manager (`8080`) e TIA Map (`5173`).
- Painel de saude do ambiente: Web/API/TIA Map.
- Mensagens tecnicas curtas e acionaveis (sem ambiguidade).

4. Validacao funcional:
- Testes de mesa com 3 cenarios:
  - dataset parcial
  - dataset completo
  - TIA aberto + exportacao + atualizacao do mapa

## Criterio de Pronto
- Usuario consegue abrir o mapa e visualizar fluxo significativo (nao apenas `OB_Main`).
- Busca filtra blocos reais no grafo.
- Interface apresenta status de saude e erros com diagnostico claro.
