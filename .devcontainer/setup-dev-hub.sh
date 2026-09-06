#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# CampVerse WSL Development Container Launcher & Dev Hub
# ==============================================================================

TARGET_DIR="$(pwd)"
EXPECTED_PROJECT_DIR="campverse"

DEV_HUB_ROOT="${DEV_HUB_ROOT:-${HOME}/dev-hub}"
SDKS_DIR="${DEV_HUB_ROOT}/sdks"
BIN_DIR="${DEV_HUB_ROOT}/bin"
CACHES_DIR="${DEV_HUB_ROOT}/caches"
NPM_CACHE_DIR="${CACHES_DIR}/npm"

DOCKER_SOCKET="${DOCKER_HOST_SOCKET:-/var/run/docker.sock}"

IMAGE_NAME="campverse-sandbox"
CONTAINER_NAME="CampVerse_Sandbox"

# Tool Toggles (Set to 'false' to skip specific tools)
UPDATE_ALL="${UPDATE_ALL:-false}"
ENABLE_ANDROID="${ENABLE_ANDROID:-true}"
ENABLE_FLUTTER="${ENABLE_FLUTTER:-true}"
ENABLE_DENO="${ENABLE_DENO:-true}"
ENABLE_GO="${ENABLE_GO:-true}"
ENABLE_SUPABASE="${ENABLE_SUPABASE:-true}"
ENABLE_GH="${ENABLE_GH:-true}"
ENABLE_FIREBASE="${ENABLE_FIREBASE:-true}"
ENABLE_INFISICAL="${ENABLE_INFISICAL:-true}"
ENABLE_PLAYWRIGHT="${ENABLE_PLAYWRIGHT:-false}"
ENABLE_SHELL_CONFIG="${ENABLE_SHELL_CONFIG:-true}"

printf '\n🚀 Preparing CampVerse development environment...\n'

# --- Temporary directory cleanup trap ---
TMP_WORK_DIR=$(mktemp -d -t campverse_dev_hub_tmp_XXXXXX)
cleanup() {
    rm -rf "${TMP_WORK_DIR}"
}
trap cleanup EXIT INT TERM

# ==============================================================================
# 0. Project-root validation
# ==============================================================================

DIR_NAME="$(basename "$TARGET_DIR")"
if [ "${DIR_NAME,,}" != "${EXPECTED_PROJECT_DIR,,}" ]; then
    echo "❌ This script must be run from the $EXPECTED_PROJECT_DIR project root."
    echo "   Current directory: $TARGET_DIR"
    exit 1
fi

if [ ! -f "$TARGET_DIR/.devcontainer/Dockerfile" ]; then
    echo "❌ .devcontainer/Dockerfile not found."
    exit 1
fi

if [ ! -d "$TARGET_DIR/campverse_client" ] && [ ! -d "$TARGET_DIR/services" ]; then
    echo "❌ CampVerse project structure (campverse_client/services) not found in $TARGET_DIR."
    exit 1
fi

echo "📁 Project: $TARGET_DIR"

# ==============================================================================
# 1. Docker host prerequisites
# ==============================================================================

echo "🐳 Checking Docker environment..."

if ! command -v docker >/dev/null 2>&1; then
    echo "❌ Docker CLI not found in WSL."
    echo "   Ensure Docker Desktop WSL integration is enabled."
    exit 1
fi

DOCKER_BIN="$(command -v docker)"

if [ ! -x "$DOCKER_BIN" ]; then
    echo "❌ Docker CLI is not executable: $DOCKER_BIN"
    exit 1
fi

if ! docker info >/dev/null 2>&1; then
    echo "❌ Docker daemon is not accessible from WSL."
    echo "   Make sure Docker Desktop is running and WSL integration is enabled."
    exit 1
fi

if [ ! -e "$DOCKER_SOCKET" ]; then
    echo "❌ Docker socket not found: $DOCKER_SOCKET"
    exit 1
