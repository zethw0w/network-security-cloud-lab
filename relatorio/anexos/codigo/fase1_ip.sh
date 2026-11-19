#!/usr/bin/env bash
# Fase 1 — IP estático na interface do laboratório (netplan).
# uso: sudo bash fase1_ip.sh <servidor|cliente> <24|26>
source "$(dirname "$0")/comum.sh"
precisa_root

PAPEL="${1:?uso: fase1_ip.sh <servidor|cliente> <24|26>}"
PREFIXO="${2:-24}"
case "$PAPEL" in
  servidor) IP="$SERVIDOR_IP" ;;
  cliente)  IP="$CLIENTE_IP" ;;
  *) erro "papel inválido: $PAPEL" ;;
esac
case "$PREFIXO" in 24|26) ;; *) erro "prefixo deve ser 24 ou 26" ;; esac

IFACE="$(lab_iface)"
[ -n "$IFACE" ] || erro "interface do laboratório não encontrada; defina LAB_IFACE"
ARQ="fase1_ip_${PAPEL}_${PREFIXO}.txt"

cat > /etc/netplan/60-lab.yaml <<EOF
# Rede do laboratório — $PAPEL ($IP/$PREFIXO)
network:
  version: 2
  ethernets:
    $IFACE:
      dhcp4: false
      addresses: [$IP/$PREFIXO]
EOF
# Arquivos do netplan não devem ser legíveis por outros usuários (evita os avisos do netplan).
chmod 600 /etc/netplan/*.yaml

titulo "$ARQ" "Configuração netplan aplicada em $IFACE"
evid "$ARQ" "cat /etc/netplan/60-lab.yaml"
evid "$ARQ" "netplan apply && sleep 2"
evid "$ARQ" "ip -4 -br addr show dev $IFACE"
evid "$ARQ" "ip route show dev $IFACE"
