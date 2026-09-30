# macos-ollama-devstral-local

<!-- hallucinogen:autonomy-disclaimer start -->
> Read [LLM-DISCLAIMER](docs/LLM-DISCLAIMER.md) first. This repository is
> tended by an autonomous loop, and that file says what the loop may do here,
> what it may not, and what to check before trusting anything in this tree.
<!-- hallucinogen:autonomy-disclaimer end -->

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

## Quick start from a ZIP

No Git, build tool, package manager, or Nix installation is needed at runtime:

1. Open the repository page, choose **Code → Download ZIP**, and save the ZIP.
2. Unpack it in Finder (or with `unzip`) and open Terminal in the unpacked
  repository directory.
3. Run the bootstrap with `sh start.sh`:

  ```sh
  cd macos-ollama-devstral-local-main
  sh start.sh
  ```

  ZIP extraction can remove executable bits; `sh start.sh` works regardless
  and repairs the entrypoint for later `./start.sh` runs. On the first run,
  if `/Applications/Ollama.app` is absent, the script opens the Ollama
  download page, prints the installation steps, and waits for Ollama.app
  before continuing. It then installs the managed headless service, pulls
  Devstral, warms the model, and prints the LAN endpoint.

To select a RAM tier before starting, set `TIER` in the same command, for
example `TIER=64 sh start.sh`. See the tier table below for the available
values and tuning; the default is the 32 GB tier.

## What it will do

- One `start.sh` that checks for `/Applications/Ollama.app`, guides
  install if missing, pulls Devstral 24B, and serves it on the LAN.
- `stop.sh` / `restart.sh` / `uninstall.sh` for lifecycle control.

On startup, `start.sh` best-effort removes Ollama from the macOS login items
so the Ollama menubar app does not start a competing server. If macOS denies
the automation request, open System Settings → General → Login Items and
remove or disable Ollama manually. The managed headless service remains the
process that owns port 11434.

- Per-RAM-tier tuning (16, 24, 32, 48, 64, 96, 128 GB) for quantization,
  context length, and concurrent requests. Set `TIER` before running
  `start.sh`; `CTX` and `NUM_PARALLEL` can override the runtime defaults.
  The quantization column documents the recommended model artifact for each
  tier; the current bootstrap does not select a different Ollama artifact
  from `QUANT`.

  | RAM | Quantization | Context | Parallel | Notes |
  | ---: | :--- | ---: | ---: | :--- |
  | 16 GB | `q4_K_M` | 4,096 | 1 | Marginal for Devstral 24B; avoid other memory-heavy workloads. |
  | 24 GB | `q4_K_M` | 8,192 | 1 | |
  | 32 GB | `q5_K_M` | 8,192 | 2 | Default tier. |
  | 48 GB | `q6_K` | 16,384 | 2 | |
  | 64 GB | `q8_0` | 32,768 | 4 | |
  | 96 GB | `q8_0` | 32,768 | 6 | |
  | 128 GB | `q8_0` | 65,536 | 8 | |

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
