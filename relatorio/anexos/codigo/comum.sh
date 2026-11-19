#!/usr/bin/env bash
# Variáveis e funções comuns a todos os scripts do laboratório.
# Cada comando relevante é executado via `evid`, que grava comando + saída + código
# de saída em relatorio/evidencias/<arquivo>.txt (usado pelos anexos do relatório).

set -uo pipefail

LAB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RAIZ="$(cd "$LAB_DIR/.." && pwd)"
export LAB_DIR RAIZ
export EVID_DIR="${EVID_DIR:-$RAIZ/relatorio/evidencias}"

export SERVIDOR_IP="${SERVIDOR_IP:-192.168.50.10}"
export CLIENTE_IP="${CLIENTE_IP:-192.168.50.20}"
export BUCKET="lab-bucket"
export BUCKET_OUTRO="outro-bucket"
export LAB_USUARIO="lab-user"
export POLITICA="lab-rw"
export S3_URL="http://127.0.0.1:9000"
export MCLI="mcli --config-dir /root/.mcli-lab"

mkdir -p "$EVID_DIR"

FALHAS=0
TOTAL=0
_F=""
_SAIDA=""
_RC=0
declare -A _EVID_INICIADO=()

erro() { echo "ERRO: $*" >&2; exit 1; }

precisa_root() { [ "$(id -u)" -eq 0 ] || erro "rode com sudo: sudo bash $0"; }

# Na primeira escrita desta execução, recria o arquivo de evidência com um cabeçalho.
_inicia() {
  _F="$EVID_DIR/$1"
  if [ -z "${_EVID_INICIADO[$1]:-}" ]; then
    printf '# %s | host: %s | script: %s | %s\n' \
      "$1" "$(hostname)" "$(basename "$0")" "$(date '+%Y-%m-%d %H:%M:%S %Z')" > "$_F"
    _EVID_INICIADO[$1]=1
  fi
}

# titulo <arquivo> <texto>
titulo() {
  _inicia "$1"
  printf '\n### %s\n' "$2" | tee -a "$_F"
}

# evid <arquivo> "<comando>" — executa o comando, mostra na tela e grava na evidência.
# Segredos devem ser passados como \$VARIAVEL para aparecerem mascarados no registro.
evid() {
  _inicia "$1"
  _SAIDA="$(bash -c "$2" 2>&1)"
  _RC=$?
  printf '$ %s\n%s\n[código de saída: %d]\n' "$2" "$_SAIDA" "$_RC" | tee -a "$_F"
  return "$_RC"
}

# checa <arquivo> <descrição> <0|!0|*> <regex|!regex|-> "<comando>"
# Passa se o código de saída bate com o esperado (* = qualquer) E a saída casa com a
# regex ("!regex" = NÃO pode casar; "-" = não verifica a saída).
checa() {
  local arq=$1 desc=$2 esperado=$3 padrao=$4 cmd=$5 ok_rc=0 ok_re=0 veredito
  TOTAL=$((TOTAL + 1))
  titulo "$arq" "Teste $TOTAL: $desc"
  evid "$arq" "$cmd"
  case "$esperado" in
    0)    [ "$_RC" -eq 0 ] && ok_rc=1 ;;
    '!0') [ "$_RC" -ne 0 ] && ok_rc=1 ;;
    *)    ok_rc=1 ;;
  esac
  if [ "$padrao" = "-" ]; then ok_re=1
  elif [ "${padrao:0:1}" = "!" ]; then grep -Eqi -- "${padrao:1}" <<<"$_SAIDA" || ok_re=1
  else grep -Eqi -- "$padrao" <<<"$_SAIDA" && ok_re=1; fi
  if [ "$ok_rc" = 1 ] && [ "$ok_re" = 1 ]; then veredito="PASSOU"
  else veredito="FALHOU"; FALHAS=$((FALHAS + 1)); fi
  printf '=> RESULTADO: %s (esperado: código %s; saída contendo: %s)\n' \
    "$veredito" "$esperado" "$padrao" | tee -a "$_F"
}

# resumo <arquivo> — fecha o arquivo com o placar e devolve != 0 se algo falhou.
resumo() {
  titulo "$1" "Resumo: $TOTAL teste(s), $FALHAS falha(s)"
  [ "$FALHAS" -eq 0 ]
}

# Interface da rede do laboratório: LAB_IFACE, ou a placa com MAC 08:00:27:50:00:xx
# (definido no Vagrantfile), ou a segunda interface que não é loopback.
lab_iface() {
  if [ -n "${LAB_IFACE:-}" ]; then echo "$LAB_IFACE"; return; fi
  local d
  for d in /sys/class/net/*; do
    case "$(cat "$d/address" 2>/dev/null)" in
      08:00:27:50:00:*) basename "$d"; return ;;
    esac
  done
  ip -o link show | awk -F': ' '$2 != "lo" {print $2}' | sed -n 2p
}

# Interface da rota padrão (no Vagrant, o adaptador NAT de gerência).
mgmt_iface() { ip route show default | awk '{print $5; exit}'; }

# Verdadeiro quando rodando em VM do Vagrant (e a exceção de gerência não foi desligada).
eh_vagrant() { [ -d /vagrant ] && id vagrant >/dev/null 2>&1 && [ "${LAB_VAGRANT_MGMT:-1}" = "1" ]; }

# Carrega credenciais do SILO e garante o alias "root" do mcli.
carrega_silo() {
  [ -f /etc/silo-lab.env ] || erro "SILO não instalado; rode antes: sudo bash $LAB_DIR/fase3_silo.sh"
  set -a; . /etc/silo-lab.env; set +a
  [ -f /root/.silo-lab-user ] && { set -a; . /root/.silo-lab-user; set +a; }
  $MCLI alias set root "$S3_URL" "$MINIO_ROOT_USER" "$MINIO_ROOT_PASSWORD" >/dev/null
}
