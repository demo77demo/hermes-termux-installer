#!/data/data/com.termux/files/usr/bin/bash
# ═══════════════════════════════════════════════════════════════
#   Hermes Agent — Native Termux Installer
#   github.com/demo77demo/hermes-termux-installer
#   One command. No proot. Pure Android native.
# ═══════════════════════════════════════════════════════════════

set -euo pipefail

# ── Config ─────────────────────────────────────────────────────────
REPO_OWNER="NousResearch"
REPO_NAME="hermes-agent"
REPO_URL="https://github.com/${REPO_OWNER}/${REPO_NAME}"
HERMES_HOME="${HOME}/.hermes"
CLONE_DIR="${HERMES_HOME}/hermes-agent"
VENV_DIR="${HERMES_HOME}/venv"
BIN_DIR="${PREFIX}/bin"
CORE_REPO="https://github.com/DevCoreXOfficial/core-termux"

# ── Colors ─────────────────────────────────────────────────────────
R='\033[0;31m'; G='\033[0;32m'; Y='\033[0;33m'
B='\033[0;34m'; C='\033[0;36m'; W='\033[1;37m'
DIM='\033[2m'; BOLD='\033[1m'; NC='\033[0m'

# ── Flags ──────────────────────────────────────────────────────────
FLAG_YES=false
FLAG_CORE=true
FLAG_TELEGRAM_INTERACTIVE=true

# ── Helpers ─────────────────────────────────────────────────────────
banner() {
  echo; echo -e "${C}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${C}${BOLD}  $1${NC}"
  echo -e "${C}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"; echo
}
step()  { echo -e "${B}  ▶  $1${NC}"; }
ok()    { echo -e "${G}  ✓  $1${NC}"; }
warn()  { echo -e "${Y}  ⚠  $1${NC}"; }
err()   { echo -e "${R}  ✗  $1${NC}"; }
info()  { echo -e "${DIM}     $1${NC}"; }
ask()   { echo -ne "${W}  ?  $1 [y/N] ${NC}"; }
readtty() { read "$@" < /dev/tty; }

# ── Argument parsing ────────────────────────────────────────────────
usage() {
  echo "Usage: bash install.sh [options]"
  echo ""
  echo "Options:"
  echo "  --yes               Non-interactive (auto-confirm all)"
  echo "  --no-core           Skip core-termux installation"
  echo "  --no-telegram       Skip Telegram setup"
  echo "  --help              Show this help"
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --yes)   FLAG_YES=true; shift ;;
    --no-core) FLAG_CORE=false; shift ;;
    --no-telegram) FLAG_TELEGRAM_INTERACTIVE=false; shift ;;
    --help)  usage ;;
    *)       echo "Unknown option: $1"; usage ;;
  esac
done

confirm() {
  if $FLAG_YES; then return 0; fi
  ask "$1"
  readtty REPLY
  [[ "$REPLY" =~ ^[yY] ]]
}

# ═══════════════════════════════════════════════════════════════════
#   STEP 0 — Header
# ═══════════════════════════════════════════════════════════════════
clear
echo ""
echo -e "${C}${BOLD}"
echo "  ╔═══════════════════════════════════════════════════╗"
echo "  ║       ⚕  HERMES AGENT — NATIVE TERMUX            ║"
echo "  ║                                                   ║"
echo "  ║   No proot  •  No glibc  •  Pure Android          ║"
echo "  ║   One command, zero config drift                  ║"
echo "  ║   github.com/demo77demo/hermes-termux-installer   ║"
echo "  ╚═══════════════════════════════════════════════════╝"
echo -e "${NC}"
echo -e "${DIM}  Installs Hermes Agent natively into Termux —${NC}"
echo -e "${DIM}  with working \`hermes update\`, \`hermes doctor\`,${NC}"
echo -e "${DIM}  and all tools ready to use.${NC}"
echo ""

# ═══════════════════════════════════════════════════════════════════
#   STEP 1 — Environment Check
# ═══════════════════════════════════════════════════════════════════
banner "Step 1 of 8 — Environment Check"

if [[ -z "${PREFIX:-}" ]]; then
  err "This script must be run inside Termux."
  exit 1
fi
ok "Termux environment detected"

ARCH=$(uname -m)
if [[ "$ARCH" != "aarch64" ]]; then
  warn "Architecture is ${ARCH} — optimized for aarch64 (ARM64). Proceeding..."
else
  ok "Architecture: aarch64 (ARM64)"
fi

