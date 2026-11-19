#!/usr/bin/env bash
# Fase 2 — Serviços no servidor: web (python3 -m http.server 8080) e SSH.
# Rodar NO SERVIDOR. uso: sudo bash fase2_servicos.sh
source "$(dirname "$0")/comum.sh"
precisa_root
ARQ="fase2_servicos.txt"

mkdir -p /srv/lab-www
echo "<h1>Servidor do laboratório ($(hostname))</h1>" > /srv/lab-www/index.html

cat > /etc/systemd/system/lab-http.service <<'EOF'
[Unit]
Description=Laboratorio - servidor web simples (python3 -m http.server 8080)
After=network-online.target

[Service]
ExecStart=/usr/bin/python3 -m http.server 8080 --directory /srv/lab-www
DynamicUser=yes
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

titulo "$ARQ" "Subindo os serviços"
evid "$ARQ" "cat /etc/systemd/system/lab-http.service"
evid "$ARQ" "systemctl daemon-reload && systemctl enable --now lab-http ssh && sleep 1"
evid "$ARQ" "systemctl is-active lab-http ssh"
evid "$ARQ" "ss -tlnp | grep -E ':(22|8080) '"
