# syntax=docker/dockerfile:1.4@sha256:9ba7531bd80fb0a858632727cf7a112fbfd19b17e94c4e84ced81e24ef1a0dbc

# Main Base Image (Ubuntu 24.04 GLIBC compatible)
FROM mcr.microsoft.com/devcontainers/base:2.1.7-ubuntu24.04@sha256:4bcb1b466771b1ba1ea110e2a27daea2f6093f9527fb75ee59703ec89b5561cb

USER root

# 1. Native System Runtimes & Dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    acl \
    adb \
    build-essential \
    ca-certificates \
    caddy \
    clang \
    cmake \
    curl \
    git \
    gnupg \
    jq \
    lcov \
    libgtk-3-dev \
    liblzma-dev \
    libnss3-tools \
    libsecret-1-dev \
    gnome-keyring \
    mesa-utils \
    ninja-build \
    openjdk-21-jdk-headless \
    pkg-config \
    python3 \
    redis-tools \
    socat \
    unzip \
    wget \
    zlib1g \
    && install -m 0755 -d /etc/apt/keyrings \
    # NodeSource Setup (Node 24 LTS)
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && chmod 644 /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_24.x nodistro main" > /etc/apt/sources.list.d/nodesource.list \
    # Docker CE Setup
    && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
    && chmod 644 /etc/apt/keyrings/docker.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu noble stable" > /etc/apt/sources.list.d/docker.list \
    && apt-get update && apt-get install -y --no-install-recommends \
    docker-buildx-plugin \
    docker-ce-cli \
    docker-compose-plugin \
    nodejs \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN npm install -g npm@latest

# 2. Configure Paths for Shared Host Mounts & Go Environment
USER vscode
ENV HOME="/home/vscode"
ENV FLUTTER_HOME="$HOME/sdk-mounts/flutter"
ENV ANDROID_HOME="$HOME/sdk-mounts/android"
ENV DENO_INSTALL="$HOME/sdk-mounts/deno"
ENV GO_HOME="$HOME/sdk-mounts/go"
ENV GOPATH="$HOME/go"
ENV PUB_CACHE="$HOME/.pub-cache"
ENV NODE_OPTIONS="--max-old-space-size=9216"
ENV PATH="$PATH:$HOME/sdk-mounts/bin:$FLUTTER_HOME/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$DENO_INSTALL/bin:$GO_HOME/bin:$GOPATH/bin:$PUB_CACHE/bin"

# 3. Bake IDE Settings & Cross-IDE Extension Symlinks
RUN mkdir -p $HOME/.antigravity-server/data/Machine \
             $HOME/.antigravity-ide-server/data/Machine \
             $HOME/.vscode-server/data/Machine \
             $HOME/.vscode-server/extensions \
             $HOME/go \
    && ln -s $HOME/.vscode-server/extensions $HOME/.antigravity-server/extensions \
    && ln -s $HOME/.vscode-server/extensions $HOME/.antigravity-ide-server/extensions \
    && SETTINGS='{ \
        "remote.forwardAgent": false, \
        "dart.flutterSdkPath": "/home/vscode/sdk-mounts/flutter", \
        "go.gopath": "/home/vscode/go", \
        "go.goroot": "/home/vscode/sdk-mounts/go", \
        "go.useLanguageServer": true, \
        "go.lintTool": "golangci-lint", \
        "go.lintOnSave": "package", \
        "gopls": { \
            "ui.semanticTokens": true, \
            "formatting.gofumpt": true \
        }, \
        "deno.enablePaths": ["services/deno_core"], \
        "editor.formatOnSave": true \
    }' \
    && echo "$SETTINGS" > $HOME/.antigravity-server/data/Machine/settings.json \
    && echo "$SETTINGS" > $HOME/.antigravity-ide-server/data/Machine/settings.json \
    && echo "$SETTINGS" > $HOME/.vscode-server/data/Machine/settings.json

# 4. Initialization Script Creation
USER root
COPY --chown=vscode:vscode --chmod=755 <<"EOF" /home/vscode/init_workspace.sh
#!/bin/bash
echo "🚀 Starting CampVerse Dev Workspace Setup..."

# --- 1. GIT CONFIG DIVERSION ---
if [ ! -L "/home/vscode/.gitconfig" ]; then
    if [ -f "/home/vscode/.gitconfig" ]; then
        mv /home/vscode/.gitconfig /home/vscode/.gitconfig_local
    else
        touch /home/vscode/.gitconfig_local
    fi
    ln -sf /home/vscode/.gitconfig_local /home/vscode/.gitconfig
fi
chmod 644 /home/vscode/.gitconfig_local 2>/dev/null || true

