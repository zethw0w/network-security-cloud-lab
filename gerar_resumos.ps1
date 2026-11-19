<#
.SYNOPSIS
  Gera os resumos usados na versão compacta do relatório (relatorio\evidencias\r_*.txt).
  - fase4_*.txt: só os títulos (###) e os vereditos (=> RESULTADO / Resumo).
  - manual_fase3_bucket_*.txt: linhas truncadas (as respostas XML são muito longas).
  Os arquivos completos não são alterados; a versão completa do relatório continua usando-os.
#>
$ev = Join-Path $PSScriptRoot 'relatorio\evidencias'
$utf8 = New-Object System.Text.UTF8Encoding($false)

foreach ($nome in 'fase4_servidor.txt', 'fase4_cliente.txt') {
  $src = Join-Path $ev $nome
  if (-not (Test-Path $src)) { continue }
  $linhas = Get-Content $src -Encoding UTF8 | Where-Object { $_ -match '^(# |### |=> RESULTADO)' }
  [IO.File]::WriteAllLines((Join-Path $ev "r_$nome"), $linhas, $utf8)
}

foreach ($nome in 'manual_fase3_bucket_publico.txt', 'manual_fase3_bucket_privado.txt') {
  $src = Join-Path $ev $nome
  if (-not (Test-Path $src)) { continue }
  $linhas = Get-Content $src -Encoding UTF8 | ForEach-Object {
    if ($_.Length -gt 105) { $_.Substring(0, 102) + '...' } else { $_ }
  }
  # no JSON da política, mantém só as linhas relevantes (Principal, Action, DeleteObject etc.)
  $linhas = $linhas | Where-Object { $_ -notmatch '^\s+("s3:(Abort|ListMultipart|ListBucketMultipart)|\])' }
  [IO.File]::WriteAllLines((Join-Path $ev "r_$nome"), $linhas, $utf8)
}
Write-Host 'Resumos gerados em relatorio\evidencias\r_*.txt'
