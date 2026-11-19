#!/usr/bin/env bash
# Fase 3 — Armazenamento compatível com S3 (SILO, fork comunitário do MinIO) + IAM.
# Instala SILO e mcli (versão fixada, SHA-256 conferido), cria os buckets, a política de
# menor privilégio e o usuário lab-user. Rodar NO SERVIDOR. uso: sudo bash fase3_silo.sh
source "$(dirname "$0")/comum.sh"
precisa_root
ARQ="fase3_iam.txt"

SILO_TAG="RELEASE.2026-11-12T00-00-00Z"
SILO_VER="20261112000000.0.0"
SILO_DEB="silo_${SILO_VER}-1PGSTY_amd64.deb"
SILO_SHA="232f59133179547a9dce6844dfbe41f222b5fe3eb53ba1d0a3904bb88c3eabcf"
MCLI_DEB="mcli_${SILO_VER}_amd64.deb"
MCLI_SHA="28663f8d54d2b01b451053b2e851b8775a91bd1e2c2a3bcc9ce5d1a45c494d82"

[ "$(dpkg --print-architecture)" = "amd64" ] || erro "este script fixa pacotes amd64; ajuste para sua arquitetura"

baixa_instala() { # baixa_instala <url> <sha256> <arquivo>
  local dir=/var/cache/silo-lab
  mkdir -p "$dir"
  [ -f "$dir/$3" ] || curl -fsSL -o "$dir/$3" "$1" || erro "download falhou: $1"
  echo "$2  $dir/$3" | sha256sum -c - || erro "SHA-256 não confere: $3"
  DEBIAN_FRONTEND=noninteractive apt-get install -y -q "$dir/$3" >/dev/null
}

titulo "$ARQ" "Instalação do SILO $SILO_VER e do mcli"
command -v silo >/dev/null || baixa_instala \
  "https://github.com/pgsty/silo/releases/download/$SILO_TAG/$SILO_DEB" "$SILO_SHA" "$SILO_DEB"
command -v mcli >/dev/null || baixa_instala \
  "https://github.com/pgsty/mc/releases/download/$SILO_TAG/$MCLI_DEB" "$MCLI_SHA" "$MCLI_DEB"
evid "$ARQ" "silo --version"
evid "$ARQ" "mcli --version"

# Credenciais de administrador geradas na VM (nunca versionadas).
if [ ! -f /etc/silo-lab.env ]; then
  ( umask 077; printf 'MINIO_ROOT_USER=lab-admin\nMINIO_ROOT_PASSWORD=%s\n' "$(openssl rand -hex 20)" > /etc/silo-lab.env )
fi
id silo-lab >/dev/null 2>&1 || useradd --system --no-create-home --shell /usr/sbin/nologin silo-lab
mkdir -p /var/lib/silo-lab && chown silo-lab:silo-lab /var/lib/silo-lab

cat > /etc/systemd/system/silo-lab.service <<'EOF'
[Unit]
Description=Laboratorio - SILO (armazenamento S3) em :9000, console em :9001
After=network-online.target

[Service]
User=silo-lab
Group=silo-lab
EnvironmentFile=/etc/silo-lab.env
ExecStart=/usr/bin/silo server /var/lib/silo-lab --address :9000 --console-address :9001
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

titulo "$ARQ" "Serviço"
evid "$ARQ" "cat /etc/systemd/system/silo-lab.service"
evid "$ARQ" "systemctl daemon-reload && systemctl enable --now silo-lab"
for _ in $(seq 1 30); do curl -fs "$S3_URL/minio/health/live" >/dev/null && break; sleep 1; done
evid "$ARQ" "curl -s -o /dev/null -w 'health: HTTP %{http_code}\n' $S3_URL/minio/health/live"
evid "$ARQ" "ss -tlnp | grep -E ':(9000|9001) '"

carrega_silo
if [ ! -f /root/.silo-lab-user ]; then
  ( umask 077; printf 'LAB_SECRET=%s\n' "$(openssl rand -hex 20)" > /root/.silo-lab-user )
fi
set -a; . /root/.silo-lab-user; set +a

titulo "$ARQ" "Buckets"
evid "$ARQ" "$MCLI alias set root $S3_URL \$MINIO_ROOT_USER \$MINIO_ROOT_PASSWORD"
evid "$ARQ" "$MCLI mb --ignore-existing root/$BUCKET root/$BUCKET_OUTRO"
echo "arquivo de teste do laboratório" > /tmp/teste.txt
evid "$ARQ" "$MCLI cp /tmp/teste.txt root/$BUCKET/teste.txt"
evid "$ARQ" "$MCLI cp /tmp/teste.txt root/$BUCKET_OUTRO/confidencial.txt"
evid "$ARQ" "$MCLI ls root"

titulo "$ARQ" "Política de menor privilégio e usuário"
evid "$ARQ" "cat $LAB_DIR/politica-lab-rw.json"
evid "$ARQ" "$MCLI admin policy create root $POLITICA $LAB_DIR/politica-lab-rw.json"
evid "$ARQ" "$MCLI admin user add root $LAB_USUARIO \$LAB_SECRET"
evid "$ARQ" "$MCLI admin policy attach root $POLITICA --user $LAB_USUARIO || true"
evid "$ARQ" "$MCLI admin user info root $LAB_USUARIO"
evid "$ARQ" "$MCLI admin policy info root $POLITICA"
exit 0
