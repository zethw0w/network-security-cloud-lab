#!/usr/bin/env bash
# Fase 4 — Verificação final a partir do cliente: somente a 8080 acessível.
# Rodar NO CLIENTE. uso: sudo bash fase4_cliente.sh
#   PERMITIR_SSH_CLIENTE=1  se o firewall também liberou o SSH do cliente.
source "$(dirname "$0")/comum.sh"
precisa_root
ARQ="fase4_cliente.txt"
ESPERADAS="8080"
[ "${PERMITIR_SSH_CLIENTE:-0}" = "1" ] && ESPERADAS="22 8080"

titulo "$ARQ" "Varredura das portas de interesse"
evid "$ARQ" "nmap -Pn -sS -sV --version-light -p 22,80,443,8080,9000,9001 $SERVIDOR_IP"

TOTAL=$((TOTAL + 1))
titulo "$ARQ" "Teste $TOTAL: varredura TCP completa encontra somente: $ESPERADAS"
evid "$ARQ" "nmap -Pn -sS -T4 --min-rate 1000 --max-retries 1 -p- $SERVIDOR_IP"
ABERTAS="$(grep -Eo '^[0-9]+/tcp +open ' <<<"$_SAIDA" | cut -d/ -f1 | sort -n | xargs)"
if [ "$ABERTAS" = "$ESPERADAS" ]; then V=PASSOU; else V=FALHOU; FALHAS=$((FALHAS + 1)); fi
printf '=> RESULTADO: %s (portas abertas: %s; esperado: %s)\n' "$V" "${ABERTAS:-nenhuma}" "$ESPERADAS" | tee -a "$_F"

checa "$ARQ" "HTTP 8080 responde ao cliente" 0 "HTTP 200" \
  "curl -s -m 5 -o /dev/null -w 'HTTP %{http_code}\n' http://$SERVIDOR_IP:8080/"
if [ "${PERMITIR_SSH_CLIENTE:-0}" != "1" ]; then
  checa "$ARQ" "SSH (22) bloqueado para o cliente" '!0' - \
    "nc -zv -w 3 $SERVIDOR_IP 22"
fi
checa "$ARQ" "API S3 (9000) bloqueada para o cliente" '!0' - \
  "curl -s -m 5 http://$SERVIDOR_IP:9000/minio/health/live"
checa "$ARQ" "console do SILO (9001) bloqueado para o cliente" '!0' - \
  "curl -s -m 5 http://$SERVIDOR_IP:9001/"
resumo "$ARQ"