fi

if [ ! -S "$DOCKER_SOCKET" ]; then
    echo "❌ Docker socket is not a Unix socket: $DOCKER_SOCKET"
    exit 1
fi

DOCKER_GID="$(stat -c '%g' "$DOCKER_SOCKET" 2>/dev/null || true)"

if [ -z "$DOCKER_GID" ] || ! [[ "$DOCKER_GID" =~ ^[0-9]+$ ]]; then
    echo "❌ Unable to determine Docker socket GID."
    echo "   Socket: $DOCKER_SOCKET"
    exit 1
fi

echo "   Docker: $(docker --version)"
echo "   Docker socket: $DOCKER_SOCKET"
echo "   Docker socket GID: $DOCKER_GID"
echo "✅ Docker environment ready."

# ==============================================================================
# 2. Shared Dev Hub
# ==============================================================================

echo "🚀 Initializing Global Dev Hub at: $DEV_HUB_ROOT"

if [ -d "${HOME}/.gitconfig" ]; then
    echo "⚠️ Found ~/.gitconfig as a directory. Fixing..."
    rm -rf "${HOME}/.gitconfig"
    touch "${HOME}/.gitconfig"
fi

mkdir -p \
    "$SDKS_DIR" \
    "$BIN_DIR" \
    "$NPM_CACHE_DIR" \
    "$CACHES_DIR/gradle" \
    "$CACHES_DIR/pub-cache" \
    "$CACHES_DIR/pip" \
    "$CACHES_DIR/playwright-browsers" \
    "$CACHES_DIR/vscode-extensions" \
    "$CACHES_DIR/antigravity-ide-server"

# Shared tooling should be readable/executable; caches must be writable.
chmod 755 "$DEV_HUB_ROOT" "$SDKS_DIR" "$BIN_DIR"
chmod 775 "$NPM_CACHE_DIR" \
          "$CACHES_DIR/gradle" \
          "$CACHES_DIR/pub-cache" \
          "$CACHES_DIR/pip" \
          "$CACHES_DIR/playwright-browsers" \
          "$CACHES_DIR/vscode-extensions" \
          "$CACHES_DIR/antigravity-ide-server"

export PATH="$BIN_DIR:$PATH"

# ==============================================================================
# 3. Host-side required tools
# ==============================================================================

echo "📦 Verifying WSL host prerequisites..."

REQUIRED_TOOLS=(
    curl
    wget
    unzip
    tar
    jq
    git
    sha256sum
)

MISSING_TOOLS=()

for tool in "${REQUIRED_TOOLS[@]}"; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        MISSING_TOOLS+=("$tool")
    fi
done

if [ "${#MISSING_TOOLS[@]}" -ne 0 ]; then
    echo "⚠️ Missing host tools: ${MISSING_TOOLS[*]}"
    echo "   Installing..."

    sudo apt-get update
    sudo apt-get install -y --no-install-recommends "${MISSING_TOOLS[@]}"
fi

# ==============================================================================
# 4. Shared CLI tools & SDKs
# ==============================================================================

is_valid_binary() {
    local bin_path="$1"
    [ -x "$bin_path" ] && "$bin_path" --version >/dev/null 2>&1
}

