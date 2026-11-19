<#
.SYNOPSIS
  Executa as fases do laboratório nas VMs do Vagrant, na ordem do enunciado.
  As evidências ficam em relatorio\evidencias\ (pasta compartilhada /vagrant).
.EXAMPLE
  .\rodar_lab.ps1            # todas as fases
  .\rodar_lab.ps1 -Fase 2,4  # só as fases 2 e 4
  .\rodar_lab.ps1 -SomenteCopiarCodigo  # só atualiza relatorio\anexos\codigo
#>
param([int[]]$Fase = @(1, 2, 3, 4), [switch]$SomenteCopiarCodigo)

Set-Location $PSScriptRoot
$script:falhas = @()

# Cópia do código usado na execução para os anexos do relatório.
$destino = Join-Path $PSScriptRoot 'relatorio\anexos\codigo'
New-Item -ItemType Directory -Force $destino | Out-Null
Copy-Item (Join-Path $PSScriptRoot 'Vagrantfile'), (Join-Path $PSScriptRoot 'lab\*.sh'), (Join-Path $PSScriptRoot 'lab\*.json') $destino -Force
if ($SomenteCopiarCodigo) { Write-Host "Código copiado para $destino"; exit 0 }

function Invoke-NaVM([string]$vm, [string]$cmd) {
  Write-Host ">> [$vm] $cmd" -ForegroundColor Cyan
  vagrant ssh $vm -c $cmd
  if ($LASTEXITCODE -ne 0) {
    Write-Warning "[$vm] terminou com código $LASTEXITCODE`: $cmd"
    $script:falhas += "[$vm] $cmd"
  }
}

$L = '/vagrant/lab'
if ($Fase -contains 1) {
  # Re-execução: volta ao estado inicial do enunciado — sem firewall e sem o SILO rodando
  # (a Fase 2 reconfigura o firewall do zero e a Fase 3 sobe o SILO de novo).
  Invoke-NaVM servidor "sudo ufw --force disable >/dev/null 2>&1; sudo systemctl stop silo-lab 2>/dev/null; true"
  Invoke-NaVM servidor "sudo bash $L/fase1_ip.sh servidor 24"
  Invoke-NaVM cliente  "sudo bash $L/fase1_ip.sh cliente 24"
  Invoke-NaVM cliente  "bash $L/fase1_testes.sh 24"
  Invoke-NaVM cliente  "bash $L/fase1_subredes.sh"
  Invoke-NaVM servidor "sudo bash $L/fase1_ip.sh servidor 26"
  Invoke-NaVM cliente  "sudo bash $L/fase1_ip.sh cliente 26"
  Invoke-NaVM cliente  "bash $L/fase1_testes.sh 26"
  Invoke-NaVM cliente  "sudo bash $L/fase1_segmentacao.sh"
}
if ($Fase -contains 2) {
  Invoke-NaVM servidor "sudo bash $L/fase2_servicos.sh"
  Invoke-NaVM cliente  "sudo bash $L/fase2_scan.sh antes"
  Invoke-NaVM servidor "sudo bash $L/fase2_firewall.sh"
  Invoke-NaVM cliente  "sudo bash $L/fase2_scan.sh depois"
}
if ($Fase -contains 3) {
  Invoke-NaVM servidor "sudo bash $L/fase3_silo.sh"
  Invoke-NaVM servidor "sudo bash $L/fase3_bucket.sh publico"
  Invoke-NaVM servidor "sudo bash $L/fase3_bucket.sh privado"
}
if ($Fase -contains 4) {
  Invoke-NaVM servidor "sudo bash $L/fase4_servidor.sh"
  Invoke-NaVM cliente  "sudo bash $L/fase4_cliente.sh"
}

if ($script:falhas.Count -eq 0) {
  Write-Host "`nTodas as etapas terminaram sem erro. Evidências em relatorio\evidencias\" -ForegroundColor Green
} else {
  Write-Host "`nEtapas com erro:" -ForegroundColor Red
  $script:falhas | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
  exit 1
}
