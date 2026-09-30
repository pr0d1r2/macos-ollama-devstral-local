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

## Fastest LAN path: Ollama.app network toggle

For the fastest path to a working endpoint on a trusted network, use the
Ollama.app setting below (verified on macOS 26.x):

1. Open **Ollama.app** from Applications.
2. Open the Ollama menu from the menu bar, then choose **Settings**.
3. In **Settings**, enable **Expose Ollama to the network**.
4. If macOS shows an incoming-connections firewall prompt, choose **Allow**.
5. Verify the bind in Terminal:

    ```sh
    lsof -nP -iTCP:11434 -sTCP:LISTEN
    ```

    The listener should show `*:11434` (or an equivalent wildcard bind), not
    only `127.0.0.1:11434`.

This app-toggle path binds Ollama to the LAN, handles the macOS firewall
prompt, and persists across launches. It is intentionally insecure: the
endpoint has no authentication or TLS and is available on every network while
the setting remains enabled. Use it only on a trusted network and turn
**Expose Ollama to the network** **off** before leaving that network.

If a client reports **connection refused**, first confirm that Ollama.app is
running and that the `lsof` command above shows `*:11434`. If it shows only
`127.0.0.1:11434`, enable the setting again and restart Ollama.app. If there
is no listener, allow the firewall prompt (or review the macOS firewall rule),
then retry the check before testing `http://<mac>.local:11434` from the client.

The `start.sh` workflow below installs the managed headless LaunchAgent and
is the alternative for persistent unattended use; do not run both service
paths against port `11434` at the same time.

## Reach it from another Mac on the LAN

Use the serving Mac's Bonjour hostname with the `.local` suffix; no raw IP
address is needed. On the serving Mac, find the hostname with:

```sh
scutil --get LocalHostName
```

For example, if that prints `dev-mac`, another Mac on the same trusted LAN
can reach Ollama at `http://dev-mac.local:11434`. Check the endpoint from the
client with:

```sh
curl http://dev-mac.local:11434/api/tags
```

If the name does not resolve, confirm both Macs are on the same LAN, that the
serving Mac is awake, and that its firewall prompt was allowed. You can also
confirm the serving Mac's full local hostname with `hostname` and use that
name before the `.local:11434` suffix.

## Agent gateways and the OpenAI-compatible inference proxy

The repository includes thin gateways for three agent CLIs. Each gateway
writes the agent's native config, points it at Ollama's OpenAI-compatible
proxy at `http://127.0.0.1:11434/v1`, verifies that `devstral` is available,
and then `exec`s the real CLI with all arguments, standard input, output, and
exit status preserved. Run them from the unpacked repository:

### Pi

Install Pi using Ollama's launcher, which installs and configures the Pi
coding agent:

```sh
ollama launch pi
./agent-pi.sh
```

The gateway writes `~/.pi/agent/models.json`. It can also be used with a Pi
installation that provides a `pi` binary on `PATH`.

### Codex

Install the Codex CLI from npm, then start it through the gateway:

```sh
npm install -g @openai/codex
./agent-codex.sh
```

The gateway writes `~/.codex/config.toml`. It selects the local provider with
`wire_api = "responses"`; use a recent Ollama release that supports the
Responses API. Do not use `codex --oss`: that mode hardcodes localhost and
does not use the gateway's configured base URL.

### OpenCode

Install OpenCode from npm, then start it through the gateway:

```sh
npm install -g opencode-ai
./agent-opencode.sh
```

The gateway writes `~/.config/opencode/opencode.json` and selects
`ollama/devstral` through the OpenAI-compatible provider.

These scripts are both agent launchers and examples of the inference proxy
contract. Other OpenAI-compatible clients can use
`http://<mac>.local:11434/v1`, model `devstral`, and the dummy API key
`ollama`; the key is accepted for compatibility and is not authentication.
The wrappers default to the serving Mac itself. They can be pointed at a
remote serving Mac by setting `AGENT_BASE_URL`, for example:

```sh
AGENT_BASE_URL=http://dev-mac.local:11434/v1 ./agent-codex.sh
```

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
TLS**. Anyone who can reach the Mac and port `11434` can use the model, so
use it only on a trusted network and never expose it directly to the public
internet. If macOS asks whether to allow incoming connections through the
firewall, choose **Allow** for LAN clients to reach the service; that prompt
is expected when enabling this trusted-network endpoint. Decline it, or
restrict the firewall rule, if the network is not trusted. See `SPEC.md` for
the full security model.

## Runtime vs dev

- **Runtime** is bare: POSIX `sh` plus `curl` and macOS built-ins. No
  package manager, no build step.
- **Dev/CI** uses Nix + [lefthook](https://github.com/evilmartians/lefthook)
  guardrails, kept separate from the runtime. End users never need Nix.

## License

[MIT](LICENSE).
