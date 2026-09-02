#!/usr/bin/env bash
set -eo pipefail

echo "🚀 Starting Campverse Backend Services (Diskless Infisical)..."

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Trap Ctrl+C and exit signals to cleanly kill child servers
cleanup() {
    echo ""
    echo "🛑 Shutting down all services..."
    trap - SIGINT SIGTERM EXIT
    kill $(jobs -p) 2>/dev/null || true
    sudo pkill -f "caddy run --config" 2>/dev/null || true
    wait 2>/dev/null || true
    echo "✨ All services stopped."
}
trap cleanup SIGINT SIGTERM EXIT

# 1. Start Deno Core (port 8000)
echo "🦖 [1/3] Launching Deno Core API (:8000)..."
(
  cd "$ROOT_DIR/services/deno_core"
  exec infisical run --path=/public --path=/runtime -- deno run --watch --allow-net --allow-env src/server.ts
) &

# 2. Start Go Chat Server (port 8080)
echo "🐹 [2/3] Launching Go Chat Gateway (:8080)..."
(
  cd "$ROOT_DIR/services/go_core"
  exec infisical run --path=/public --path=/runtime -- go run ./cmd/chat_server/main.go
) &

# 3. Start Caddy API Gateway (port 80 -> :8000 & :8080)
echo "🌐 [3/3] Launching Caddy API Gateway (:80)..."
(
  cd "$ROOT_DIR/services/api_gateway"
  exec sudo caddy run --config ./Caddyfile
) &

echo "✅ All servers running! Press Ctrl+C to terminate all services."
wait