# ------------------------------------------------------------------------------
# Supabase CLI
# ------------------------------------------------------------------------------
if [ "${ENABLE_SUPABASE}" = "true" ]; then
    if ! is_valid_binary "$BIN_DIR/supabase" || [ "${UPDATE_ALL}" = "true" ]; then
        echo "  ⬇️ Fetching Supabase CLI..."

        SUPABASE_URL="$(
            curl -fsSL https://api.github.com/repos/supabase/cli/releases/latest |
            jq -r '.assets[]
                | select(.name | contains("linux_amd64.tar.gz"))
                | .browser_download_url' |
            head -n 1
        )"

        if [ -z "$SUPABASE_URL" ]; then
            echo "❌ Could not determine Supabase CLI download URL."
            exit 1
        fi

        curl -fSL "$SUPABASE_URL" -o "$TMP_WORK_DIR/supabase.tar.gz"
        tar -xzf "$TMP_WORK_DIR/supabase.tar.gz" -C "$TMP_WORK_DIR"

        if [ ! -f "$TMP_WORK_DIR/supabase" ]; then
            echo "❌ Supabase CLI binary not found after extraction."
            exit 1
        fi

        install -m 0755 "$TMP_WORK_DIR/supabase" "$BIN_DIR/supabase"
        rm -f "$TMP_WORK_DIR/supabase.tar.gz" "$TMP_WORK_DIR/supabase"
    fi
    echo "   Supabase: $("$BIN_DIR/supabase" --version 2>/dev/null || echo unknown)"
else
    echo "⏩ Skipping Supabase CLI (ENABLE_SUPABASE=false)"
fi

# ------------------------------------------------------------------------------
# Infisical CLI
# ------------------------------------------------------------------------------
if [ "${ENABLE_INFISICAL}" = "true" ]; then
    if ! is_valid_binary "$BIN_DIR/infisical" || [ "${UPDATE_ALL}" = "true" ]; then
        echo "  ⬇️ Fetching Infisical CLI..."

        INFISICAL_URL="$(
            curl -fsSL https://api.github.com/repos/Infisical/cli/releases/latest 2>/dev/null |
            jq -r '.assets[]
                | select(.name | endswith("_linux_amd64.tar.gz"))
                | .browser_download_url' 2>/dev/null |
            head -n 1
        )"

        if [ -z "$INFISICAL_URL" ]; then
            INFISICAL_URL="$(
                curl -fsSL https://api.github.com/repos/Infisical/infisical/releases/latest 2>/dev/null |
                jq -r '.assets[]
                    | select(.name | contains("linux_amd64.tar.gz"))
                    | .browser_download_url' 2>/dev/null |
                head -n 1
            )"
        fi

        if [ -n "$INFISICAL_URL" ]; then
            curl -fSL "$INFISICAL_URL" -o "$TMP_WORK_DIR/infisical.tar.gz"
            tar -xzf "$TMP_WORK_DIR/infisical.tar.gz" -C "$TMP_WORK_DIR"

            INFISICAL_BINARY="$(
                find "$TMP_WORK_DIR" \
                    -maxdepth 2 \
                    -type f \
                    -name "infisical" \
                    -print -quit
            )"

            if [ -n "$INFISICAL_BINARY" ]; then
                install -m 0755 "$INFISICAL_BINARY" "$BIN_DIR/infisical"
            fi
            rm -rf "$TMP_WORK_DIR/infisical"*
        fi
    fi
    echo "   Infisical: $("$BIN_DIR/infisical" --version 2>/dev/null || echo unknown)"
else
    echo "⏩ Skipping Infisical CLI (ENABLE_INFISICAL=false)"
fi

# ------------------------------------------------------------------------------
# GitHub CLI (gh)
# ------------------------------------------------------------------------------
if [ "${ENABLE_GH}" = "true" ]; then
    if ! is_valid_binary "$BIN_DIR/gh" || [ "${UPDATE_ALL}" = "true" ]; then
        echo "  ⬇️ Fetching GitHub CLI..."
        GH_URL="$(
            curl -fsSL https://api.github.com/repos/cli/cli/releases/latest |
            jq -r '.assets[] | select(.name | contains("linux_amd64.tar.gz")) | .browser_download_url' |
            head -n 1
        )"
        if [ -n "${GH_URL}" ]; then
            curl -fSL "${GH_URL}" -o "${TMP_WORK_DIR}/gh.tar.gz"
            tar -xzf "${TMP_WORK_DIR}/gh.tar.gz" -C "${TMP_WORK_DIR}"
            find "${TMP_WORK_DIR}" -type f -name "gh" -exec install -m 0755 {} "${BIN_DIR}/gh" \;
            rm -rf "${TMP_WORK_DIR}/gh"*
        fi
    fi
    echo "   GitHub CLI: $("$BIN_DIR/gh" --version 2>/dev/null | head -n 1 || echo unknown)"
