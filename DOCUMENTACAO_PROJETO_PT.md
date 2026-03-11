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

O painel de operação web (`Puchta PLC Insight`) foi projetado para ser intuitivo. Siga os passos abaixo para analisar seus projetos.

### 1. Configuração de Origem

Esta é a etapa mais importante. Aqui você define qual projeto e de qual fabricante será analisado.

1.  **Escolha o Fabricante (Vendor):** No primeiro menu, selecione `Siemens`, `Rockwell`, ou `Auto detectar`. A interface se adaptará à sua escolha.
2.  **Selecione a Pasta do Projeto:**
    *   Clique no botão **"Procurar..."**. Uma janela do sistema operacional será aberta.
    *   Navegue até a pasta raiz do seu projeto (a que contém o `.ap20` para Siemens ou o `.L5X` para Rockwell) e clique em "OK".
    *   **Importante:** Após a seleção, a interface irá detectar automaticamente a sua escolha e preencher o campo de texto com o caminho selecionado. Aguarde um instante para que o caminho apareça.
3.  **Salve e Valide:** Com o caminho preenchido, clique em **"Salvar e validar"**. O sistema irá verificar a pasta, confirmar o tipo de projeto e habilitar as ações no passo 2.

### 2. Ações do Projeto

Uma vez que a origem está configurada, as seguintes ações ficam disponíveis:

-   **Exportar XML (Siemens):** Inicia o processo de backup dos blocos do projeto TIA Portal em formato XML. Necessário para as análises.
-   **Mapa Estrutural / Fluxo de Execução:** Estes botões abrem um visualizador de diagrama (`Mermaid`).
    -   **Interatividade:** Os diagramas são totalmente interativos. Você pode usar o **scroll do mouse para dar zoom** e **clicar e arrastar para mover (pan)** o diagrama, facilitando a navegação em projetos grandes.
-   **Abrir Puchta PLC Insight:** Inicia a aplicação de análise visual completa para uma exploração aprofundada do projeto.
-   **Importar Blocos / Documentação HTML:** Funções auxiliares para gerenciamento do projeto.

### 3. Solução de Problemas Comuns

-   **O caminho não atualiza após selecionar a pasta:** Garanta que você clicou em "OK" na janela de seleção. A interface irá detectar a mudança em poucos segundos. Se não detectar, usar o botão de reiniciar (↻) pode resolver problemas de cache do servidor.
-   **Diagramas não abrem ou aparecem em branco:** O painel "Logs de execução" é seu principal aliado. Ele é limpo a cada nova ação e atualiza automaticamente por alguns segundos, mostrando o progresso. Verifique-o para mensagens de erro.
-   **Diagrama Rockwell mostra erro de ".L5X não encontrado":** Isso significa que a pasta que você selecionou como "Origem" não contém um arquivo `.L5X` diretamente ou em um subdiretório. Verifique se a pasta está correta ou exporte o arquivo `.L5X` do Studio 5000 novamente.
-   **Ações parecem não funcionar:** Se os botões não responderem ou o log não atualizar, a primeira medida é sempre reiniciar o servidor web clicando no botão (↻) na interface.

## Estado atual

- O backend novo suporta Siemens e Rockwell.
- O painel legado ja permite selecionar o vendor antes da origem.
- O nome visual principal foi migrado para `Puchta PLC Insight`.
- O proximo passo natural e unificar ainda mais a experiencia entre o painel legado e o app `tia-map`.
