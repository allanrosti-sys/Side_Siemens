# AI Collaboration Protocol (Gemini + DeepSeek + Codex)

## Goal
Keep all assistants aligned through repository files, so the user does not need to manually relay context.

## Shared Files
- `Logs/AI_SYNC.md`: running log of decisions, blockers, next actions.
- `Logs/AI_HANDOFF_TEMPLATE.md`: copy/paste template for structured handoff entries.
- `Logs/using Siemens.cs`: canonical extraction implementation (do not fork logic in parallel files).

## Update Rules
1. Before changing extraction logic, read the latest section in `Logs/AI_SYNC.md`.
2. After any relevant change, append one short handoff block in `Logs/AI_SYNC.md`.
3. Record:
   - What changed
   - Why it changed
   - What was validated
   - What remains blocked
4. Prefer additive changes; avoid deleting prior history.
5. Communication is mandatory and bidirectional:
   - If you change code/config/tests, you MUST post a handoff entry in `Logs/AI_SYNC.md`.
   - You MUST explicitly ask other assistants to report their own changes in the same file.
   - No silent changes are allowed.

## Code Documentation Rules
1. Keep high-value comments in `Logs/using Siemens.cs`:
   - intent of each major step
   - API assumptions (TIA V20/V19 behaviors)
   - error/timeout rationale
2. Do not add noisy comments that repeat obvious syntax.

## Validation Rules
1. Compile with:
   - `C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe`
   - reference: `C:\Program Files\Siemens\Automation\Portal V20\PublicAPI\V20\Siemens.Engineering.dll`
2. Runtime test command:
   - `.\Logs\TiaProjectExporter_v20.exe --no-attach .\tirol-ipiranga-os18869_20260224_PE_V20.ap20 .\Logs\ControlModules_Export`
3. If blocked by TIA Openness prompts, log it in `AI_SYNC.md` and do not mask the issue.