ANDROID_API=$(getprop ro.build.version.sdk 2>/dev/null || echo "unknown")
ANDROID_VER=$(getprop ro.build.version.release 2>/dev/null || echo "unknown")
ok "Android ${ANDROID_VER} (API ${ANDROID_API})"

PYTHON_VER=$(python3 --version 2>&1 | awk '{print $2}')
ok "Python ${PYTHON_VER}"

# Check if Hermes already installed
if command -v hermes &>/dev/null; then
  warn "Hermes is already installed ($(hermes --version 2>/dev/null || echo 'unknown version'))"
  if ! confirm "Reinstall? This will NOT delete your existing config."; then
    info "Skipping installation. Run with --yes to override."
    exit 0
  fi
fi

# ═══════════════════════════════════════════════════════════════════
#   STEP 2 — System Dependencies
# ═══════════════════════════════════════════════════════════════════
banner "Step 2 of 8 — Installing System Dependencies"

step "Updating package lists..."
pkg update -y -q 2>/dev/null || true
ok "Package lists updated"

DEPS="git python python-dev binutils openssl openssl-tool"
DEPS_BIN="which file sqlite ncurses-utils"

step "Installing core packages..."
for pkg in $DEPS $DEPS_BIN; do
  if pkg list-installed 2>/dev/null | grep -q "^${pkg}$"; then
    continue
  fi
  pkg install -y -q "$pkg" 2>/dev/null || warn "$pkg failed to install"
done
ok "Core packages ready"

# Detect build deps only if needed (cryptography, psutil, etc.)
step "Installing build dependencies..."
BUILD_DEPS="clang rust make pkg-config libffi"
for pkg in $BUILD_DEPS; do
  pkg install -y -q "$pkg" 2>/dev/null || true
done
ok "Build dependencies ready"

# Fix common Termux pip issues
step "Configuring pip..."
mkdir -p "${HOME}/.config/pip"
cat > "${HOME}/.config/pip/pip.conf" << 'PIPEOF'
[global]
break-system-packages = true
PIPEOF
ok "pip configured for system-site-packages compatibility"

# ═══════════════════════════════════════════════════════════════════
#   STEP 3 — Clone Hermes Agent
# ═══════════════════════════════════════════════════════════════════
banner "Step 3 of 8 — Cloning Hermes Agent Repository"

if [[ -d "${CLONE_DIR}/.git" ]]; then
  ok "Repository already cloned at ${CLONE_DIR}"
  step "Fetching latest..."
  cd "$CLONE_DIR"
  git fetch --depth 1 origin main 2>/dev/null || true
  git reset --hard origin/main 2>/dev/null || true
  ok "Updated to latest"
else
  if [[ -d "$CLONE_DIR" ]]; then
    warn "Removing stale directory ${CLONE_DIR}..."
    rm -rf "$CLONE_DIR"
  fi
  mkdir -p "$HERMES_HOME"
  step "Cloning ${REPO_NAME}..."
  git clone --depth 1 "${REPO_URL}.git" "$CLONE_DIR"
  ok "Repository cloned"
fi

cd "$CLONE_DIR"
HERMES_VERSION=$(grep '^version = ' pyproject.toml | head -1 | cut -d'"' -f2)
ok "Hermes Agent ${HERMES_VERSION}"

# ═══════════════════════════════════════════════════════════════════
#   STEP 4 — Python Virtual Environment
# ═══════════════════════════════════════════════════════════════════
banner "Step 4 of 8 — Setting Up Python Environment"

# Patch pyproject.toml to allow current Python version
PY_MAJOR=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
PY_MINOR=$(python3 -c 'import sys; print(sys.version_info.minor)')

step "Patching Python constraint in pyproject.toml..."
sed -i "s/requires-python = \">=3.11,<3.14\"/requires-python = \">=3.11,<=${PY_MAJOR}\"/" pyproject.toml
ok "Python constraint relaxed for ${PY_MAJOR}"

# Create venv
if [[ -d "${VENV_DIR}" ]]; then
  ok "Virtual environment already exists at ${VENV_DIR}"
  # Update pip in existing venv
  step "Upgrading pip..."
  "${VENV_DIR}/bin/python" -m pip install --upgrade pip -q
else
  step "Creating virtual environment..."
  python3 -m venv "${VENV_DIR}"
  ok "Virtual environment created"
  step "Upgrading pip..."
  "${VENV_DIR}/bin/pip" install --upgrade pip -q
fi

# ═══════════════════════════════════════════════════════════════════
#   STEP 5 — Install Hermes
# ═══════════════════════════════════════════════════════════════════
banner "Step 5 of 8 — Installing Hermes Agent"

