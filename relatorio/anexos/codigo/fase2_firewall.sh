#!/usr/bin/env bash
# Fase 2 — Firewall do servidor (ufw): entrada negada por padrão; só TCP/8080 vindo do cliente.
# Rodar NO SERVIDOR. uso: sudo bash fase2_firewall.sh
#   PERMITIR_SSH_CLIENTE=1  também libera SSH (22) vindo do cliente (leitura alternativa da Fase 2).
#   LAB_VAGRANT_MGMT=0      não cria a exceção de gerência do Vagrant (ver README).
source "$(dirname "$0")/comum.sh"
precisa_root
IFACE="$(lab_iface)"
ARQ="fase2_firewall.txt"

titulo "$ARQ" "Estado antes da configuração"
evid "$ARQ" "ufw status verbose"

titulo "$ARQ" "Regras aplicadas"
evid "$ARQ" "ufw --force reset"
evid "$ARQ" "ufw default deny incoming"
evid "$ARQ" "ufw default allow outgoing"
evid "$ARQ" "ufw default deny routed"
evid "$ARQ" "ufw allow in on $IFACE proto tcp from $CLIENTE_IP to $SERVIDOR_IP port 8080 comment 'Fase 2: HTTP 8080 somente da VM cliente'"
if [ "${PERMITIR_SSH_CLIENTE:-0}" = "1" ]; then
  evid "$ARQ" "ufw allow in on $IFACE proto tcp from $CLIENTE_IP to $SERVIDOR_IP port 22 comment 'Fase 2: SSH somente da VM cliente'"
fi
if eh_vagrant; then
  # O adaptador NAT do Vagrant não faz parte da rede do laboratório; sem esta exceção
  # o `vagrant ssh` deixa de funcionar. O host chega pela NAT como 10.0.2.2.
  evid "$ARQ" "ufw allow in on $(mgmt_iface) proto tcp from 10.0.2.2 to any port 22 comment 'Gerencia Vagrant via NAT (fora da rede do lab)'"
fi
evid "$ARQ" "ufw logging low"
evid "$ARQ" "ufw --force enable"

titulo "$ARQ" "Estado depois da configuração"
evid "$ARQ" "ufw status verbose"
evid "$ARQ" "ufw status numbered"
evid "$ARQ" "iptables -S ufw-user-input"
