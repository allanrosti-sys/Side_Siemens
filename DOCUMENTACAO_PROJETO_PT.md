# Documentacao do Puchta PLC Insight

## Resumo

O projeto evoluiu de um painel focado em TIA Portal para uma plataforma de analise multi-vendor.

Objetivo atual:
- preparar a origem do projeto a partir da interface principal;
- escolher o vendor antes da pasta ou arquivo;
- manter um contrato unico de grafo para Siemens e Rockwell;
- abrir o app web de analise com contexto coerente ao vendor escolhido.

## Nome oficial

- Nome atual do produto: `Puchta PLC Insight`
- Nome legado: `TIA Map`
- Uso recomendado em interface, documentacao e backlog: sempre `Puchta PLC Insight`

## Fluxo principal da interface

1. Escolher `Auto`, `Siemens` ou `Rockwell`.
2. Informar a pasta raiz do projeto.
3. Salvar a configuracao para persistir `vendor` e `tiaPath`.
4. Executar as acoes disponiveis para a origem.
5. Abrir o mapa completo no app React/FastAPI quando necessario.

## Regras por vendor

### Siemens

- Terminologia principal: `OB`, `FB`, `FC`, `DB`
- Origem suportada:
  - raiz do projeto TIA;
  - pasta com XMLs exportados;
  - pasta contendo `Logs/ControlModules_Export`
- Exportacao direta suportada pelo painel legado via scripts TIA.

### Rockwell

- Terminologia principal: `Task`, `MainProgram`, `Routine`, `AOI`, `Tags/Data`
- Origem suportada:
  - pasta contendo um arquivo `.L5X`
- O painel legado nao exporta projeto Rockwell; a analise parte de um `.L5X` previamente exportado.

## Backend

O backend novo em `tia-map/backend/core/` adota arquitetura multi-vendor:

- `plc_parser.py`: contrato base de parser
- `siemens_parser.py`: parser Siemens
- `rockwell_parser.py`: parser Rockwell `.L5X`
- `pipeline.py`: deteccao de vendor e execucao do pipeline
- `builder.py`: montagem padronizada de nos e arestas

O endpoint de grafo aceita:

- `vendor=auto`
- `vendor=siemens`
- `vendor=rockwell`

## Painel legado

O painel legado em `Logs/` continua sendo o ponto de entrada operacional rapido.

Responsabilidades atuais:
- persistir `tiaPath` e `vendor` em `Logs/web_settings.json`;
- exibir a escolha de vendor antes da pasta;
- ajustar labels e legenda conforme o vendor efetivo;
- chamar scripts auxiliares;
- abrir Mermaid estrutural e de execucao.

## Cores padrao

### Siemens

- `OB`: roxo
- `FB`: azul
- `FC`: verde
- `DB / Dados`: cinza

### Rockwell

- `MainProgram`: vermelho
- `Routine`: verde
- `AOI`: azul
- `Tags / Data`: cinza

## Governanca

- Registro oficial de mudancas: `Logs/AI_SYNC.md`
- Quadro oficial de tarefas: `Logs/AI_TASK_BOARD.md`
- Toda alteracao relevante deve registrar:
  - escopo;
  - arquivos alterados;
  - validacao executada;
  - resultado;
  - proximo passo.

## Guia de Uso da Interface Web

O painel de operaÃ§Ã£o web (`Puchta PLC Insight`) foi projetado para ser intuitivo. Siga os passos abaixo para analisar seus projetos.

### 1. ConfiguraÃ§Ã£o de Origem

Esta Ã© a etapa mais importante. Aqui vocÃª define qual projeto e de qual fabricante serÃ¡ analisado.

1.  **Escolha o Fabricante (Vendor):** No primeiro menu, selecione `Siemens`, `Rockwell`, ou `Auto detectar`. A interface se adaptarÃ¡ Ã  sua escolha.
2.  **Selecione a Pasta do Projeto:**
    *   Clique no botÃ£o **"Procurar..."**. Uma janela do sistema operacional serÃ¡ aberta.
    *   Navegue atÃ© a pasta raiz do seu projeto (a que contÃ©m o `.ap20` para Siemens ou o `.L5X` para Rockwell) e clique em "OK".
    *   **Importante:** ApÃ³s a seleÃ§Ã£o, a interface irÃ¡ detectar automaticamente a sua escolha e preencher o campo de texto com o caminho selecionado. Aguarde um instante para que o caminho apareÃ§a.
