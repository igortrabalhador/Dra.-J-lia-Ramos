#!/usr/bin/env bash
set -euo pipefail

# Idempotent environment setup for SVG logo design, rendering, validation,
# text-to-path outlining, and optimization.

# Ensure non-interactive bash shells source ~/.bashrc completely.
touch "$HOME/.bashrc"
sed -i '/case \$- in/,/esac/d' "$HOME/.bashrc" 2>/dev/null || true

mkdir -p "$HOME/.npm-global/bin" "$HOME/.local/bin"

if ! grep -qxF 'export NPM_CONFIG_PREFIX="$HOME/.npm-global"' "$HOME/.bashrc"; then
  echo 'export NPM_CONFIG_PREFIX="$HOME/.npm-global"' >> "$HOME/.bashrc"
fi
if ! grep -qxF 'export PATH="$HOME/.npm-global/bin:$HOME/.local/bin:$PATH"' "$HOME/.bashrc"; then
  echo 'export PATH="$HOME/.npm-global/bin:$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
fi

export NPM_CONFIG_PREFIX="$HOME/.npm-global"
export PATH="$HOME/.npm-global/bin:$HOME/.local/bin:$PATH"

SUDO=""
if [ "$(id -u)" -ne 0 ] && command -v sudo >/dev/null 2>&1; then
  SUDO="sudo"
fi

APT_PACKAGES=(
  librsvg2-bin
  inkscape
  libxml2-utils
  imagemagick
  potrace
  fontconfig
  fonts-ebgaramond
  fonts-lato
  fonts-montserrat
  fonts-inter
  fonts-open-sans
  fonts-quicksand
  fonts-dancingscript
  fonts-crosextra-caladea
)

MISSING_PACKAGES=()
for pkg in "${APT_PACKAGES[@]}"; do
  status="$(dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null || true)"
  if [ "$status" != "install ok installed" ]; then
    MISSING_PACKAGES+=("$pkg")
  fi
done

if [ "${#MISSING_PACKAGES[@]}" -gt 0 ]; then
  $SUDO DEBIAN_FRONTEND=noninteractive apt-get update -qq
  $SUDO DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "${MISSING_PACKAGES[@]}"
  fc-cache -f
fi

if ! command -v svgo >/dev/null 2>&1; then
  npm install -g --no-audit --no-fund svgo
fi

if ! python3 -c "import PIL, svgpathtools, fontTools" >/dev/null 2>&1; then
  python3 -m pip install --user --no-input --quiet pillow svgpathtools fonttools
fi
