#!/usr/bin/env bash
# Fase 4 — Verificação final no servidor: bucket sem acesso anônimo e lab-user restrito.
# Rodar NO SERVIDOR. uso: sudo bash fase4_servidor.sh
source "$(dirname "$0")/comum.sh"
precisa_root
ARQ="fase4_servidor.txt"
carrega_silo
[ -n "${LAB_SECRET:-}" ] || erro "credencial do lab-user ausente; rode fase3_silo.sh"
NEGADO='access denied|accessdenied|insufficient permissions|not allowed'

titulo "$ARQ" "Alias do usuário de menor privilégio"
evid "$ARQ" "$MCLI alias set labuser $S3_URL $LAB_USUARIO \$LAB_SECRET"

# 1) Acesso público
checa "$ARQ" "política anônima do bucket é private" 0 "private" \
  "$MCLI anonymous get root/$BUCKET"
checa "$ARQ" "download anônimo negado" 0 "HTTP 403" \
  "curl -s -w '\nHTTP %{http_code}\n' $S3_URL/$BUCKET/teste.txt"
checa "$ARQ" "listagem anônima negada" 0 "HTTP 403" \
  "curl -s -w '\nHTTP %{http_code}\n' '$S3_URL/$BUCKET/?list-type=2'"
checa "$ARQ" "upload anônimo negado" 0 "HTTP 403" \
  "curl -s -w '\nHTTP %{http_code}\n' -X PUT --data-binary 'teste' $S3_URL/$BUCKET/anonimo.txt"

# 2) Dentro do escopo da política
checa "$ARQ" "lab-user lista o $BUCKET" 0 "teste.txt" \
  "$MCLI ls labuser/$BUCKET"
checa "$ARQ" "lab-user lê objeto do $BUCKET" 0 "arquivo de teste" \
  "$MCLI cat labuser/$BUCKET/teste.txt"
checa "$ARQ" "lab-user grava objeto no $BUCKET" 0 - \
  "$MCLI cp /etc/hostname labuser/$BUCKET/gravado-pelo-lab-user.txt"

# 3) Fora do escopo — tudo deve ser negado
checa "$ARQ" "lab-user NÃO cria bucket" '!0' "$NEGADO" \
  "$MCLI mb labuser/bucket-nao-autorizado"
checa "$ARQ" "lab-user NÃO lista o $BUCKET_OUTRO" '!0' "$NEGADO" \
  "$MCLI ls labuser/$BUCKET_OUTRO"
checa "$ARQ" "lab-user NÃO lê objeto do $BUCKET_OUTRO" '!0' "$NEGADO" \
  "$MCLI cat labuser/$BUCKET_OUTRO/confidencial.txt"
checa "$ARQ" "lab-user NÃO apaga objeto (s3:DeleteObject não concedido)" '!0' "$NEGADO" \
  "$MCLI rm labuser/$BUCKET/teste.txt"
checa "$ARQ" "lab-user NÃO altera a política do bucket" '!0' "$NEGADO" \
  "$MCLI anonymous set public labuser/$BUCKET"
checa "$ARQ" "lab-user NÃO executa ação administrativa" '!0' "$NEGADO" \
  "$MCLI admin user list labuser"

titulo "$ARQ" "Buckets visíveis para o lab-user"
evid "$ARQ" "$MCLI ls labuser"
titulo "$ARQ" "Firewall do servidor"
evid "$ARQ" "ufw status verbose"
resumo "$ARQ"
