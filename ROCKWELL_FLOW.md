# 🛠️ Fluxo de Trabalho Rockwell Automation (Studio 5000)

Esta ferramenta agora suporta a análise de projetos Rockwell via arquivos de exportação `.L5X`.

## 1. Como Exportar do Studio 5000

Para que o **TIA Map** consiga ler seu projeto Rockwell, você deve exportar o projeto completo para o formato XML (`.L5X`).

1. Abra seu projeto no **Studio 5000 Logix Designer**.
2. Vá no menu **File** -> **Save As...**.
3. No campo "Save as type", selecione **Logix Designer XML File (*.L5X)**.
4. Escolha uma pasta de fácil acesso (ex: `C:\Projetos\MeuProjetoRockwell`).
5. Clique em **Save**.

---

## 2. Como Visualizar no Web Manager

1. Abra o **Web Manager** (`http://localhost:8090`).
2. No campo **CONFIGURAÇÃO DE ORIGEM**, clique em "Procurar..." ou cole o caminho da pasta onde você salvou o arquivo `.L5X`.
3. Clique em **Definir Origem**.
4. O sistema detectará automaticamente o arquivo `.L5X` (ao invés de procurar XMLs da Siemens).

---

## 3. Visualização Disponível

Ao clicar nos botões de mapa, você verá:

* **Botão 5 (Mapa Estrutural):**
    * Hierarquia: `Controller` -> `Programs` -> `Routines`.
    * Lista de `Add-On Instructions (AOI)`.

* **Botão 6 (Fluxo de Execução):**
    * O mesmo mapa acima, mas com **setas pontilhadas** indicando chamadas `JSR` (Jump to Subroutine).
    * Isso permite visualizar quem chama quem dentro das rotinas.

---

**Nota:** A ferramenta detecta automaticamente se a pasta contém um projeto Siemens (`.ap20` + exports) ou Rockwell (`.L5X`) e ajusta os diagramas sem necessidade de configuração extra.