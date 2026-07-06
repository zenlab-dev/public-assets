#!/usr/bin/env bash
set -euo pipefail

DEPLOY_USER="${DEPLOY_USER:-zenlab-cd}"
REPO_DIR="${REPO_DIR:-/opt/zenlab-infra}"
DATA_ROOT="${DATA_ROOT:-/opt/zenlab-data}"
SKIP_SSH_HARDENING="${SKIP_SSH_HARDENING:-false}"
CI_PUBKEY_CONTENT="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINHf6PUG5axEHq7tiu32l3Etlje8U6ITm8JXui19R2mH zenlab-cd@zenlab-infra"

usage() {
  cat >&2 <<'EOF'
Usage: sudo bash zenlab-host.sh [options]

Bootstrap the local host for zenlab-infra GitHub CD.

Options are provided as environment variables:
  DEPLOY_USER             Deploy user to create/use (default: zenlab-cd)
  REPO_DIR                Repo checkout path (default: /opt/zenlab-infra)
  DATA_ROOT               Persistent data root (default: /opt/zenlab-data)
  SKIP_SSH_HARDENING=true Do not write the sshd Match block

The host must already have Docker and Tailscale configured. This script
contains only the public CI SSH key; it does not contain secrets.
EOF
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  usage
  exit 0
fi

if [ "$(id -u)" -ne 0 ]; then
  echo "Run as root, for example: sudo bash zenlab-host.sh" >&2
  exit 1
fi

if [ -n "${1:-}" ]; then
  usage
  exit 2
fi

if ! id -u "$DEPLOY_USER" >/dev/null 2>&1; then
  useradd -m -s /bin/bash "$DEPLOY_USER"
fi

if getent group docker >/dev/null 2>&1; then
  usermod -aG docker "$DEPLOY_USER"
else
  echo "Warning: docker group not found; install Docker before production CD runs." >&2
fi

install -d -m 700 -o "$DEPLOY_USER" -g "$DEPLOY_USER" "/home/$DEPLOY_USER/.ssh"
printf '%s\n' "$CI_PUBKEY_CONTENT" > "/home/$DEPLOY_USER/.ssh/authorized_keys"
chown "$DEPLOY_USER:$DEPLOY_USER" "/home/$DEPLOY_USER/.ssh/authorized_keys"
chmod 600 "/home/$DEPLOY_USER/.ssh/authorized_keys"

install -d -m 755 "$REPO_DIR"
install -d -m 755 "$DATA_ROOT"
chown -R "$DEPLOY_USER:$DEPLOY_USER" "$REPO_DIR" "$DATA_ROOT"

if [ "$SKIP_SSH_HARDENING" != "true" ]; then
  install -d -m 755 /etc/ssh/sshd_config.d
  printf '%s\n' \
    "Match User $DEPLOY_USER" \
    "  PasswordAuthentication no" \
    "  KbdInteractiveAuthentication no" \
    "  PubkeyAuthentication yes" \
    > /etc/ssh/sshd_config.d/90-zenlab-cd.conf

  if command -v sshd >/dev/null 2>&1; then
    sshd -t
  elif [ -x /usr/sbin/sshd ]; then
    /usr/sbin/sshd -t
  else
    echo "Warning: sshd not found; skipping sshd config validation." >&2
  fi

  if command -v systemctl >/dev/null 2>&1; then
    systemctl reload ssh 2>/dev/null || systemctl reload sshd 2>/dev/null || true
  elif command -v service >/dev/null 2>&1; then
    service ssh reload 2>/dev/null || service sshd reload 2>/dev/null || true
  fi
fi

id "$DEPLOY_USER"
stat -c '%U:%G %a %n' "$REPO_DIR" "$DATA_ROOT"
echo "Zenlab host bootstrap complete."