# --- 2. SSH AGENT & SIGNING SETUP ---
echo "🔑 Checking SSH Agent Forwarding..."
HAS_SSH_KEY=false
if [ -S "$SSH_AUTH_SOCK" ] && ssh-add -L >/dev/null 2>&1; then
    CLEAN_KEY=$(ssh-add -L 2>/dev/null | tr -d '\r' | head -n 1)

    if [ -n "$CLEAN_KEY" ]; then
        HAS_SSH_KEY=true
        git config --global user.signingkey "$CLEAN_KEY"
        git config --global gpg.format ssh
        git config --global commit.gpgsign true
        echo "✅ SSH signing enabled."
    fi
else
    echo "⚠️ SSH Agent is not active or has no keys loaded."
fi

# --- 3. GIT IDENTITY ---
CURRENT_NAME=$(git config --global user.name 2>/dev/null)
CURRENT_EMAIL=$(git config --global user.email 2>/dev/null)

if [ -z "$CURRENT_NAME" ] || [ -z "$CURRENT_EMAIL" ]; then
    if [ -t 0 ]; then
        echo "👤 Setting up Git identity..."
        [ -z "$CURRENT_NAME" ] && read -rp "Enter Git Name: " CURRENT_NAME && git config --global user.name "$CURRENT_NAME"
        [ -z "$CURRENT_EMAIL" ] && read -rp "Enter Git Email: " CURRENT_EMAIL && git config --global user.email "$CURRENT_EMAIL"
    else
        AUTO_EMAIL=$(ssh-add -L 2>/dev/null | awk '{print $3}' | grep "@" | head -n 1)
        [ -z "$CURRENT_NAME" ] && git config --global user.name "${GIT_NAME:-User}"
        [ -z "$CURRENT_EMAIL" ] && git config --global user.email "${GIT_EMAIL:-${AUTO_EMAIL:-dev@example.com}}"
        echo "ℹ️ Auto-configured Git identity: $(git config --global user.name) <$(git config --global user.email)>"
    fi
fi

# --- 4. POPULATE ALLOWED SIGNERS ---
if [ "$HAS_SSH_KEY" = true ]; then
    FINAL_EMAIL=$(git config --global user.email)
    ALLOWED_SIGNERS_FILE="/home/vscode/.ssh/allowed_signers"
    
    mkdir -p /home/vscode/.ssh && chmod 700 /home/vscode/.ssh
    echo "${FINAL_EMAIL:-*} ${CLEAN_KEY}" > "$ALLOWED_SIGNERS_FILE"
    chmod 600 "$ALLOWED_SIGNERS_FILE"
    
    git config --global gpg.ssh.allowedSignersFile "$ALLOWED_SIGNERS_FILE"
    echo "✅ Local SSH signature verification configured for ${FINAL_EMAIL:-*}"
fi

TARGET_DIR="${WORKSPACE_DIR:-/campverse}"
if [ ! -d "$TARGET_DIR" ] && [ -d "$PWD" ]; then
    TARGET_DIR="$PWD"
fi
git config --global --add safe.directory "$TARGET_DIR"

# --- 5. GO TOOLCHAIN INSTALLATION ---
if command -v go >/dev/null 2>&1; then
    echo "🐹 Checking Go Developer Tools (gopls, dlv, golangci-lint)..."
    mkdir -p "$GOPATH/bin"
    if [ ! -x "$GOPATH/bin/gopls" ]; then
        echo "  ⬇️ Installing gopls..."
        go install -v golang.org/x/tools/gopls@latest >/dev/null 2>&1 || true
    fi
    if [ ! -x "$GOPATH/bin/dlv" ]; then
        echo "  ⬇️ Installing dlv debugger..."
        go install -v github.com/go-delve/delve/cmd/dlv@latest >/dev/null 2>&1 || true
    fi
    if [ ! -x "$GOPATH/bin/golangci-lint" ]; then
        echo "  ⬇️ Installing golangci-lint..."
        go install -v github.com/golangci/golangci-lint/cmd/golangci-lint@latest >/dev/null 2>&1 || true
    fi
    echo "✅ Go Developer Tools ready."
fi

# --- 6. MONOREPO DEPENDENCIES SYNCHRONIZATION ---
# Flutter Client Sync
if command -v flutter >/dev/null 2>&1; then
    flutter config --enable-linux-desktop >/dev/null 2>&1 || true
fi

if [ -d "$TARGET_DIR/campverse_client" ] && command -v flutter >/dev/null 2>&1; then 
    echo "🐦 Synchronizing Flutter Client packages..."
    (cd "$TARGET_DIR/campverse_client" && flutter pub get)
elif [ -d "$TARGET_DIR/apps/flutter" ] && command -v flutter >/dev/null 2>&1; then
    echo "🐦 Synchronizing Flutter Client packages..."
    (cd "$TARGET_DIR/apps/flutter" && flutter pub get)
