#!/usr/bin/env bash
# Fase 3 — Acesso anônimo ao bucket: primeiro público (de propósito), depois privado.
# Rodar NO SERVIDOR. uso: sudo bash fase3_bucket.sh <publico|privado>
source "$(dirname "$0")/comum.sh"
precisa_root
MODO="${1:?uso: fase3_bucket.sh <publico|privado>}"
ARQ="fase3_bucket_${MODO}.txt"
carrega_silo

titulo "$ARQ" "Configuração de acesso anônimo: $MODO"
case "$MODO" in
  publico) evid "$ARQ" "$MCLI anonymous set public root/$BUCKET" ;;
  privado) evid "$ARQ" "$MCLI anonymous set private root/$BUCKET" ;;
  *) erro "modo inválido: $MODO" ;;
esac
evid "$ARQ" "$MCLI anonymous get root/$BUCKET"
evid "$ARQ" "$MCLI anonymous get-json root/$BUCKET"

titulo "$ARQ" "Tentativas SEM autenticação (curl, sem assinatura)"
evid "$ARQ" "curl -s -w '\nHTTP %{http_code}\n' $S3_URL/$BUCKET/teste.txt"
evid "$ARQ" "curl -s -w '\nHTTP %{http_code}\n' '$S3_URL/$BUCKET/?list-type=2'"
evid "$ARQ" "curl -s -w '\nHTTP %{http_code}\n' -X PUT --data-binary 'escrito por anonimo' $S3_URL/$BUCKET/anonimo.txt"

if [ "$MODO" = "publico" ]; then
  titulo "$ARQ" "Limpeza do objeto gravado anonimamente"
  evid "$ARQ" "$MCLI rm root/$BUCKET/anonimo.txt"
fi
exit 0
