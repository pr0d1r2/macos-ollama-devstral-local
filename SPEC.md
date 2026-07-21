# SPEC — macos-ollama-devstral-local

## §G GOAL

Drop-in bare scripts. Download zip from public repo → unpack → run `start.sh`. Checks `/Applications/Ollama.app`; if missing, opens https://ollama.com/download in browser + clear on-screen steps + waits for manual install. Ollama.app = installer ONLY (provides CLI + runtime). After install, headless: own LaunchAgent runs bundled `ollama serve` on `0.0.0.0:11434` at login (RunAtLoad, KeepAlive), env baked in plist. Model warm always (KEEP_ALIVE=-1 + preload), response-optimized. No GUI after first install. Pulls devstral 24B, healthchecks. Fastest fresh-mac → shared LAN inference endpoint. start/stop/restart/uninstall. Agent gateways (opencode/pi/codex) via config injection. README maps RAM size → config, tiers 16..128 GB.

Arch = B: own LaunchAgent runs headless `ollama serve`. Ollama.app only installs binary; its menubar autostart disabled → no rival serve, no port clash.

## §C CONSTRAINTS

- C1 macOS Apple Silicon (arm64) only. Runtime `uname -m` guard.
- C2 ollama via `/Applications/Ollama.app` (from https://ollama.com/download), installer only. CLI at `/Applications/Ollama.app/Contents/Resources/ollama`, PATH fallback.
- C3 headless service: LaunchAgent runs `ollama serve` w/ env in plist (`OLLAMA_HOST=0.0.0.0:11434`, keep_alive, ctx, num_parallel). RunAtLoad + KeepAlive. Starts after login.
- C4 Ollama.app menubar autostart disabled after install → no rival serve, no port clash. Best-effort programmatic + documented manual fallback.
- C5 trusted network only. No auth, no TLS, bare endpoint. Security warning mandatory. macOS firewall incoming-prompt = expected OS security feature.
- C6 runtime bare: `sh` + `curl` + macOS builtins (`open`, `launchctl`, `osascript`). No just/bats/python3 hard-dep. Parse JSON grep/sed.
- C7 zero prior setup. Download zip, unpack, run. No git clone, no build, no package manager. Exec-bit robust after unzip (`sh start.sh` works / self-chmod).
- C8 model `devstral` 24B via `ollama pull`.
- C9 RAM min ~16GB (marginal for 24B). Quant + ctx per tier, no OOM.
- C10 single config source `config.sh`. All scripts source it.
- C11 idempotent. Re-run safe, no dup, no error.
- C12 README tiers: 16, 24, 32, 48, 64, 96, 128 GB.
- C13 app absent → `open` download page, print clear steps, poll until installed. No silent fail, no proceed before install.
- C14 LAN reach via Bonjour `<mac>.local:11434`. No raw IP needed.
- C15 response-optimized: model warm always (`OLLAMA_KEEP_ALIVE=-1` + preload on start). `OLLAMA_NUM_PARALLEL` set for shared use.
- C16 CLI calls (pull/curl) in scripts `export OLLAMA_HOST` → hit own service. Distinct from plist env feeding the daemon.
- C17 dev/CI layer = Nix flake + lefthook + pr0d1r2/nix-lefthook-* checks. RUNTIME UNAFFECTED — end user never needs nix/lefthook; scripts stay bare sh+curl. Dev-only.
- C18 agent config = repo templates (`templates/`) w/ `__BASE_URL__`/`__MODEL__` placeholders. Wrapper substitutes via `sed` (bare, no envsubst). Templates lintable + testable.

## §I SURFACES

- I.start `start.sh` — arch guard, check app, guide install, disable app autostart, gen+load plist, pull, warm, healthcheck, print endpoint
- I.stop `stop.sh` — launchctl unload, safe when idle
- I.restart `restart.sh` — unload then load
- I.uninstall `uninstall.sh` — stop first, rm plist, unset, optional rm model
- I.config `config.sh` — model, port, quant, ctx, keep_alive, num_parallel, tier
- I.service LaunchAgent plist → `~/Library/LaunchAgents/*.plist` — runs `ollama serve`, env, RunAtLoad, KeepAlive, log paths
- I.api ollama HTTP `0.0.0.0:11434` (`/api/tags`, `/api/generate`)
- I.dl https://ollama.com/download opened via `open` when app missing
- I.lan clients reach `http://<mac>.local:11434` (Bonjour)
- I.readme `README.md` — RAM tiers, usage, LAN, security
- I.helpers `scripts/` — get-model, status, models, test, prompt (sh, adapted from a sibling ollama-helper project)
- I.agents `agent-opencode.sh`, `agent-pi.sh`, `agent-codex.sh` — inject config + env, `exec` real binary. Dual use: agent CLI + inference gateway.
- I.log service stdout/stderr → log file (`~/Library/Logs/` or `var/log/`)
- I.templates `templates/opencode.json`, `templates/codex.config.toml`, `templates/pi.models.json` — placeholder configs, sed-substituted at runtime
- I.dev `flake.nix` devShell — lefthook + tools (dev/CI only, not shipped in zip runtime)
- I.hooks `lefthook.yml` — wire pr0d1r2/nix-lefthook-* checks (remotes mode)
- I.ci `.github/workflows/ci.yml` — `pr0d1r2/nix-lefthook-ci-action@<SHA>`, ubuntu + macos

## §V INVARIANTS

- V1 serve binds `0.0.0.0:11434` (`OLLAMA_HOST` in plist env). LAN reachable, not localhost-only.
- V2 app absent → download page opened + steps shown + poll until `/Applications/Ollama.app` appears. No proceed before install.
- V3 service persists across reboot — LaunchAgent `RunAtLoad` + `KeepAlive`. Crash → auto restart.
- V4 headless — no GUI after first install. Ollama.app autostart disabled, own serve owns 11434, no clash.
- V5 start idempotent. Re-run safe, no dup, no error.
- V6 stop = launchctl unload. serve stops, no orphan.
- V7 restart = unload + load. No orphan, no port clash.
- V8 uninstall stops service first, removes plist, unsets env. Optional model rm. Clean.
- V9 devstral present before start success. Pull if missing.
- V10 quant + ctx fit RAM tier, no OOM. 16GB marked marginal.
- V11 runtime scripts sh + curl + macOS builtins only. Clean mac runs w/o extra install.
- V12 config single source. All scripts source `config.sh`.
- V13 README every tier (16/24/32/48/64/96/128) concrete quant + ctx.
- V14 README security warning present. 0.0.0.0 no auth = trusted net only.
- V15 start healthcheck verifies LAN-interface reachability — `curl http://<lan-ip>:11434/api/tags`, NOT just `localhost`. localhost-only pass hides 127.0.0.1 bind (see B1).
- V16 stop/uninstall safe when nothing running. No error exit.
- V17 CLI resolved from app path → PATH fallback. Missing app → download link, nonzero exit.
- V18 model warm always — `OLLAMA_KEEP_ALIVE=-1` in plist + preload generate on start. First real request fast.
- V19 shared endpoint concurrency — `OLLAMA_NUM_PARALLEL` set (sane default). No serialize under multi-client.
- V20 CLI scripts `export OLLAMA_HOST` → own service, not stray localhost server.
- V21 arch guard — non-arm64 → clear error, nonzero exit.
- V22 exec-bit robust — works after zip unpack (self-chmod or `sh start.sh`).
- V23 ollama helpers parse `/api/tags` + `/api/generate` (`stream:false`), report `total_duration` + `eval_count`.
- V24 agent wrapper `exec` real binary. All args + stdin/stdout + exit code preserved. Transparent.
- V25 wrapper points agent at local ollama via config-file injection — base `http://<host>:11434/v1`, model=devstral, dummy key `ollama`. Exact per-agent files: opencode `~/.config/opencode/opencode.json`, codex `~/.codex/config.toml`, pi `~/.pi/agent/models.json`.
- V26 wrapper resolves real binary via PATH, skips self (no recursion / fork bomb).
- V27 real binary missing → clear install hint, nonzero exit.
- V28 model id matches ollama tag — verify via `GET /v1/models` (may be `devstral` or `devstral:latest`).
- V29 dev/CI layer materialized from set-and-setting — `flake.nix`+`lefthook.yml`+`ci.yml` wire pr0d1r2/nix-lefthook-* checks. Runtime zip unaffected (no nix/lefthook needed to run scripts).
- V30 same lefthook checks run local (pre-commit/pre-push) AND CI (nix-lefthook-ci-action). Deterministic, SHA-pinned.
- V31 every `*.sh` shellcheck + shfmt clean; every runtime script has 1:1 bats test (unit-coverage); tests pass.
- V32 plist xmllint-valid; templates taplo(toml)/json-valid; README markdownlint+typos clean; workflow actionlint+yamllint clean.
- V33 no leaked secrets (gitleaks) — dummy key `ollama` only; no personal local paths (git-no-local-paths) — scripts generic.
- V34 config templates substituted via `sed` at runtime (`__BASE_URL__`,`__MODEL__`). No envsubst dep.
- V35 app-toggle path (Ollama.app Settings → "Expose Ollama to the network", verified macOS 26.x) = FASTEST to working endpoint, binds 0.0.0.0 + firewall + persists. Aligns w/ §G goal (speed, trusted net). Acceptable within trusted-net premise (C4). README flags insecure caveat: always-on/all-networks → turn OFF when leaving trusted network. Not disqualified — it's the quick path. Headless launchd service (arch B) = managed/scoped alternative for persistent unattended use.

## §T TASKS

id|status|task|cites
T1|.|config.sh — model, port, quant, ctx, keep_alive(-1), num_parallel, tier|V12,C15,I.config
T2|.|arch guard — uname -m = arm64 else error|V21,C1
T3|.|detect /Applications/Ollama.app, resolve CLI path|C2,V17,I.start
T4|.|app missing → open ollama.com/download, print steps, poll until installed|C13,V2,I.dl
T5|.|disable Ollama.app menubar autostart (best-effort + doc manual)|C4,V4
T6|.|LaunchAgent plist gen — ollama serve, env(host/keep_alive/ctx/num_parallel), RunAtLoad, KeepAlive, log paths|C3,V1,V3,V18,V19,I.service
T7|.|install + launchctl load plist|V3,V5,I.service
T8|.|export OLLAMA_HOST in scripts for own CLI calls|C16,V20
T9|.|devstral pull, skip if present|V9,C8
T10|.|warm/preload model on start (priming generate)|V18,C15
T11|.|healthcheck helper — curl /api/tags|V15,I.api
T12|.|start.sh — orchestrate T2-T11, print <mac>.local endpoint|V1,V5,V15,I.start
T13|.|stop.sh — launchctl unload, safe when idle|V6,V16,I.stop
T14|.|restart.sh — unload then load|V7,I.restart
T15|.|uninstall.sh — stop first, rm plist, unset, optional rm model|V8,I.uninstall
T16|.|ollama helpers — get-model/status/models/test/prompt (sh, lift sibling)|V23,I.helpers
T17|.|RAM tier → quant + ctx + num_parallel map; 16GB marginal|V10,V13
T18|.|exec-bit mitigation — self-chmod / sh start.sh fallback|V22,C7
T19|.|README — usage: download zip, unpack, run start.sh|C7,I.readme
T20|.|README — per-tier table 16..128 GB (quant, ctx); 16GB marginal|V13,C12
T21|.|README — security warning trusted net + firewall Allow note|V14,C5
T21a|.|README — app-toggle LAN-bind: Ollama.app Settings → "Expose Ollama to the network" (step-by-step, verified macOS 26.x) = FASTEST path, valid for trusted-net goal. Insecure caveat: turn OFF when leaving trusted net. Verify `lsof -nP -iTCP:11434 -sTCP:LISTEN` shows `*:11434`; troubleshoot connection-refused|V35,B1,I.readme
T22|.|README — LAN reach <mac>.local:11434, find hostname|C14,I.lan
T23|.|config — per-agent binary + config path + base_url(/v1) + model + dummy key `ollama`|V25,V28,I.config
T24|.|agent-lib.sh — resolve real binary (skip self via PATH minus script dir), verify model tag /v1/models, exec "$@"|V24,V26,V27,V28,I.agents
T25|.|agent-opencode.sh — write ~/.config/opencode/opencode.json: provider.ollama {npm:@ai-sdk/openai-compatible, options.baseURL, models.devstral}, model="ollama/devstral"; exec opencode|V24,V25,I.agents
T26|.|agent-pi.sh — write ~/.pi/agent/models.json: providers.ollama {baseUrl,/v1, api:openai-completions, apiKey:ollama, models:[{id:devstral}]}; exec pi (install via `ollama launch pi` or npm @earendil-works/pi-coding-agent)|V24,V25,I.agents
T27|.|agent-codex.sh — write ~/.codex/config.toml: [model_providers.ollama-local] base_url(/v1), wire_api="responses"; model+model_provider top-level; exec codex (NOT --oss: hardcodes localhost, ignores base_url)|V24,V25,I.agents
T28|.|README — agent gateways: CLI + inference proxy; install (pi via `ollama launch pi`, codex npm @openai/codex, opencode); codex wire_api=responses needs recent ollama|I.agents,I.readme
T29|.|templates/ — opencode.json, codex.config.toml, pi.models.json w/ __BASE_URL__/__MODEL__ placeholders|C18,I.templates
T30|.|wrappers substitute template via sed → agent config path (T25-T27 read templates)|C18,V34,I.templates
T31|x|flake.nix devShell — nix-dev-shell-agentic mkShells CI/dev split (dev/CI only)|C17,V29,I.dev
T32|~|lefthook.yml — baseline 15 remotes DONE (shellcheck/shfmt/nixfmt/statix/deadnix/yamllint/typos/trailing-ws/final-newline/conflict/editorconfig/no-local-paths/vulnix/flake-check/no-embedded-shell). PENDING add: execute-permissions, bats-unit, bats-changed, unit-coverage, xmllint, taplo, markdownlint, actionlint, gitleaks|V30,V31,V32,V33,I.hooks
T33|x|.github/workflows/ci.yml — nix develop .#ci lefthook run, ubuntu + macos|C17,V30,I.ci
T34|.|tests/unit/*.bats — per-script, curl mocked via MOCK_BIN; template-substitution tests|V31,I.helpers
T35|.|README — dev/CI section: nix devShell, lefthook, CI action (runtime needs none)|C17,I.readme

## §B BUGS

id|date|cause|fix
B1|2026-07-21|LAN `curl <ip>:11434` connection refused. ollama defaults to 127.0.0.1 bind (localhost only). launchctl setenv path unreliable/non-persistent + no firewall handling. Fix verified: Ollama.app Settings → "Expose Ollama to the network" toggle (binds 0.0.0.0 + firewall + persists)|V15,V35
B2|2026-07-21|`guardrails / check` failed because the reusable workflow runs `nix run .#confirm`, but the migrated flake did not export that app; its dev shell also let lefthook create an example config instead of materializing the fragment-derived config|Added the standard pinned confirm app with the repository's lefthook wrappers on its runtime path and made both dev shells install the pinned fragment-derived `lefthook.yml`
