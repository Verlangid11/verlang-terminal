#!/bin/bash

set -euo pipefail

export PATH="/usr/local/node/bin:/usr/local/bun/bin:/usr/local/go/bin:/usr/local/cargo/bin:/usr/local/bin:\( {JAVA_HOME}/bin: \){DOTNET_ROOT}:${DOTNET_ROOT}/tools:$PATH"
export PLAYWRIGHT_BROWSERS_PATH="/usr/local/share/playwright"
export RUSTUP_HOME="/usr/local/rustup"
export CARGO_HOME="/usr/local/cargo"
export JAVA_HOME="/usr/local/java"
export DOTNET_ROOT="/usr/local/dotnet"

echo "export PATH=\"/usr/local/node/bin:/usr/local/bun/bin:/usr/local/go/bin:/usr/local/cargo/bin:/usr/local/bin:\( {JAVA_HOME}/bin: \){DOTNET_ROOT}:${DOTNET_ROOT}/tools:\$PATH\"" >> ~/.bashrc
echo "export PLAYWRIGHT_BROWSERS_PATH=\"$PLAYWRIGHT_BROWSERS_PATH\"" >> ~/.bashrc
echo "export RUSTUP_HOME=\"$RUSTUP_HOME\"" >> ~/.bashrc
echo "export CARGO_HOME=\"$CARGO_HOME\"" >> ~/.bashrc
echo "export JAVA_HOME=\"$JAVA_HOME\"" >> ~/.bashrc
echo "export DOTNET_ROOT=\"$DOTNET_ROOT\"" >> ~/.bashrc

if [ -n "${NODE_VERSION:-}" ]; then
    CURRENT_VER=$(node -v 2>/dev/null || echo "none")
    INDEX_JSON=$(curl -s https://nodejs.org/dist/index.json)
    TARGET_VER=$(echo "\( INDEX_JSON" | jq -r --arg ver " \){NODE_VERSION}" 'map(select(.version | startswith("v\($ver)"))) | .[0].version // empty')
    [ -z "\( TARGET_VER" ] && TARGET_VER="v \){NODE_VERSION}.0.0"

    if [ "$CURRENT_VER" != "$TARGET_VER" ]; then
        echo "Installing Node ${TARGET_VER}..."
        rm -rf /usr/local/node/*
        curl -fsSL "https://nodejs.org/dist/\( {TARGET_VER}/node- \){TARGET_VER}-linux-x64.tar.gz" -o /tmp/node.tar.gz
        tar -xzf /tmp/node.tar.gz --strip-components=1 -C /usr/local/node
        rm /tmp/node.tar.gz
        /usr/local/node/bin/npm install -g npm@latest pnpm yarn pm2 playwright --loglevel=error
    fi
fi

if [[ "\( {ENABLE_CF_TUNNEL:-false}" =~ ^(true|1) \) ]] && [ -n "${CF_TOKEN:-}" ]; then
    pkill -f cloudflared 2>/dev/null || true
    nohup cloudflared tunnel --loglevel info run --token "${CF_TOKEN}" > ~/.cloudflared.log 2>&1 &
fi

clear
echo -e "\033[34m╔════════════════════════════════════════════════════════════════════╗\033[0m"
echo -e "\033[34m║                    \033[1;36mVERLANGID TERMINAL\033[0m                             ║\033[0m"
echo -e "\033[34m║               \033[1;34mMulti-Language • Bot • Script • Automation\033[0m              ║\033[0m"
echo -e "\033[34m╚════════════════════════════════════════════════════════════════════╝\033[0m"
echo ""

echo -e "\033[34m┌────────────────────────────────────────────────────────────────────┐\033[0m"
echo -e "\033[34m│ \033[1;32mLocation\033[0m : $(curl -s ipinfo.io/country 2>/dev/null || echo '—')                                      \033[34m│\033[0m"
echo -e "\033[34m│ \033[1;32mOS      \033[0m : $(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)                           \033[34m│\033[0m"
echo -e "\033[34m│ \033[1;32mCPU     \033[0m : $(awk -F: '/model name/ {print $2; exit}' /proc/cpuinfo | sed 's/^[ \t]*//') (\033[1;32m$(nproc)\033[0m cores) \033[34m│\033[0m"
echo -e "\033[34m│ \033[1;32mUptime  \033[0m : $(uptime -p | sed 's/up //')                                       \033[34m│\033[0m"
echo -e "\033[34m└────────────────────────────────────────────────────────────────────┘\033[0m"
echo ""

echo -e "\033[34m┌───────────────────── \033[1;33mResource Usage\033[0m ─────────────────────┐\033[0m"
echo -e "\033[34m│ \033[1;33mRAM\033[0m : $(free -h | awk '/Mem:/ {print $3 " / " $2 " (" $5 ")"}')   \033[34m│\033[0m"
echo -e "\033[34m│ \033[1;33mDisk\033[0m: $(df -h / | awk 'NR==2 {print $3 " / " $2 " (" $5 ")"}')  \033[34m│\033[0m"
echo -e "\033[34m└────────────────────────────────────────────────────────────┘\033[0m"
echo ""

echo -e "\033[1;34mRuntime Versions (2026 Stable)\033[0m"
echo -e "\033[34m────────────────────────────────────────────────────────────────────\033[0m"
echo -e " \033[1;32mNode.js    \033[0m : $(node -v 2>/dev/null || echo '—')"
echo -e " \033[1;32mBun        \033[0m : $(bun -v 2>/dev/null || echo '—')"
echo -e " \033[1;32mDeno       \033[0m : $(deno --version 2>/dev/null | head -n1 || echo '—')"
echo -e " \033[1;32mPython     \033[0m : $(python3 --version 2>/dev/null | awk '{print $2}' || echo '—')"
echo -e " \033[1;32mGo         \033[0m : $(go version 2>/dev/null | awk '{print $3}' || echo '—')"
echo -e " \033[1;32mRust       \033[0m : $(rustc --version 2>/dev/null || echo '—')"
echo -e " \033[1;32mJava       \033[0m : $(java -version 2>&1 | head -n1 | grep version || echo '—')"
echo -e " \033[1;32mPHP        \033[0m : $(php -v 2>/dev/null | head -n1 | awk '{print $2}' || echo '—')"
echo -e " \033[1;32m.NET       \033[0m : $(dotnet --version 2>/dev/null || echo '—')"
echo -e " \033[1;32mLua        \033[0m : $(lua -v 2>/dev/null || echo '—')"
echo -e " \033[1;32mPlaywright \033[0m : $(playwright --version 2>/dev/null | head -n1 || echo '—')"
echo -e "\033[34m────────────────────────────────────────────────────────────────────\033[0m"
echo ""

update_prompt() {
    local ram=$(free -m | awk '/Mem:/ {printf "%.1f%%", $3*100/$2}')
    local disk=$(df -h / | awk 'NR==2 {printf "%s", $5}')
    local load=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}')
    PS1="\n\033[1;34m[container@\h] \033[1;36m\w \033[1;33m[RAM:\( {ram} | Disk: \){disk} | Load:${load}]\033[0m\n\033[1;32m→ \033[0m"
}

PROMPT_COMMAND='update_prompt'

echo -e "\033[1;32mSystem ready! Multi-language powerhouse ready for bots, scripts & more.\033[0m"
echo -e "\033[1;36mExamples: node bot.js | bun run index.ts | deno run main.ts | python3 script.py | php bot.php | dotnet run\033[0m"
echo ""

exec /bin/bash -i
