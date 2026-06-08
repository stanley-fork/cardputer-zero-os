#!/bin/sh
set -eu

ROOT=${1:-}

find_boot_file() {
  rel=$1
  for path in "$ROOT/boot/firmware/$rel" "$ROOT/boot/$rel"; do
    if [ -f "$path" ]; then
      printf '%s\n' "$path"
      return 0
    fi
  done
  return 1
}

backup_once() {
  path=$1
  if [ -f "$path" ] && [ ! -f "$path.cardputer-zero.bak" ]; then
    cp "$path" "$path.cardputer-zero.bak"
  fi
}

cmdline=$(find_boot_file cmdline.txt || true)
if [ -n "$cmdline" ]; then
  backup_once "$cmdline"
  tmp=$(mktemp)
  trap 'rm -f "$tmp"' EXIT HUP INT TERM
  tr '\n' ' ' <"$cmdline" |
    awk '
      {
        for (i = 1; i <= NF; ++i) {
          if ($i ~ /^console=(ttyS0|serial0)(,.*)?$/) {
            continue;
          }
          printf "%s%s", out ? " " : "", $i;
          out = 1;
        }
        printf "\n";
      }
    ' >"$tmp"
  install -m 0644 "$tmp" "$cmdline"
  echo "Updated $cmdline to release GPIO14/GPIO15 external UART from the kernel serial console."
fi

config=$(find_boot_file config.txt || true)
if [ -n "$config" ]; then
  backup_once "$config"
  if ! grep -q '^[[:space:]]*enable_uart=1[[:space:]]*$' "$config"; then
    cat >>"$config" <<'EOF'
# BEGIN cardputer-zero-external-uart
# Keep the GPIO14/GPIO15 UART enabled for optional external serial accessories.
enable_uart=1
# END cardputer-zero-external-uart
EOF
  fi
  echo "Verified $config enables the serial UART."
fi

if [ -z "$ROOT" ] && command -v systemctl >/dev/null 2>&1; then
  systemctl stop serial-getty@ttyS0.service >/dev/null 2>&1 || true
  systemctl disable serial-getty@ttyS0.service >/dev/null 2>&1 || true
  systemctl mask serial-getty@ttyS0.service >/dev/null 2>&1 || true
  systemctl disable --now hciuart.service >/dev/null 2>&1 || true
  echo "Disabled serial-getty@ttyS0 and hciuart so GPIO14/GPIO15 external UART is not claimed by OS services."
else
  mkdir -p "$ROOT/etc/systemd/system"
  ln -sfn /dev/null "$ROOT/etc/systemd/system/serial-getty@ttyS0.service"
fi