else
    echo "⏩ Skipping GitHub CLI (ENABLE_GH=false)"
fi

# ------------------------------------------------------------------------------
# Firebase CLI
# ------------------------------------------------------------------------------
if [ "${ENABLE_FIREBASE}" = "true" ]; then
    if ! is_valid_binary "$BIN_DIR/firebase" || [ "${UPDATE_ALL}" = "true" ]; then
        echo "  ⬇️ Fetching Standalone Firebase CLI..."
        wget -q https://firebase.tools/bin/linux/latest -O "${TMP_WORK_DIR}/firebase"
        install -m 0755 "${TMP_WORK_DIR}/firebase" "${BIN_DIR}/firebase"
        rm -f "${TMP_WORK_DIR}/firebase"
    fi
    echo "   Firebase: $("$BIN_DIR/firebase" --version 2>/dev/null || echo unknown)"
else
    echo "⏩ Skipping Firebase CLI (ENABLE_FIREBASE=false)"
fi

# ------------------------------------------------------------------------------
# Android SDK Setup
# ------------------------------------------------------------------------------
ANDROID_HOME="${SDKS_DIR}/android"
if [ "${ENABLE_ANDROID}" = "true" ]; then
    echo "🤖 Setting up Android SDK at: ${ANDROID_HOME}"

    if [ -d "${ANDROID_HOME}/cmdline-tools/latest" ]; then
        if ! "${ANDROID_HOME}/cmdline-tools/latest/bin/sdkmanager" --version >/dev/null 2>&1; then
            echo "⚠️ Android cmdline-tools installation is corrupt. Re-installing..."
            rm -rf "${ANDROID_HOME}/cmdline-tools"
        fi
    fi

    if [ ! -d "${ANDROID_HOME}/cmdline-tools/latest" ]; then
        mkdir -p "${ANDROID_HOME}/cmdline-tools"
        CMDLINE_URL="https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"
        
        echo "  ⬇️ Downloading Android Commandline Tools..."
        wget -q "${CMDLINE_URL}" -O "${TMP_WORK_DIR}/cmdline-tools.zip"
        unzip -q "${TMP_WORK_DIR}/cmdline-tools.zip" -d "${TMP_WORK_DIR}/cmdline-tools"
        mv "${TMP_WORK_DIR}/cmdline-tools/cmdline-tools" "${ANDROID_HOME}/cmdline-tools/latest"
        rm -rf "${TMP_WORK_DIR}/cmdline-tools"*
    fi

    export PATH="${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${PATH}"

    # Accept Android licenses
    yes | "${ANDROID_HOME}/cmdline-tools/latest/bin/sdkmanager" --licenses >/dev/null 2>&1 || true

    echo "  🔄 Detecting latest stable Android Platform & Build Tools..."
    LATEST_PLATFORM=$("${ANDROID_HOME}/cmdline-tools/latest/bin/sdkmanager" --list 2>/dev/null | grep -E '^\s*platforms;android-[0-9]+(\s|$)' | awk '{print $1}' | sort -V | tail -n 1)
    LATEST_BUILD_TOOLS=$("${ANDROID_HOME}/cmdline-tools/latest/bin/sdkmanager" --list 2>/dev/null | grep -E '^\s*build-tools;[0-9]+\.[0-9]+\.[0-9]+(\s|$)' | awk '{print $1}' | sort -V | tail -n 1)

    LATEST_PLATFORM="${LATEST_PLATFORM:-platforms;android-36}"
    LATEST_BUILD_TOOLS="${LATEST_BUILD_TOOLS:-build-tools;36.0.0}"

    echo "  📦 Installing: platform-tools, ${LATEST_PLATFORM}, ${LATEST_BUILD_TOOLS}, and build-tools;28.0.3"
    "${ANDROID_HOME}/cmdline-tools/latest/bin/sdkmanager" "platform-tools" "build-tools;28.0.3" "${LATEST_PLATFORM}" "${LATEST_BUILD_TOOLS}" >/dev/null 2>&1 || true
