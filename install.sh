#!/usr/bin/env bash
set -euo pipefail

if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
	echo "Do not run this script as root. Run as a regular user with sudo access."
	exit 1
fi

if [[ "$(uname -s)" != "Linux" ]]; then
	echo "This installer only supports Linux (Ubuntu 24.04 Desktop)."
	exit 1
fi

if [[ ! -f /etc/os-release ]]; then
	echo "Cannot detect operating system (missing /etc/os-release)."
	exit 1
fi

# shellcheck disable=SC1091
source /etc/os-release

if [[ "${ID:-}" != "ubuntu" ]]; then
	echo "Detected ID=${ID:-unknown}. This script is intended for Ubuntu 24.04 Desktop."
	exit 1
fi

if [[ "${VERSION_ID:-}" != "24.04" ]]; then
	echo "Detected Ubuntu ${VERSION_ID:-unknown}. This script targets Ubuntu 24.04."
	exit 1
fi

SUDO=""
if command -v sudo >/dev/null 2>&1; then
	SUDO="sudo"
fi

require_command() {
	if ! command -v "$1" >/dev/null 2>&1; then
		echo "Missing required command: $1"
		exit 1
	fi
}

ensure_path_line() {
	local shell_rc="$1"
	local export_line='export PATH="$HOME/.bun/bin:$PATH"'
	if [[ -f "$shell_rc" ]]; then
		if ! grep -Fq "$export_line" "$shell_rc"; then
			echo "$export_line" >>"$shell_rc"
		fi
	else
		echo "$export_line" >"$shell_rc"
	fi
}

echo "==> Installing Ubuntu packages"
$SUDO apt-get update
$SUDO apt-get install -y \
	build-essential \
	ca-certificates \
	curl \
	git \
	jq \
	tmux \
	unzip

if ! command -v bun >/dev/null 2>&1; then
	echo "==> Installing Bun runtime"
	curl -fsSL https://bun.sh/install | bash
fi

export PATH="$HOME/.bun/bin:$PATH"
require_command bun

echo "==> Installing Overstory and required os-eco CLIs"
bun install -g @os-eco/mulch-cli @os-eco/seeds-cli @os-eco/canopy-cli @os-eco/overstory-cli

ensure_path_line "$HOME/.bashrc"
ensure_path_line "$HOME/.zshrc"

# Ensure shell can resolve new binaries in current script process.
export PATH="$HOME/.bun/bin:$PATH"

require_command ov
require_command overstory
require_command mulch
require_command ml
require_command sd
require_command cn

cat <<'DONE'

✅ Overstory installation complete.

Next steps:
1. Open a new terminal (or run: source ~/.bashrc).
2. Verify install:
   ov --version
   ov doctor --json
3. In your project:
   ov init

Optional: install at least one agent runtime CLI (claude, codex, copilot, pi, or gemini).
DONE
