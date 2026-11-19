#!/usr/bin/env bash
# Fase 1 — Conectividade cliente -> servidor (ping e ssh). Rodar NO CLIENTE, sem sudo.
# uso: bash fase1_testes.sh <24|26>
source "$(dirname "$0")/comum.sh"
PREFIXO="${1:-24}"
ARQ="fase1_conectividade_${PREFIXO}.txt"
SSH_USER="${LAB_SSH_USER:-$(id -un)}"
SSH_OPTS="-o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new"
[ -f "$HOME/.ssh/id_lab" ] && SSH_OPTS="$SSH_OPTS -i $HOME/.ssh/id_lab"

checa "$ARQ" "ping cliente -> servidor (/$PREFIXO)" 0 " 0% packet loss" \
  "ping -c 4 $SERVIDOR_IP"
checa "$ARQ" "ssh cliente -> servidor (/$PREFIXO)" 0 "$SERVIDOR_IP" \
  "ssh $SSH_OPTS $SSH_USER@$SERVIDOR_IP 'hostname; ip -4 -br addr'"
resumo "$ARQ"