else
    echo "⏩ Skipping Android SDK (ENABLE_ANDROID=false)"
fi

# ------------------------------------------------------------------------------
# Flutter SDK Setup
# ------------------------------------------------------------------------------
FLUTTER_HOME="${SDKS_DIR}/flutter"
if [ "${ENABLE_FLUTTER}" = "true" ]; then
    echo "🐦 Setting up Flutter SDK at: ${FLUTTER_HOME}"

    if [ -d "${FLUTTER_HOME}" ]; then
        if ! git -C "${FLUTTER_HOME}" rev-parse --git-dir >/dev/null 2>&1; then
            echo "⚠️ Found corrupted/interrupted Flutter directory. Cleaning up..."
            rm -rf "${FLUTTER_HOME}"
        fi
    fi

    if [ ! -d "${FLUTTER_HOME}" ]; then
        echo "  ⬇️ Cloning Flutter Stable Channel..."
        git clone https://github.com/flutter/flutter.git -b stable "${FLUTTER_HOME}"
    else
        echo "  🔄 Flutter SDK present. Resetting to latest stable..."
        git -C "${FLUTTER_HOME}" fetch origin stable --quiet || true
        git -C "${FLUTTER_HOME}" reset --hard origin/stable || true
    fi

    export PATH="${FLUTTER_HOME}/bin:${PATH}"
    "${FLUTTER_HOME}/bin/flutter" config --no-analytics >/dev/null 2>&1 || true
    "${FLUTTER_HOME}/bin/flutter" config --enable-linux-desktop >/dev/null 2>&1 || true
    if [ "${ENABLE_ANDROID}" = "true" ]; then
        "${FLUTTER_HOME}/bin/flutter" config --android-sdk "${ANDROID_HOME}" >/dev/null 2>&1 || true
    fi
    echo "  ⚡ Pre-caching Flutter artifacts..."
    "${FLUTTER_HOME}/bin/flutter" precache --android --linux >/dev/null 2>&1 || true
else
    echo "⏩ Skipping Flutter SDK (ENABLE_FLUTTER=false)"
fi

# ------------------------------------------------------------------------------
# Deno Setup
# ------------------------------------------------------------------------------
DENO_HOME="${SDKS_DIR}/deno"
if [ "${ENABLE_DENO}" = "true" ]; then
    echo "🦕 Setting up Deno at: ${DENO_HOME}"

    IS_DENO_VALID=false
    if [ -x "${DENO_HOME}/bin/deno" ] && "${DENO_HOME}/bin/deno" --version >/dev/null 2>&1; then
        IS_DENO_VALID=true
    fi

    if [ "${IS_DENO_VALID}" = "false" ] || [ "${UPDATE_ALL}" = "true" ]; then
        mkdir -p "${DENO_HOME}/bin"
        echo "  ⬇️ Fetching Deno binary..."
        wget -q https://github.com/denoland/deno/releases/latest/download/deno-x86_64-unknown-linux-gnu.zip -O "${TMP_WORK_DIR}/deno.zip"
        unzip -q "${TMP_WORK_DIR}/deno.zip" -d "${TMP_WORK_DIR}/deno_bin"
        install -m 0755 "${TMP_WORK_DIR}/deno_bin/deno" "${DENO_HOME}/bin/deno"
        rm -rf "${TMP_WORK_DIR}/deno"*
    fi
    echo "   Deno: $("${DENO_HOME}/bin/deno" --version 2>/dev/null | head -n 1 || echo unknown)"
