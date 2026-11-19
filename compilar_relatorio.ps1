<#
.SYNOPSIS
  Compila relatorio\main.pdf com LuaLaTeX dentro de um container TeX Live (não instala nada no Windows).
  Na primeira vez baixa a imagem texlive/texlive:latest-small (~0,6 GB) e instala os pacotes do abnTeX2.
#>
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
& .\rodar_lab.ps1 -SomenteCopiarCodigo | Out-Null   # código atual nos anexos
& .\gerar_resumos.ps1 | Out-Null                    # resumos da versão compacta

$nome = 'nsce-texlive'
$existe = docker ps -a --filter "name=^$nome$" --format '{{.Names}}'
if (-not $existe) {
  docker run -d --name $nome -v "$PSScriptRoot\relatorio:/doc" -w /doc texlive/texlive:latest-small sleep infinity | Out-Null
  docker exec $nome tlmgr install abntex2 memoir babel-portuges hyphen-portuguese fvextra fancyvrb upquote `
    lineno xstring tex-gyre dejavu microtype lastpage textcase enumitem bookmark latexmk fontspec xcolor etoolbox
} else {
  docker start $nome | Out-Null
}
docker exec $nome latexmk -lualatex -interaction=nonstopmode main.tex
if ($LASTEXITCODE -eq 0) { Write-Host "`nPDF gerado (compacto): relatorio\main.pdf" -ForegroundColor Green }
# Versão completa (todas as evidências e o código-fonte dos scripts)
docker exec $nome latexmk -lualatex -interaction=nonstopmode main-completo.tex
if ($LASTEXITCODE -eq 0) { Write-Host "PDF gerado (completo): relatorio\main-completo.pdf" -ForegroundColor Green }
docker stop $nome | Out-Null
