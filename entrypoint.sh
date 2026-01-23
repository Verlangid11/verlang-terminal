#!/bin/bash

NODE_DIR="/home/container/node"
BUN_DIR="/usr/local/bun"
GO_DIR="/usr/local/go"
export PLAYWRIGHT_BROWSERS_PATH="/usr/local/share/playwright"

mkdir -p "$NODE_DIR"
export PATH="$NODE_DIR/bin:$BUN_DIR/bin:$GO_DIR/bin:$HOME/.cargo/bin:$PATH"

echo "export PATH=\"$NODE_DIR/bin:$BUN_DIR/bin:$GO_DIR/bin:\$PATH\"" > /home/container/.bashrc
echo "export NODE_PATH=\"$NODE_DIR/lib/node_modules\"" >> /home/container/.bashrc
echo "export PLAYWRIGHT_BROWSERS_PATH=\"$PLAYWRIGHT_BROWSERS_PATH\"" >> /home/container/.bashrc

if [ ! -z "${NODE_VERSION}" ]; then
    [ -x "$NODE_DIR/bin/node" ] && CURRENT_VER=$("$NODE_DIR/bin/node" -v) || CURRENT_VER="none"
    TARGET_VER=$(curl -s https://nodejs.org/dist/index.json | jq -r 'map(select(.version)) | .[] | select(.version | startswith("v'${NODE_VERSION}'")) | .version' 2>/dev/null | head -n 1)
    
    if [ -z "$TARGET_VER" ] || [ "$TARGET_VER" == "null" ]; then
         if [[ "${NODE_VERSION}" == v* ]]; then TARGET_VER="${NODE_VERSION}"; else TARGET_VER="v${NODE_VERSION}.0.0"; fi
    fi

    if [[ "$CURRENT_VER" != "$TARGET_VER" ]]; then
        rm -rf $NODE_DIR/* && cd /tmp
        curl -fL "https://nodejs.org/dist/${TARGET_VER}/node-${TARGET_VER}-linux-x64.tar.gz" -o node.tar.gz
        tar -xf node.tar.gz --strip-components=1 -C "$NODE_DIR" && rm node.tar.gz
        "$NODE_DIR/bin/npm" install -g npm@latest pm2 pnpm yarn nodemon playwright typescript ts-node --loglevel=error
        cd /home/container
    fi
fi

if [[ "${ENABLE_CF_TUNNEL}" == "true" ]] || [[ "${ENABLE_CF_TUNNEL}" == "1" ]]; then
    if [ ! -z "${CF_TOKEN}" ]; then
        pkill -f cloudflared 2>/dev/null
        nohup cloudflared tunnel run --token ${CF_TOKEN} > /home/container/.cloudflared.log 2>&1 &
        sleep 2
    fi
fi

clear

C_RESET="\e[0m"
C_CYAN="\e[1;36m"
C_GREEN="\e[1;32m"
C_YELLOW="\e[1;33m"
C_BLUE="\e[1;34m"
C_MAGENTA="\e[1;35m"
C_RED="\e[1;31m"
C_WHITE="\e[1;37m"
C_GRAY="\e[0;37m"

echo -e "${C_CYAN}"
cat << "EOF"
██╗   ██╗███████╗██████╗ ██╗      █████╗ ███╗   ██╗ ██████╗ ██╗██████╗ 
██║   ██║██╔════╝██╔══██╗██║     ██╔══██╗████╗  ██║██╔════╝ ██║██╔══██╗
██║   ██║█████╗  ██████╔╝██║     ███████║██╔██╗ ██║██║  ███╗██║██║  ██║
╚██╗ ██╔╝██╔══╝  ██╔══██╗██║     ██╔══██║██║╚██╗██║██║   ██║██║██║  ██║
 ╚████╔╝ ███████╗██║  ██║███████╗██║  ██║██║ ╚████║╚██████╔╝██║██████╔╝
  ╚═══╝  ╚══════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝╚═════╝ 
EOF
echo -e "${C_RESET}"

echo -e "${C_BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
echo -e "${C_WHITE}                    MULTI-RUNTIME TERMINAL${C_RESET}"
echo -e "${C_BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
echo ""

LOCATION=$(curl -s ipinfo.io/country 2>/dev/null || echo 'Unknown')
CITY=$(curl -s ipinfo.io/city 2>/dev/null || echo 'Unknown')
IP=$(curl -s ipinfo.io/ip 2>/dev/null || echo 'Unknown')
OS=$(grep -oP '(?<=^PRETTY_NAME=).+' /etc/os-release | tr -d '"')
KERNEL=$(uname -r)
CPU_MODEL=$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | xargs)
CPU_CORES=$(grep -c ^processor /proc/cpuinfo)
CPU_FREQ=$(grep -m1 'cpu MHz' /proc/cpuinfo | awk '{printf "%.2f GHz", $4/1000}')
UPTIME=$(uptime -p | sed 's/up //')
LOAD_AVG=$(uptime | awk -F'load average:' '{print $2}' | xargs)

echo -e "${C_YELLOW}╔═══════════════════════════════════════════════════════════════════╗${C_RESET}"
echo -e "${C_YELLOW}║${C_RESET} ${C_GREEN}Location${C_RESET}       : ${C_CYAN}${CITY}, ${LOCATION}${C_RESET} ${C_GRAY}(IP: ${IP})${C_RESET}"
echo -e "${C_YELLOW}║${C_RESET} ${C_GREEN}OS${C_RESET}             : ${C_CYAN}${OS}${C_RESET}"
echo -e "${C_YELLOW}║${C_RESET} ${C_GREEN}Kernel${C_RESET}         : ${C_CYAN}${KERNEL}${C_RESET}"
echo -e "${C_YELLOW}║${C_RESET} ${C_GREEN}CPU${C_RESET}            : ${C_CYAN}${CPU_MODEL}${C_RESET}"
echo -e "${C_YELLOW}║${C_RESET} ${C_GREEN}CPU Cores${C_RESET}      : ${C_CYAN}${CPU_CORES} Cores${C_RESET} @ ${C_CYAN}${CPU_FREQ}${C_RESET}"
echo -e "${C_YELLOW}║${C_RESET} ${C_GREEN}Load Average${C_RESET}   : ${C_CYAN}${LOAD_AVG}${C_RESET}"
echo -e "${C_YELLOW}║${C_RESET} ${C_GREEN}Uptime${C_RESET}         : ${C_CYAN}${UPTIME}${C_RESET}"
echo -e "${C_YELLOW}╚═══════════════════════════════════════════════════════════════════╝${C_RESET}"
echo ""

RAM_USED=$(free -m | awk '/Mem:/ {print $3}')
RAM_TOTAL=$(free -m | awk '/Mem:/ {print $2}')
RAM_PERCENT=$(free -m | awk '/Mem:/ {printf "%.1f", ($3/$2)*100}')
RAM_AVAILABLE=$(free -m | awk '/Mem:/ {print $7}')

SWAP_USED=$(free -m | awk '/Swap:/ {print $3}')
SWAP_TOTAL=$(free -m | awk '/Swap:/ {print $2}')
if [ "$SWAP_TOTAL" -gt 0 ]; then
    SWAP_PERCENT=$(free -m | awk '/Swap:/ {printf "%.1f", ($3/$2)*100}')
else
    SWAP_PERCENT="0.0"
fi

DISK_USED=$(df -h / | awk 'NR==2 {print $3}')
DISK_TOTAL=$(df -h / | awk 'NR==2 {print $2}')
DISK_PERCENT=$(df -h / | awk 'NR==2 {print $5}')
DISK_AVAILABLE=$(df -h / | awk 'NR==2 {print $4}')

INODE_USED=$(df -i / | awk 'NR==2 {print $3}')
INODE_TOTAL=$(df -i / | awk 'NR==2 {print $2}')
INODE_PERCENT=$(df -i / | awk 'NR==2 {print $5}')

NET_RX=$(cat /sys/class/net/eth0/statistics/rx_bytes 2>/dev/null | awk '{printf "%.2f MB", $1/1024/1024}' || echo "0 MB")
NET_TX=$(cat /sys/class/net/eth0/statistics/tx_bytes 2>/dev/null | awk '{printf "%.2f MB", $1/1024/1024}' || echo "0 MB")

echo -e "${C_MAGENTA}┌─────────────────────────────────────────────────────────────────┐${C_RESET}"
echo -e "${C_MAGENTA}│${C_RESET} ${C_WHITE}RAM${C_RESET}            : ${C_GREEN}${RAM_USED}MB${C_RESET} / ${C_CYAN}${RAM_TOTAL}MB${C_RESET} ${C_YELLOW}(${RAM_PERCENT}%)${C_RESET} ${C_GRAY}[Free: ${RAM_AVAILABLE}MB]${C_RESET}"
echo -e "${C_MAGENTA}│${C_RESET} ${C_WHITE}SWAP${C_RESET}           : ${C_GREEN}${SWAP_USED}MB${C_RESET} / ${C_CYAN}${SWAP_TOTAL}MB${C_RESET} ${C_YELLOW}(${SWAP_PERCENT}%)${C_RESET}"
echo -e "${C_MAGENTA}│${C_RESET} ${C_WHITE}Disk${C_RESET}           : ${C_GREEN}${DISK_USED}${C_RESET} / ${C_CYAN}${DISK_TOTAL}${C_RESET} ${C_YELLOW}${DISK_PERCENT}${C_RESET} ${C_GRAY}[Free: ${DISK_AVAILABLE}]${C_RESET}"
echo -e "${C_MAGENTA}│${C_RESET} ${C_WHITE}Inodes${C_RESET}         : ${C_GREEN}${INODE_USED}${C_RESET} / ${C_CYAN}${INODE_TOTAL}${C_RESET} ${C_YELLOW}${INODE_PERCENT}${C_RESET}"
echo -e "${C_MAGENTA}│${C_RESET} ${C_WHITE}Network${C_RESET}        : ${C_CYAN}↓ ${NET_RX}${C_RESET} ${C_GRAY}|${C_RESET} ${C_GREEN}↑ ${NET_TX}${C_RESET}"
echo -e "${C_MAGENTA}└─────────────────────────────────────────────────────────────────┘${C_RESET}"
echo ""

if pgrep -f cloudflared > /dev/null; then
    CF_STATUS="${C_GREEN}✓ Active${C_RESET}"
else
    CF_STATUS="${C_RED}✗ Inactive${C_RESET}"
fi

echo -e "${C_BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
echo -e "${C_WHITE}                       INSTALLED RUNTIMES${C_RESET}"
echo -e "${C_BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
echo ""

print_runtime() {
    local name=$1
    local cmd=$2
    local version=$(eval "$cmd" 2>/dev/null || echo 'Not Installed')
    if [[ "$version" == "Not Installed" ]]; then
        echo -e "${C_WHITE}${name}${C_RESET}$(printf '%*s' $((15-${#name})) '') : ${C_RED}${version}${C_RESET}"
    else
        echo -e "${C_WHITE}${name}${C_RESET}$(printf '%*s' $((15-${#name})) '') : ${C_GREEN}${version}${C_RESET}"
    fi
}

print_runtime "Node.js" "node -v"
print_runtime "Bun" "echo v\$(bun -v)"
print_runtime "Deno" "deno --version | head -n1 | awk '{print \$2}'"
print_runtime "Python" "python3 --version | awk '{print \$2}'"
print_runtime "Go" "go version | awk '{print \$3}' | sed 's/go//'"
print_runtime "Zig" "zig version"
print_runtime "Ruby" "ruby -v | awk '{print \$2}'"
print_runtime "PHP" "php -v | head -n1 | awk '{print \$2}'"
print_runtime "Java" "java -version 2>&1 | head -n1 | awk -F '\"' '{print \$2}'"
print_runtime "Playwright" "playwright --version | head -n1"

echo ""
echo -e "${C_BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
echo -e "${C_WHITE}                       INSTALLED TOOLS${C_RESET}"
echo -e "${C_BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
echo ""

print_runtime "FFmpeg" "ffmpeg -version | head -n1 | awk '{print \$3}'"
print_runtime "ImageMagick" "convert -version | head -n1 | awk '{print \$3}'"
print_runtime "WebP" "cwebp -version 2>&1 | head -n1 | awk '{print \$2}'"
print_runtime "PM2" "pm2 -v"
print_runtime "Nodemon" "nodemon -v"
print_runtime "TypeScript" "tsc -v"
print_runtime "PNPM" "pnpm -v"
print_runtime "Yarn" "yarn -v"
print_runtime "Git" "git --version | awk '{print \$3}'"
print_runtime "Composer" "composer --version 2>/dev/null | head -n1 | awk '{print \$3}'"
print_runtime "Bundler" "bundler -v"
print_runtime "CF Tunnel" "echo '$CF_STATUS'"

echo ""
echo -e "${C_BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
echo -e "${C_YELLOW}  📞 Telegram: ${C_CYAN}t.me/verlangid11${C_RESET}"
echo -e "${C_YELLOW}  ▶️ Youtube  : ${C_CYAN}https://www.youtube.com/@verlangid${C_RESET}"
echo -e "${C_YELLOW}  💼 TikTok  : ${C_CYAN}tiktok.com/@verlangid${C_RESET}"
echo -e "${C_BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
echo ""

exec /bin/bash