else
    echo "⏩ Skipping Deno (ENABLE_DENO=false)"
fi

# ------------------------------------------------------------------------------
# Go SDK Setup (CampVerse Realtime Gateway & Workers)
# ------------------------------------------------------------------------------
GO_HOME="${SDKS_DIR}/go"
if [ "${ENABLE_GO}" = "true" ]; then
    echo "🐹 Setting up Go SDK at: ${GO_HOME}"
    
    if [ ! -x "${GO_HOME}/bin/go" ] || [ "${UPDATE_ALL}" = "true" ]; then
        echo "  ⬇️ Fetching latest Go binary..."
        GO_VERSION=$(curl -sL "https://go.dev/VERSION?m=text" | head -n 1)
        wget -q "https://go.dev/dl/${GO_VERSION}.linux-amd64.tar.gz" -O "${TMP_WORK_DIR}/go.tar.gz"
        
        rm -rf "${GO_HOME}"
        tar -C "${SDKS_DIR}" -xzf "${TMP_WORK_DIR}/go.tar.gz"
        rm -f "${TMP_WORK_DIR}/go.tar.gz"
    fi
    echo "   Go: $("${GO_HOME}/bin/go" version 2>/dev/null || echo unknown)"
else
    echo "⏩ Skipping Go SDK (ENABLE_GO=false)"
fi

# ------------------------------------------------------------------------------
# Playwright Browser Binaries Pre-cache
# ------------------------------------------------------------------------------
if [ "${ENABLE_PLAYWRIGHT}" = "true" ]; then
    echo "🎭 Setting up Playwright shared browser cache..."
    export PLAYWRIGHT_BROWSERS_PATH="${CACHES_DIR}/playwright-browsers"
    if command -v npx >/dev/null 2>&1; then
        npx playwright install chromium firefox webkit --with-deps >/dev/null 2>&1 || true
    fi
else
    echo "⏩ Skipping Playwright Browsers (ENABLE_PLAYWRIGHT=false)"
fi

# ------------------------------------------------------------------------------
# WSL Host Shell Integration
# ------------------------------------------------------------------------------
if [ "${ENABLE_SHELL_CONFIG}" = "true" ]; then
    echo "🔗 Configuring WSL host shell environment paths..."

    ENV_MARKER="# --- CampVerse Dev Hub Paths ---"
    ENV_BLOCK=$(cat << 'EOF'
# --- CampVerse Dev Hub Paths ---
export DEV_HUB="${HOME}/dev-hub"
export FLUTTER_HOME="${DEV_HUB}/sdks/flutter"
export ANDROID_HOME="${DEV_HUB}/sdks/android"
export DENO_INSTALL="${DEV_HUB}/sdks/deno"
export GO_HOME="${DEV_HUB}/sdks/go"
export PATH="${PATH}:${DEV_HUB}/bin:${FLUTTER_HOME}/bin:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${DENO_INSTALL}/bin:${GO_HOME}/bin"
EOF
    )

    for RC_FILE in "${HOME}/.bashrc" "${HOME}/.zshrc"; do
        if [ -f "${RC_FILE}" ]; then
            if ! grep -qF "${ENV_MARKER}" "${RC_FILE}"; then
                echo "" >> "${RC_FILE}"
                echo "${ENV_BLOCK}" >> "${RC_FILE}"
                echo "  ✅ Configured paths in ${RC_FILE}"
            fi
        fi
    done
else
    echo "⏩ Skipping shell config integration (ENABLE_SHELL_CONFIG=false)"
fi

# ==============================================================================
# 5. Shared npm cache permissions
# ==============================================================================

echo "🔐 Checking shared npm cache permissions..."

DEV_UID="$(id -u)"
DEV_GID="$(id -g)"

if find "$NPM_CACHE_DIR" \
    ! -user "$DEV_UID" \
    -print -quit 2>/dev/null | grep -q .; then

    echo "   🔧 Correcting npm cache ownership..."
    sudo chown -R "$DEV_UID:$DEV_GID" "$NPM_CACHE_DIR"
    echo "   ✅ npm cache ownership corrected."
