#!/usr/bin/env bash
# Provisionamento inicial das VMs (rodado pelo Vagrant, ou manualmente com sudo).
# uso: sudo bash provision.sh <servidor|cliente>
set -euo pipefail

PAPEL="${1:?uso: provision.sh <servidor|cliente>}"
LAB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# O Vagrant executa uma cópia deste script em /tmp; a pasta compartilhada é /vagrant/lab.
[ -d /vagrant/lab ] && LAB_DIR=/vagrant/lab
USUARIO="${SUDO_USER:-vagrant}"
[ "$USUARIO" = "root" ] && USUARIO=vagrant
CASA="$(getent passwd "$USUARIO" | cut -d: -f6)"
CHAVES="$LAB_DIR/.chaves"

export DEBIAN_FRONTEND=noninteractive
timedatectl set-timezone America/Sao_Paulo 2>/dev/null || true
apt-get update -q
apt-get install -y -q nmap curl ufw netcat-openbsd python3 openssl openssh-server

mkdir -p "$CHAVES"
case "$PAPEL" in
  cliente)
    # Chave SSH do cliente, publicada para o servidor autorizar (teste de SSH da Fase 1).
    if [ ! -f "$CASA/.ssh/id_lab" ]; then
      sudo -u "$USUARIO" mkdir -p "$CASA/.ssh"
      sudo -u "$USUARIO" ssh-keygen -q -t ed25519 -N '' -C "cliente-lab" -f "$CASA/.ssh/id_lab"
    fi
    cp "$CASA/.ssh/id_lab.pub" "$CHAVES/cliente.pub"
    ;;
  servidor)
    if [ -f "$CHAVES/cliente.pub" ]; then
      sudo -u "$USUARIO" mkdir -p "$CASA/.ssh"
      touch "$CASA/.ssh/authorized_keys"
      grep -qxF "$(cat "$CHAVES/cliente.pub")" "$CASA/.ssh/authorized_keys" \
        || cat "$CHAVES/cliente.pub" >> "$CASA/.ssh/authorized_keys"
      chown "$USUARIO:" "$CASA/.ssh/authorized_keys"; chmod 600 "$CASA/.ssh/authorized_keys"
    else
      echo "AVISO: $CHAVES/cliente.pub não existe; provisione o cliente antes (vagrant provision servidor depois)." >&2
    fi
    ;;
  *) echo "papel inválido: $PAPEL" >&2; exit 1 ;;
esac
echo "Provisionamento de '$PAPEL' concluído."
