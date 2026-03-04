# Estratégia de Reuso e Testes (Gemini)

## 1. Estratégia de Reuso de Código (Library-Oriented)

Para garantir que `FB_MonitorAtivo` e `FC_GerenciadorStatus` sejam reutilizáveis em múltiplos projetos (Tirol, Ipiranga, etc.), propomos:

### A. Encapsulamento Estrito
- **Regra:** NENHUM acesso a variáveis globais (Tags `M`, `I`, `Q` ou DBs globais) dentro da lógica do bloco.
- **Interface:** Toda comunicação deve ser via `Input`, `Output` ou `InOut`.
- **Benefício:** O bloco pode ser copiado para qualquer projeto sem quebrar referências ("compile error free").

### B. Uso de UDTs (PLC Data Types)
- Em vez de passar 10 booleanos para um FB, criar um UDT padrão.
- **Exemplo:** `typeAtivoCmd` (Ligar, Reset, Manual) e `typeAtivoStatus` (Ligado, Falha, Pronto).
- **Ação:** Definir UDTs correspondentes nos próximos passos.

### C. Versionamento Semântico no Cabeçalho
- Manter histórico no header do SCL:
  ```scl
  // v1.0.0 - Versão Inicial
  // v1.1.0 - Adicionado timeout de feedback
  ```

## 2. Padrão de Testes em Simulação

Como validar os blocos sem hardware físico?

### A. Bloco de Teste Unitário (`FB_TestRunner`)
- Criar um FB dedicado apenas para testar a lógica.
- **Vetor de Teste:**
  1. Ativar `i_xLigar`.
  2. Verificar se `o_xAtivoLigado` vai para TRUE.
  3. Simular falha de feedback (não ativar `i_fbConfirmacao`).
  4. Verificar se `o_xEmFalha` vai para TRUE após 5s.
- **Automação:** O `FB_TestRunner` gera um bit `q_xTestPassed` se a lógica se comportar como esperado.

### B. Ciclo de Validação (CI/CD Local)
1. **Edit:** Alterar SCL no VS Code.
2. **Push:** Script `Run-Full-Cycle.ps1` (já existente).
3. **Simulate:** (Futuro) Script que conecta ao PLCSIM Advanced, carrega o bloco e monitora o `FB_TestRunner`.

---
**Status:** Proposta pronta para revisão do Codex.