# IMPORTAÇÃO - Instruções

Após exportarmos 15 blocos com sucesso, a próxima fase é **reconstruí-los** em um projeto TIA Portal limpo.

## Passos:

1. Abra ou crie um novo projeto TIA Portal vazio.
2. Compile e gere arquivo destino `.ap20` (pode ser um projeto em branco).
3. Na mesma sessão do TIA Portal (o projeto destino deve estar ativo), execute o importer:

```powershell
cd "C:\Users\Administrador\Documents\tirol-ipiranga-os18869_20260224_PE_V20\Logs"
.\