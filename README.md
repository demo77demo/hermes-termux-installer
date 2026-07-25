# ⚕ Hermes Agent — Native Termux Installer

**One-command installer** for [Hermes Agent](https://github.com/NousResearch/hermes-agent) on Android/Termux — no proot, no glibc, pure Android native. Installs directly into `~/.hermes/` with working `hermes update`, `hermes doctor`, and optional `core-termux`.

```bash
curl -fsSL https://raw.githubusercontent.com/demo77demo/hermes-termux-installer/main/install.sh | bash
```

## Why this exists

The official Hermes install script targets Linux (glibc) and works inside Termux proot-distro. This installer:

- ✅ Runs **natively** on Android's Bionic libc — no proot, no container, no emulation
- ✅ **`hermes update`** works out of the box (editable install from git clone)
- ✅ **`hermes doctor`** passes — all native deps resolved
- ✅ Resolves Python version constraints automatically
- ✅ Installs **core-termux** optionally
- ✅ One command, full Hermes installation, no bugs

## Quick start

```bash
# Install (interactive — prompts for core-termux, Telegram)
bash <(curl -fsSL https://raw.githubusercontent.com/demo77demo/hermes-termux-installer/main/install.sh)

# Non-interactive (auto-confirm everything)
bash <(curl -fsSL https://raw.githubusercontent.com/demo77demo/hermes-termux-installer/main/install.sh) --yes

# Skip core-termux
bash <(curl -fsSL https://raw.githubusercontent.com/demo77demo/hermes-termux-installer/main/install.sh) --no-core

# Skip Telegram prompts
bash <(curl -fsSL https://raw.githubusercontent.com/demo77demo/hermes-termux-installer/main/install.sh) --no-telegram
```

## What it installs

```
~/.hermes/
├── hermes-agent/          # Git clone (for hermes update)
├── venv/                  # Python virtual environment
├── config.yaml            # Hermes configuration
└── .env                   # API keys and secrets
```

System-wide commands:
- `hermes` — the Hermes agent CLI
- `hermes-agent` — the agent runtime
- `core` (optional) — core-termux CLI toolkit

## Requirements

- Termux from GitHub (not Google Play — it's outdated)
- `aarch64` (ARM64) recommended, `arm` works too
- Android 8+ (API 26+)
- ~500 MB free space
- Git configured (`git config --global user.name` / `user.email`)

## Comparison

| Feature | Official script | kaiveekx/hermes-termux-native | **This installer** |
|---|---|---|---|
| Install target | proot-distro | Native Termux | Native Termux |
| glibc | Yes | No (Bionic) | No (Bionic) |
| `hermes update` | Works | Broken (no git) | **Works** ✅ |
| `hermes doctor` | Passes | Fails (deps) | **Passes** ✅ |
| Python version | System (on proot) | Pinned 3.11 | **Auto-detect** ✅ |
| core-termux | No | No | **Optional** ✅ |
| Install time | ~10 min | ~5–10 min | **~3–5 min** ⚡ |

## How it works

1. **Checks environment** — verifies Termux, Android API, architecture
2. **Installs system deps** — git, Python, build tools, openssl
3. **Clones Hermes** — full git repo at `~/.hermes/hermes-agent/`
4. **Creates venv** — isolated Python environment
5. **Patches Python constraint** — allows current Python version
6. **Editable install** — `pip install -e` so `hermes update` works
7. **Configures Hermes** — `hermes setup`, `hermes doctor --fix`
8. **Optional: core-termux** — DevCoreX CLI framework
9. **Verification** — checks `hermes`, `hermes update`, `hermes doctor`

## CI / Headless Install

```bash
# Automated install (no prompts)
curl -fsSL https://raw.githubusercontent.com/demo77demo/hermes-termux-installer/main/install.sh | bash -s -- --yes --no-core --no-telegram
```

## Troubleshooting

**`hermes update` fails with "Not a git repository"**
→ The editable install should prevent this. If it happens, run:
```bash
cd ~/.hermes/hermes-agent && git pull
pip install -e ~/.hermes/hermes-agent
```

**Python version error during install**
→ The script automatically patches `pyproject.toml`. If your Python is very new (≥3.15), the patch may need updating.

**`hermes doctor` reports missing tools**
→ Some tools (like agent-browser, edge-tts) are optional. Install them manually:
```bash
npm install -g agent-browser
pip install edge-tts
```

## Contributing

PRs welcome! The installer is a single `install.sh` — keep it that way. No generated files, no multi-file projects.

## License

MIT