else
    echo "   ✅ npm cache ownership already correct."
fi

# ==============================================================================
# 6. Project dependency permissions
# ==============================================================================

echo "🔐 Checking project dependency permissions..."

for dir in \
    "$TARGET_DIR/node_modules" \
    "$TARGET_DIR/coverage" \
    "$TARGET_DIR/campverse_client/.dart_tool" \
    "$TARGET_DIR/campverse_client/build"
do
    if [ -d "$dir" ] && find "$dir" \
        ! -user "$DEV_UID" \
        -print -quit 2>/dev/null | grep -q .; then

        echo "   🔧 Correcting ownership: $dir"
        sudo chown -R "$DEV_UID:$DEV_GID" "$dir"
    fi
done

# ==============================================================================
# 7. SSH agent forwarding
# ==============================================================================

echo "🔑 Checking SSH agent forwarding..."

SSH_AGENT_SOCKET="${SSH_AUTH_SOCK:-${HOME}/.ssh/agent.sock}"

SSH_MOUNT_ARGS=()
SSH_ENV_ARGS=()

if [ -S "$SSH_AGENT_SOCKET" ]; then
    if SSH_AUTH_SOCK="$SSH_AGENT_SOCKET" ssh-add -L >/dev/null 2>&1; then
        echo "   ✅ WSL SSH agent is responding."

        SSH_MOUNT_ARGS=(
            -v "$SSH_AGENT_SOCKET:/run/host-services/ssh-auth.sock"
        )

        SSH_ENV_ARGS=(
            -e "SSH_AUTH_SOCK=/run/host-services/ssh-auth.sock"
        )
    else
        echo "⚠️ SSH socket exists, but agent is not responding."
        echo "   Continuing without SSH-agent forwarding."
    fi
else
    echo "⚠️ SSH agent socket not found: $SSH_AGENT_SOCKET"
    echo "   Continuing without SSH-agent forwarding."
fi

# ==============================================================================
# 8. WSLg / X11 GUI Forwarding (Linux Desktop UI on Windows)
# ==============================================================================

echo "🖥️ Checking GUI display forwarding (WSLg / X11)..."

GUI_MOUNT_ARGS=()
GUI_ENV_ARGS=()

if [ -n "${DISPLAY:-}" ] || [ -d "/tmp/.X11-unix" ] || [ -d "/mnt/wslg" ]; then
    echo "   ✅ WSLg / X11 GUI display forwarding active."
    
    GUI_ENV_ARGS+=(
        -e "DISPLAY=${DISPLAY:-:0}"
        -e "WAYLAND_DISPLAY=${WAYLAND_DISPLAY:-wayland-0}"
        -e "XDG_RUNTIME_DIR=/tmp/runtime-dir"
        -e "PULSE_SERVER=${PULSE_SERVER:-/mnt/wslg/PulseServer}"
        -e "LIBGL_ALWAYS_INDIRECT=0"
    )

    if [ -d "/tmp/.X11-unix" ]; then
        GUI_MOUNT_ARGS+=(-v "/tmp/.X11-unix:/tmp/.X11-unix")
    fi

    if [ -d "/mnt/wslg" ]; then
        GUI_MOUNT_ARGS+=(-v "/mnt/wslg:/mnt/wslg")
    fi

    if [ -d "/mnt/wslg/runtime-dir" ]; then
        GUI_MOUNT_ARGS+=(-v "/mnt/wslg/runtime-dir:/tmp/runtime-dir")
    fi
else
    echo "ℹ️ No GUI display environment detected. Running headless."
fi

# ==============================================================================
# 9. Existing container handling
# ==============================================================================

