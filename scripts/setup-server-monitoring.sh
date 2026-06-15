#!/usr/bin/env bash
#
# setup-server-monitoring.sh — persistent post-mortem monitoring for the arcdex
# droplet. Run ON THE SERVER as root (e.g. `ssh root@164.92.92.244` then run, or
# scp it over). Idempotent: safe to re-run.
#
# Installs/configures:
#   1. atop      — per-process CPU/mem/disk history to /var/log/atop, survives
#                  reboot, replay with `atop -r`. The "what ate my RAM" tool.
#   2. journald  — persistent storage so the kernel OOM-killer log survives a
#                  reboot (by default it lives in /run and is wiped).
#   3. swap      — a 4G swapfile so the box thrashes-and-recovers instead of
#                  hard-locking. Skipped if any swap already exists.
#
# After a future lock-up + reboot, see the cheatsheet printed at the end.

set -euo pipefail

[[ $EUID -eq 0 ]] || { echo "run as root (sudo)" >&2; exit 1; }

ATOP_INTERVAL="${ATOP_INTERVAL:-60}"   # seconds between samples (default 600 is too coarse)
SWAP_SIZE="${SWAP_SIZE:-4G}"
WITH_SWAP="${WITH_SWAP:-1}"            # set WITH_SWAP=0 to skip swap

echo "==> 1/3 atop (process-level history)"
if ! command -v atop >/dev/null 2>&1; then
  apt-get update -qq
  DEBIAN_FRONTEND=noninteractive apt-get install -y -qq atop
fi
# Tighten the sample interval and keep ~4 weeks of daily logs.
if [[ -f /etc/default/atop ]]; then
  sed -i "s/^LOGINTERVAL=.*/LOGINTERVAL=${ATOP_INTERVAL}/" /etc/default/atop
  grep -q '^LOGINTERVAL=' /etc/default/atop || echo "LOGINTERVAL=${ATOP_INTERVAL}" >> /etc/default/atop
  sed -i 's/^LOGGENERATIONS=.*/LOGGENERATIONS=28/' /etc/default/atop
fi
systemctl enable --now atop >/dev/null 2>&1 || systemctl restart atop
echo "    logging every ${ATOP_INTERVAL}s -> /var/log/atop/"

echo "==> 2/3 persistent journald (keeps OOM-killer logs across reboot)"
mkdir -p /var/log/journal /etc/systemd/journald.conf.d
cat > /etc/systemd/journald.conf.d/99-persistent.conf <<'EOF'
[Journal]
Storage=persistent
SystemMaxUse=500M
EOF
systemctl restart systemd-journald
echo "    journal -> /var/log/journal (capped 500M)"

echo "==> 3/3 swap"
if [[ "$WITH_SWAP" != "1" ]]; then
  echo "    skipped (WITH_SWAP=0)"
elif [[ -n "$(swapon --show --noheadings 2>/dev/null)" ]]; then
  echo "    swap already present, skipping:"; swapon --show
else
  fallocate -l "$SWAP_SIZE" /swapfile || dd if=/dev/zero of=/swapfile bs=1M count=4096
  chmod 600 /swapfile
  mkswap /swapfile >/dev/null
  swapon /swapfile
  grep -q '^/swapfile ' /etc/fstab || echo '/swapfile none swap sw 0 0' >> /etc/fstab
  sysctl -w vm.swappiness=10 >/dev/null
  grep -q '^vm.swappiness' /etc/sysctl.conf || echo 'vm.swappiness=10' >> /etc/sysctl.conf
  echo "    added ${SWAP_SIZE} swapfile (swappiness=10)"
fi

cat <<'CHEATSHEET'

================= post-mortem cheatsheet (after a lock-up + reboot) =================

# Did the kernel OOM-killer fire on the PREVIOUS boot, and on what?
journalctl -k -b -1 --no-pager | grep -iE 'out of memory|oom-kill|killed process'

# Replay atop around the incident (pick the day; files are atop_YYYYMMDD):
atop -r /var/log/atop/atop_$(date -d yesterday +%Y%m%d 2>/dev/null || date +%Y%m%d)
#   inside atop:  t / T = step forward/back a sample · m = sort by memory
#                 c = sort by cpu · q = quit
# Text summary of memory pressure for a day:
atopsar -r /var/log/atop/atop_$(date +%Y%m%d) -m   # memory   (-c cpu, -d disk)

# Which container/process was biggest right now:
docker stats --no-stream

====================================================================================
CHEATSHEET
