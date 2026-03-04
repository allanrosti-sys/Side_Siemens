# Proposta de Padronização (Gemini)

## 1. Convenção de Nomes (IEC 61131-3 / Siemens Style)

### Blocos
- **Function Blocks (FB):** `FB_<Substantivo><Ação>`
  - Ex: `FB_MotorControl`, `FB_PidRegulator`
- **Functions (FC):** `FC_<Verbo><Substantivo>`
  - Ex: `FC_CalculateOee`, `FC_CheckInterlocks`
- **Data Blocks (DB):** `DB_<NomeDescritivo>` ou `inst<NomeFB>`

### Variáveis (Prefixos Húngaros Simplificados)
- **Input:** `i_<Nome>` (Ex: `i_xStart`, `i_rSetPoint`)
- **Output:** `q_<Nome>` (Ex: `q_xRunning`, `q_rActualValue`)
- **InOut:** `iq_<Nome>`
- **Static:** `s_<Nome>`
- **Temp:** `t_<Nome>`
- **Constant:** `c_<Nome>`

### Tipos de Dados (Prefixos)
- `x` = Bool (Ex: `i_xEnable`)
- `i` = Int/DInt (Ex: `q_iStatus`)
- `r` = Real/LReal (Ex: `i_rTemperature`)
- `s` = String (Ex: `s_sBarcode`)
- `t` = Time (Ex: `c_tTimeout`)

## 2. Padrão de Códigos de Status (State Machine / HMI)

Padronização para facilitar animação em IHM e diagnóstico em SCADA.

| Range | Categoria | Cor Sugerida (HMI) | Descrição |
|-------|-----------|--------------------|-----------|
| **0** | Parado | Cinza | Pronto / Standby / Desligado |
| **1-9** | Inicialização | Verde Piscante | Sequência de partida / Pré-check |
| **10-19** | Rodando | Verde Sólido | Operação normal / Em ciclo |
| **20-29** | Aviso | Amarelo | Operação degradada / Warning (sem parada) |
| **30-89** | Falha | Vermelho | Falha de processo / Intertravamento |
| **90-99** | Segurança | Vermelho Piscante | Emergência / Cortina de luz / Safety |

### Exemplo de Implementação (SCL)
```scl
CASE #s_iState OF
    0:  #s_sStateText := 'PRONTO';
    10: #s_sStateText := 'RODANDO';
    30: #s_sStateText := 'FALHA MOTOR';
    99: #s_sStateText := 'EMERGENCIA';
END_CASE;
```