fi

# Go Backend Sync
if [ -f "$TARGET_DIR/services/go_core/go.mod" ] && command -v go >/dev/null 2>&1; then
    echo "🐹 Synchronizing Go Core dependencies..."
    (cd "$TARGET_DIR/services/go_core" && go mod download)
fi

# Root / NPM Tooling Sync
if [ -f "$TARGET_DIR/package.json" ]; then 
    echo "📦 Synchronizing NPM packages..."
    (cd "$TARGET_DIR" && npm ci --legacy-peer-deps 2>/dev/null || npm install)
fi

# --- 7. EXTENSION SYNC ---
EXTENSIONS=(
  "golang.go"
  "Dart-Code.flutter"
  "Dart-Code.dart-code"
  "denoland.vscode-deno"
  "cweijan.vscode-database-client2"
  "esbenp.prettier-vscode"
  "formulahendry.auto-rename-tag"
  "christian-kohler.path-intellisense"
  "davidanson.vscode-markdownlint"
  "oderwat.indent-rainbow"
  "usernamehw.errorlens"
)

echo "🔍 Searching for primary IDE server binary..."
PRIMARY_CLI=""

while IFS= read -r binary_path; do
    if [ -n "$binary_path" ] && "$binary_path" --version >/dev/null 2>&1; then
        PRIMARY_CLI="$binary_path"
        break
    fi
done < <(find ~/.vscode-server ~/.antigravity-server ~/.antigravity-ide-server ~/.cursor-server -type f -executable \( -name "code-server" -o -name "antigravity-server" -o -name "antigravity-ide-server" -o -name "cursor-server" \) 2>/dev/null || true)

if [ -n "$PRIMARY_CLI" ]; then
    echo "🔧 Synchronizing extensions via: $PRIMARY_CLI"
    INSTALLED_EXTS=$("$PRIMARY_CLI" --list-extensions 2>/dev/null | tr '[:upper:]' '[:lower:]')

    for ext in "${EXTENSIONS[@]}"; do
        EXT_LOWER=$(echo "$ext" | tr '[:upper:]' '[:lower:]')
        if ! echo "$INSTALLED_EXTS" | grep -q "^${EXT_LOWER}$"; then
            echo "  ⬇️ Installing extension: $ext"
            "$PRIMARY_CLI" --install-extension "$ext" --force >/dev/null 2>&1 || true
        fi
    done
else
    echo "ℹ️ IDE server binary pending connection. Extensions will synchronize upon IDE attachment."
fi

supabase-proxy start >/dev/null 2>&1 || true

echo "🎯 CampVerse Workspace Initialization Complete!"
EOF

RUN sed -i 's/\r$//' /home/vscode/init_workspace.sh

RUN groupadd -g 989 docker-host 2>/dev/null || true \
    && usermod -aG docker-host vscode 2>/dev/null || true

# Supabase devcontainer loopback proxy
RUN cat <<'EOF' > /usr/local/bin/supabase-proxy \
    && chmod +x /usr/local/bin/supabase-proxy
#!/usr/bin/env bash
HOST_IP=$(ip route | awk '/default/ { print $3 }')
[ -z "$HOST_IP" ] && HOST_IP="172.17.0.1"

PORTS=(54320 54321 54322 54323 54324 54327 54329)

case "$1" in
  stop)
    pkill -f "socat.*bind=127.0.0.1" 2>/dev/null || true
    echo "Supabase proxy stopped."
    ;;
  status)
    for p in "${PORTS[@]}"; do
      if ss -tlpn | grep -q "127.0.0.1:$p"; then
        echo "Port $p: PROXIED -> $HOST_IP:$p"
      else
        echo "Port $p: NOT RUNNING"
      fi
    done
    ;;
  start|*)
    for p in "${PORTS[@]}"; do
      if ! ss -tlpn | grep -q "127.0.0.1:$p"; then
        setsid -f socat TCP-LISTEN:$p,fork,reuseaddr,bind=127.0.0.1 TCP:$HOST_IP:$p
      fi
    done
    echo "Supabase proxy started forwarding to host ($HOST_IP)."
    ;;
esac
EOF

# 5. User Environment Defaults & Entrypoint
USER vscode
RUN echo 'if [ -t 1 ]; then (while true; do printf "\033[0m" > /dev/tty 2>/dev/null; sleep 25; done) >/dev/null 2>&1 & disown $! 2>/dev/null; fi' >> /home/vscode/.bashrc \
    && echo 'supabase-proxy start >/dev/null 2>&1' >> /home/vscode/.bashrc
WORKDIR /campverse
EXPOSE 80 3000 8000 8080 8181
CMD ["sleep", "infinity"]