3.  **Salve e Valide:** Com o caminho preenchido, clique em **"Salvar e validar"**. O sistema irÃ¡ verificar a pasta, confirmar o tipo de projeto e habilitar as aÃ§Ãµes no passo 2.

### 2. AÃ§Ãµes do Projeto

Uma vez que a origem estÃ¡ configurada, as seguintes aÃ§Ãµes ficam disponÃ­veis:

-   **Exportar XML (Siemens):** Inicia o processo de backup dos blocos do projeto TIA Portal em formato XML. NecessÃ¡rio para as anÃ¡lises.
-   **Mapa Estrutural / Fluxo de ExecuÃ§Ã£o:** Estes botÃµes abrem um visualizador de diagrama (`Mermaid`).
    -   **Interatividade:** Os diagramas sÃ£o totalmente interativos. VocÃª pode usar o **scroll do mouse para dar zoom** e **clicar e arrastar para mover (pan)** o diagrama, facilitando a navegaÃ§Ã£o em projetos grandes.
-   **Abrir Puchta PLC Insight:** Inicia a aplicaÃ§Ã£o de anÃ¡lise visual completa para uma exploraÃ§Ã£o aprofundada do projeto.
-   **Importar Blocos / DocumentaÃ§Ã£o HTML:** FunÃ§Ãµes auxiliares para gerenciamento do projeto.

### 3. SoluÃ§Ã£o de Problemas Comuns

-   **O caminho nÃ£o atualiza apÃ³s selecionar a pasta:** Garanta que vocÃª clicou em "OK" na janela de seleÃ§Ã£o. A interface irÃ¡ detectar a mudanÃ§a em poucos segundos. Se nÃ£o detectar, usar o botÃ£o de reiniciar (â†») pode resolver problemas de cache do servidor.
-   **Diagramas nÃ£o abrem ou aparecem em branco:** O painel "Logs de execuÃ§Ã£o" Ã© seu principal aliado. Ele Ã© limpo a cada nova aÃ§Ã£o e atualiza automaticamente por alguns segundos, mostrando o progresso. Verifique-o para mensagens de erro.
-   **Diagrama Rockwell mostra erro de ".L5X nÃ£o encontrado":** Isso significa que a pasta que vocÃª selecionou como "Origem" nÃ£o contÃ©m um arquivo `.L5X` diretamente ou em um subdiretÃ³rio. Verifique se a pasta estÃ¡ correta ou exporte o arquivo `.L5X` do Studio 5000 novamente.
-   **AÃ§Ãµes parecem nÃ£o funcionar:** Se os botÃµes nÃ£o responderem ou o log nÃ£o atualizar, a primeira medida Ã© sempre reiniciar o servidor web clicando no botÃ£o (â†») na interface.

## Estado atual

- O backend novo suporta Siemens e Rockwell.
- O painel legado ja permite selecionar o vendor antes da origem.
- O nome visual principal foi migrado para `Puchta PLC Insight`.
- O proximo passo natural e unificar ainda mais a experiencia entre o painel legado e o app `tia-map`.

## Atualizacoes Recentes (2026-03-11)

- Painel Web:
  - Selecao de origem com popup em primeiro plano (TopMost).
  - Polling de selecao com timeout estavel e sem travar a UI ao cancelar.
  - Botao "Abrir Puchta PLC Insight" alinhado ao padrao visual dos demais.
  - TiaMap-Dev nao bloqueia os outros botoes.
  - Documentacao libera a UI imediatamente apos abrir o HTML.
  - Documentacao Siemens e Rockwell com rotas separadas.
- Rockwell:
  - Gerador `Generate-Documentation-Rockwell.ps1`.
  - Parser L5K/L5X com decodificacao de entidades.
  - Conversao RC/N -> ST no visualizador (mantendo tags como comentarios).
- Siemens:
  - Fluxos de exportacao e mapas seguem compativeis com o painel.

