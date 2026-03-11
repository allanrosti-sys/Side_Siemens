# 📘 Estudos Iniciais: Automação TIA Portal

**Autor:** Allan Rostirolla  
**Líder Técnico AI:** Gemini  
**Data:** 27/02/2026

---

## 1. O que estamos fazendo aqui?

Imagine que o projeto do PLC (o "cérebro" da máquina) é como um livro gigante escrito à mão. Se quisermos copiar uma página para outro livro, ou verificar se alguém mudou uma vírgula, é muito difícil fazer isso manualmente.

Neste projeto, criamos **robôs de software** (scripts) que:
1. **Leem o livro (Exportação):** Entram no TIA Portal, leem todo o código e salvam cada bloco (FC, FB, OB) como um arquivo de texto separado (XML).
2. **Guardam no cofre (Git):** Salvam esses arquivos em um sistema seguro que registra quem mudou o quê e quando.
3. **Escrevem no livro (Importação):** Pegam arquivos de texto corrigidos ou novos e os escrevem de volta dentro do TIA Portal automaticamente.

## 2. Por que isso é importante?

- **Segurança:** Nunca mais perderemos uma versão funcional do código.
- **Agilidade:** Podemos criar 50 blocos de motor no Excel ou VS Code e importá-los em segundos, em vez de criar um por um com o mouse.
- **Padronização:** Garantimos que todos os blocos sigam as mesmas regras de nome e estrutura.

## 3. Glossário para Leigos

| Termo | O que significa na prática? |
|-------|-----------------------------|
| **TIA Openness** | É a "porta dos fundos" do TIA Portal que permite que nossos robôs entrem e mexam nos dados sem precisar de um humano clicando. |
| **XML** | É um formato de arquivo de texto que tanto humanos quanto computadores conseguem ler. É como transformamos o código do PLC em texto puro. |
| **SCL** | Linguagem de programação do PLC (parecida com Pascal/Inglês). É o texto que escrevemos no VS Code. |
| **Headless** | Modo "sem cabeça". Significa que o software roda escondido, sem abrir janelas na tela, trabalhando em segundo plano. |
| **Attach** | "Grudar". É quando nossa ferramenta se conecta a um TIA Portal que já está aberto na sua tela. |

## 4. Como funciona o nosso fluxo?

1. **Você** abre o TIA Portal.
2. **Você** roda nosso script (`Run-Full-Cycle`).
3. **O Script** faz um backup do que está lá.
4. **O Script** pega os novos códigos que você escreveu no VS Code.
5. **O Script** injeta esses códigos no TIA Portal.
6. Tudo pronto!

---
*Documentação aprovada por Allan Rostirolla.*