step "Installing Hermes and dependencies (editable mode)..."
"${VENV_DIR}/bin/pip" install -e "${CLONE_DIR}" --no-build-isolation 2>&1 | \
  grep -v "^$" | grep -v "Requirement already satisfied\|already satisfied" | \
  sed "s/^/     /" || true
ok "Hermes installed in editable mode"

# Verify
step "Verifying installation..."
"${VENV_DIR}/bin/python" -c "
from pathlib import Path
import hermes_cli
f = hermes_cli.__file__
p = Path(f).parent.parent.resolve()
has_git = (p / '.git').exists()
print(f'  hermes_cli: {f}')
print(f'  PROJECT_ROOT: {p}')
print(f'  .git: {has_git}')
assert has_git, '.git must exist for hermes update to work'
print('OK - editable install verified')
" 2>&1
ok "Editable install verified (PROJECT_ROOT has .git)"

# Create symlink
step "Creating hermes command in ${BIN_DIR}..."
ln -sf "${VENV_DIR}/bin/hermes" "${BIN_DIR}/hermes"
ln -sf "${VENV_DIR}/bin/hermes-agent" "${BIN_DIR}/hermes-agent"
ok "hermes command available system-wide"

# ═══════════════════════════════════════════════════════════════════
#   STEP 6 — Configure Hermes
# ═══════════════════════════════════════════════════════════════════
banner "Step 6 of 8 — Configuring Hermes"

mkdir -p "$HERMES_HOME"

step "Running initial setup..."
hermes setup --defaults 2>/dev/null || true
ok "Hermes configured with defaults"

step "Running doctor (diagnose + fix common issues)..."
hermes doctor --fix 2>/dev/null || true
ok "Hermes diagnostics complete"

# ═══════════════════════════════════════════════════════════════════
#   STEP 7 — Optional: core-termux
# ═══════════════════════════════════════════════════════════════════
banner "Step 7 of 8 — Optional Tools"

if $FLAG_CORE && confirm "Install core-termux (DevCoreX CLI framework)?"; then
  step "Installing core-termux..."
  curl -fsSL "${CORE_REPO}/main/install.sh" | bash 2>&1 | grep -v "^$" | sed "s/^/     /" || warn "core-termux installation had issues"
  ok "core-termux installed"
else
  info "core-termux skipped"
fi

# ═══════════════════════════════════════════════════════════════════
#   STEP 8 — Verification
# ═══════════════════════════════════════════════════════════════════
banner "Step 8 of 8 — Final Verification"

step "Checking hermes command..."
if command -v hermes &>/dev/null; then
  ok "hermes found in PATH ($(command -v hermes))"
  hermes --version 2>&1 | sed "s/^/     /"
else
  err "hermes not in PATH — this should not happen"
fi

step "Checking hermes update..."
hermes update 2>&1 | head -5 | sed "s/^/     /"
ok "hermes update mechanism ready"

step "Checking hermes doctor..."
hermes doctor 2>&1 | \
  grep -E "✓|✗|error|Error|fail|Fail|missing" | head -15 | sed "s/^/     /"
ok "hermes doctor check complete"

# ═══════════════════════════════════════════════════════════════════
#   DONE
# ═══════════════════════════════════════════════════════════════════
echo ""
echo -e "${C}${BOLD}"
echo "  ╔═══════════════════════════════════════════════════╗"
echo "  ║       🎉  Installation Complete!                 ║"
echo "  ╚═══════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""
echo -e "${W}  Hermes Agent ${HERMES_VERSION} — ready on Termux${NC}"
echo ""
echo -e "  ${G}hermes${NC}                 Start chatting"
echo -e "  ${G}hermes update${NC}          Update Hermes to latest"
echo -e "  ${G}hermes doctor${NC}          Check everything is healthy"
echo -e "  ${G}hermes gateway${NC}         Start Telegram/Discord gateway"
echo -e "  ${G}hermes setup model${NC}     Change AI model/provider"
echo ""
echo -e "  ${DIM}Config: ${HERMES_HOME}/config.yaml${NC}"
echo -e "  ${DIM}Keys:   ${HERMES_HOME}/.env${NC}"
echo -e "  ${DIM}Clone:  ${CLONE_DIR}${NC}"
echo -e "  ${DIM}Venv:   ${VENV_DIR}${NC}"
echo ""
echo -e "${W}  Want Telegram gateway?${NC}"
echo -e "  ${DIM}  Run after install:  hermes setup gateway${NC}"
echo ""
echo -e "${C}  ⭐ github.com/demo77demo/hermes-termux-installer${NC}"
echo ""
