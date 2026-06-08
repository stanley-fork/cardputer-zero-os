#!/bin/sh
set -eu

echo "DRM:"
ls -l /dev/dri 2>/dev/null || true

echo
echo "Input:"
ls -l /dev/input 2>/dev/null || true

echo
echo "Audio:"
ls -l /dev/snd 2>/dev/null || true

echo
echo "GPIO:"
ls -l /dev/gpio* /dev/gpiomem 2>/dev/null || true

echo
echo "I2C/SPI:"
ls -l /dev/i2c-* /dev/spidev* 2>/dev/null || true

echo
echo "External GPIO14/GPIO15 UART:"
cat /proc/cmdline 2>/dev/null | tr ' ' '\n' | grep '^console=' || true
ls -l /dev/serial0 /dev/serial1 /dev/ttyAMA* /dev/ttyS* 2>/dev/null || true
if command -v pinctrl >/dev/null 2>&1; then
  pinctrl get 14 || true
  pinctrl get 15 || true
fi
if command -v systemctl >/dev/null 2>&1; then
  systemctl is-active serial-getty@ttyS0.service 2>/dev/null || true
  systemctl is-enabled serial-getty@ttyS0.service 2>/dev/null || true
  systemctl is-active hciuart.service 2>/dev/null || true
fi

echo
echo "Relevant groups:"
for group in cardputer-zero input video audio render gpio spi i2c; do
  getent group "$group" || true
done
