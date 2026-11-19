#!/usr/bin/env bash
# Fase 2 — Varredura do servidor a partir do cliente (antes/depois do firewall).
# Rodar NO CLIENTE. uso: sudo bash fase2_scan.sh <antes|depois>
source "$(dirname "$0")/comum.sh"
precisa_root
ROTULO="${1:?uso: fase2_scan.sh <antes|depois>}"
ARQ="fase2_nmap_${ROTULO}.txt"

titulo "$ARQ" "Varredura das portas de interesse (com detecção de versão)"
evid "$ARQ" "nmap -Pn -sS -sV --version-light -p 22,80,443,8080,9000,9001 $SERVIDOR_IP"
titulo "$ARQ" "Varredura TCP completa (1-65535)"
evid "$ARQ" "nmap -Pn -sS -T4 --min-rate 1000 --max-retries 1 -p- $SERVIDOR_IP"
titulo "$ARQ" "Testes de aplicação"
evid "$ARQ" "curl -s -m 5 -o /dev/null -w 'HTTP %{http_code}\n' http://$SERVIDOR_IP:8080/"
evid "$ARQ" "nc -zv -w 3 $SERVIDOR_IP 22"
exit 0
