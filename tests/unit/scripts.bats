#!/usr/bin/env bats

setup() {
    REPO_DIR="$BATS_TEST_DIRNAME/../.."
    TEST_DIR="$(mktemp -d)"
    MOCK_BIN="$TEST_DIR/bin"
    mkdir -p "$MOCK_BIN"

    cat >"$MOCK_BIN/curl" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >>"${MOCK_CURL_LOG:?}"
case "$*" in
    *api/generate*) printf '%s\n' '{"response":"OK","total_duration":123,"eval_count":7}' ;;
    */api/show*) printf '%s\n' '{"name":"devstral"}' ;;
    */api/ps*) printf '%s\n' '{"models":[]}' ;;
    */api/tags*) printf '%s\n' '{"models":[{"name":"devstral:latest"}]}' ;;
    */v1/models*) printf '%s\n' '{"data":[{"id":"devstral"}]}' ;;
esac
EOF
    chmod +x "$MOCK_BIN/curl"
    export PATH="$MOCK_BIN:$PATH" MOCK_CURL_LOG="$TEST_DIR/curl.log"
}

teardown() {
    rm -rf "$TEST_DIR"
}

@test "scripts/ollama-helper.sh and scripts/models.sh use MOCK_BIN curl" {
    run sh "$REPO_DIR/scripts/models.sh"
    [ "$status" -eq 0 ]
    grep -F '/api/tags' "$MOCK_CURL_LOG"
    [[ "$output" == *'devstral:latest'* ]]
}

@test "scripts/get-model.sh passes the requested model to curl" {
    run sh "$REPO_DIR/scripts/get-model.sh" custom
    [ "$status" -eq 0 ]
    grep -F '/api/show' "$MOCK_CURL_LOG"
    grep -F 'custom' "$MOCK_CURL_LOG"
}

@test "scripts/status.sh uses the process endpoint" {
    run sh "$REPO_DIR/scripts/status.sh"
    [ "$status" -eq 0 ]
    grep -F '/api/ps' "$MOCK_CURL_LOG"
}

@test "scripts/test.sh sends a non-streaming generate request and reports metrics" {
    run sh "$REPO_DIR/scripts/test.sh" 'say hello'
    [ "$status" -eq 0 ]
    grep -F 'api/generate' "$MOCK_CURL_LOG"
    grep -F '"stream":false' "$MOCK_CURL_LOG"
    [[ "$output" == *'OK'* ]]
}

@test "scripts/prompt.sh prints the response and metrics" {
    run sh "$REPO_DIR/scripts/prompt.sh" 'say hello'
    [ "$status" -eq 0 ]
    [[ "$output" == *'OK'* ]]
    grep -F 'api/generate' "$MOCK_CURL_LOG"
}

@test "scripts/healthcheck.sh checks the LAN address" {
    run env LAN_IP=192.0.2.10 PORT=12345 sh "$REPO_DIR/scripts/healthcheck.sh"
    [ "$status" -eq 0 ]
    grep -F 'http://192.0.2.10:12345/api/tags' "$MOCK_CURL_LOG"
}

@test "agent templates substitute the configured URL and model" {
    home="$TEST_DIR/home"
    mkdir -p "$home"
    cat >"$MOCK_BIN/opencode" <<'EOF'
#!/bin/sh
exit 0
EOF
    chmod +x "$MOCK_BIN/opencode"
    cat >"$MOCK_BIN/pi" <<'EOF'
#!/bin/sh
exit 0
EOF
    chmod +x "$MOCK_BIN/pi"
    cat >"$MOCK_BIN/codex" <<'EOF'
#!/bin/sh
exit 0
EOF
    chmod +x "$MOCK_BIN/codex"

    run env HOME="$home" AGENT_BASE_URL=http://dev-mac.local:11434/v1 AGENT_MODEL=custom \
        OPENCODE_CONFIG_PATH="$home/opencode.json" sh "$REPO_DIR/agent-opencode.sh"
    [ "$status" -eq 0 ]
    grep -F 'http://dev-mac.local:11434/v1' "$home/opencode.json"
    grep -F '"custom": {}' "$home/opencode.json"
    ! grep -F '__BASE_URL__' "$home/opencode.json"
    ! grep -F '__MODEL__' "$home/opencode.json"

    run env HOME="$home" AGENT_BASE_URL=http://dev-mac.local:11434/v1 AGENT_MODEL=custom \
        PI_CONFIG_PATH="$home/pi.json" sh "$REPO_DIR/agent-pi.sh"
    [ "$status" -eq 0 ]
    grep -F '"id": "custom"' "$home/pi.json"

    run env HOME="$home" AGENT_BASE_URL=http://dev-mac.local:11434/v1 AGENT_MODEL=custom \
        CODEX_CONFIG_PATH="$home/codex.toml" sh "$REPO_DIR/agent-codex.sh"
    [ "$status" -eq 0 ]
    grep -F 'model = "custom"' "$home/codex.toml"
    grep -F 'base_url = "http://dev-mac.local:11434/v1"' "$home/codex.toml"
}