if docker container inspect "$CONTAINER_NAME" >/dev/null 2>&1; then
    echo "⚠️ Existing $CONTAINER_NAME container found."

    if docker inspect \
        --format '{{.State.Running}}' \
        "$CONTAINER_NAME" 2>/dev/null |
        grep -qx "true"; then

        echo "   🛑 Stopping existing container..."
        docker stop "$CONTAINER_NAME" >/dev/null
    fi

    echo "   🗑️ Removing existing container..."
    docker rm "$CONTAINER_NAME" >/dev/null

    echo "   ✅ Existing container removed."
fi

# ==============================================================================
# 10. Build image
# ==============================================================================

echo "🔨 Building $IMAGE_NAME..."

if ! docker build \
    --build-arg DOCKER_GID="$DOCKER_GID" \
    -t "$IMAGE_NAME" \
    -f .devcontainer/Dockerfile \
    "$TARGET_DIR"; then

    echo "❌ Docker image build failed."
    exit 1
fi

echo "✅ Docker image built."

# ==============================================================================
# 11. Start container
# ==============================================================================

echo "🚀 Starting $CONTAINER_NAME..."

RUN_ARGS=(
    -d
    --name "$CONTAINER_NAME"
    --restart unless-stopped

    # Allow Supabase CLI & Docker tools inside the container to use host Docker daemon
    --group-add "$DOCKER_GID"

    # Project source
    -v "$TARGET_DIR:/campverse"

    # Shared development hub
    -v "$DEV_HUB_ROOT:/home/vscode/dev-hub"
    -v "$SDKS_DIR:/home/vscode/sdk-mounts"
    -v "$BIN_DIR:/home/vscode/sdk-mounts/bin"

    # Shared caches
    -v "$NPM_CACHE_DIR:/home/vscode/.npm"
    -v "$CACHES_DIR/pub-cache:/home/vscode/.pub-cache"
    -v "$CACHES_DIR/gradle:/home/vscode/.gradle"

    # Host Docker daemon socket
    -v "$DOCKER_SOCKET:$DOCKER_SOCKET"

    # Port mappings
    -p 80:80        # Caddy Reverse Proxy API Gateway
    -p 3000:3000    # Web / Frontend Dev
    -p 8000:8000    # Deno Core API
    -p 8080:8080    # Go Realtime Chat & Workers
    -p 8181:8181    # Dart VM Service / DevTools
)

RUN_ARGS+=("${GUI_MOUNT_ARGS[@]}")
RUN_ARGS+=("${GUI_ENV_ARGS[@]}")
RUN_ARGS+=("${SSH_MOUNT_ARGS[@]}")
RUN_ARGS+=("${SSH_ENV_ARGS[@]}")

RUN_ARGS+=("$IMAGE_NAME")

if ! docker run "${RUN_ARGS[@]}"; then
    echo "❌ Failed to start $CONTAINER_NAME."

    if docker container inspect "$CONTAINER_NAME" >/dev/null 2>&1; then
        echo
        echo "📋 Container logs:"
        docker logs "$CONTAINER_NAME" 2>&1 || true
    fi

    exit 1
fi

# ==============================================================================
# 12. Verify container remains running
# ==============================================================================

sleep 1

if ! docker inspect \
    --format '{{.State.Running}}' \
    "$CONTAINER_NAME" 2>/dev/null |
    grep -qx "true"; then

    echo "❌ Container started but is no longer running."
    echo
    echo "📋 Container logs:"
    docker logs "$CONTAINER_NAME" 2>&1 || true
    exit 1
fi

echo
echo "✅ $CONTAINER_NAME is running."

# ==============================================================================
# 13. Display assigned ports
# ==============================================================================

echo
echo "🌐 Container port mappings:"
docker port "$CONTAINER_NAME" || true

echo
echo "📦 Shared Dev Hub:"
echo "   $DEV_HUB_ROOT"

echo "📁 Project:"
echo "   $TARGET_DIR"

echo
echo "🎉 CampVerse development environment ready."