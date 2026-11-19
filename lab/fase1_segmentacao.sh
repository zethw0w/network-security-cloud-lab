#!/usr/bin/env bash
# Fase 1 — Demonstra a segmentação: o cliente vai temporariamente para a sub-rede B
# (192.168.50.70/26) e deixa de alcançar o servidor (sub-rede A) por não haver roteador.
# Rodar NO CLIENTE depois de `fase1_ip.sh cliente 26`. uso: sudo bash fase1_segmentacao.sh
source "$(dirname "$0")/comum.sh"
precisa_root

IFACE="$(lab_iface)"
IP_B="192.168.50.70"
ARQ="fase1_segmentacao.txt"

restaura() {
  ip addr flush dev "$IFACE"; ip addr add "$CLIENTE_IP/26" dev "$IFACE"
  netplan apply 2>/dev/null; sleep 2
  evid "$ARQ" "ip -4 -br addr show dev $IFACE" >/dev/null
}
trap restaura EXIT

titulo "$ARQ" "Estado inicial (sub-rede A)"
evid "$ARQ" "ip -4 -br addr show dev $IFACE"

titulo "$ARQ" "Cliente movido para a sub-rede B"
evid "$ARQ" "ip addr flush dev $IFACE && ip addr add $IP_B/26 dev $IFACE"
evid "$ARQ" "ip -4 -br addr show dev $IFACE"

evid "$ARQ" "ip route show dev $IFACE"
checa "$ARQ" "o servidor deixou de ser vizinho direto (rota não sai por $IFACE)" '*' "!dev $IFACE( |$)" \
  "ip route get $SERVIDOR_IP"
checa "$ARQ" "ping da sub-rede B para o servidor na sub-rede A falha" '!0' - \
  "ping -I $IFACE -c 3 -W 1 $SERVIDOR_IP"

titulo "$ARQ" "Restaurando o cliente para a sub-rede A (netplan apply)"
resumo "$ARQ"
