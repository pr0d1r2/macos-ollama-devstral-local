# macos-ollama-devstral-local

[![CI](https://github.com/pr0d1r2/macos-ollama-devstral-local/actions/workflows/ci.yml/badge.svg)](https://github.com/pr0d1r2/macos-ollama-devstral-local/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![NixOS 25.11](https://img.shields.io/badge/NixOS-25.11-blue.svg?logo=nixos)](https://nixos.org)

Bare, drop-in shell scripts to serve [Ollama](https://ollama.com) with
**Devstral 24B** on `0.0.0.0` for fast local inference across a trusted
network. Aimed at Apple Silicon (M-chip) Macs with enough RAM. Download,
unpack, run, and you get a shared LAN inference endpoint in minutes.

> **Status: spec + guardrails.** The full specification lives in
> [`SPEC.md`](SPEC.md); the runtime scripts are being built against it.
> This repo is materialized and tended via the
> [set-and-setting](https://github.com/pr0d1r2/set-and-setting) ecosystem.

## What it will do

- One `start.sh` that checks for `/Applications/Ollama.app`, guides
  install if missing, pulls Devstral 24B, and serves it on the LAN.
- `stop.sh` / `restart.sh` / `uninstall.sh` for lifecycle control.
- Per-RAM-tier tuning (16, 24, 32, 48, 64, 96, 128 GB) documented for
  quantization and context length.
- Agent gateways (`agent-opencode.sh`, `agent-pi.sh`, `agent-codex.sh`)
  that point local coding agents at the endpoint.

## Security

The endpoint is a bare `0.0.0.0` service with **no authentication and no
TLS**. Use it only on a trusted network. See `SPEC.md` for the full
security model.

## Runtime vs dev

- **Runtime** is bare: POSIX `sh` plus `curl` and macOS built-ins. No
  package manager, no build step.
- **Dev/CI** uses Nix + [lefthook](https://github.com/evilmartians/lefthook)
  guardrails, kept separate from the runtime. End users never need Nix.

## License

[MIT](LICENSE).
