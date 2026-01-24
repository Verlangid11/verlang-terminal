#!/bin/bash

NODE_DIR="/home/container/node"
BUN_DIR="/usr/local/bun"
DENO_DIR="/usr/local"
GO_DIR="/usr/local/go"
ZIG_DIR="/usr/local/zig"
export PLAYWRIGHT_BROWSERS_PATH="/usr/local/share/playwright"
export PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
export PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium

mkdir -p "$NODE_DIR"
export PATH="$NODE_DIR/bin:$BUN_DIR/bin:$DENO_DIR/bin:$GO_DIR/bin:$ZIG_DIR:$HOME/.cargo/bin:$HOME/go/bin:$PATH"

cat > /home/container/.bashrc << 'EOF'
export PATH="$HOME/node/bin:/usr/local/bun/bin:/usr/local/bin:/usr/local/go/bin:/usr/local/zig:$HOME/.cargo/bin:$HOME/go/bin:$PATH"
export NODE_PATH="$HOME/node/lib/node_modules"
export PLAYWRIGHT_BROWSERS_PATH="/usr/local/share/playwright"
export PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium
export GOPATH="$HOME/go"

alias ll='ls -alh'
alias cls='clear'
alias pm2ls='pm2 list'
alias pm2log='pm2 logs'
alias redis-start='redis-server --daemonize yes --bind 127.0.0.1'
alias redis-stop='redis-cli shutdown'
alias mysql-start='mysqld_safe --skip-grant-tables &'
alias serve='npx http-server -p 8080'
EOF

if [ ! -z "${HTTP_PROXY}" ]; then
    export HTTP_PROXY="${HTTP_PROXY}"
    export HTTPS_PROXY="${HTTP_PROXY}"
    export http_proxy="${HTTP_PROXY}"
    export https_proxy="${HTTP_PROXY}"
    echo "export HTTP_PROXY=\"${HTTP_PROXY}\"" >> /home/container/.bashrc
    echo "export HTTPS_PROXY=\"${HTTP_PROXY}\"" >> /home/container/.bashrc
fi

if [ ! -z "${NODE_VERSION}" ]; then
    [ -x "$NODE_DIR/bin/node" ] && CURRENT_VER=$("$NODE_DIR/bin/node" -v) || CURRENT_VER="none"
    TARGET_VER=$(curl -s https://nodejs.org/dist/index.json | jq -r 'map(select(.version)) | .[] | select(.version | startswith("v'${NODE_VERSION}'")) | .version' 2>/dev/null | head -n 1)
    
    if [ -z "$TARGET_VER" ] || [ "$TARGET_VER" == "null" ]; then
         if [[ "${NODE_VERSION}" == v* ]]; then TARGET_VER="${NODE_VERSION}"; else TARGET_VER="v${NODE_VERSION}.0.0"; fi
    fi

    if [[ "$CURRENT_VER" != "$TARGET_VER" ]]; then
        rm -rf $NODE_DIR/* && cd /tmp
        curl -fL "https://nodejs.org/dist/${TARGET_VER}/node-${TARGET_VER}-linux-x64.tar.gz" -o node.tar.gz 2>/dev/null
        tar -xf node.tar.gz --strip-components=1 -C "$NODE_DIR" 2>/dev/null && rm node.tar.gz
        "$NODE_DIR/bin/npm" install -g npm@latest pm2 pnpm yarn nodemon \
            typescript ts-node playwright puppeteer \
            @nestjs/cli eslint prettier --loglevel=error 2>/dev/null
        cd /home/container
    fi
fi

if [[ "${ENABLE_REDIS}" == "true" ]]; then
    REDIS_MEM="${REDIS_MAXMEMORY:-256mb}"
    redis-server --daemonize yes --bind 127.0.0.1 --port 6379 \
        --maxmemory $REDIS_MEM --maxmemory-policy allkeys-lru \
        --save "" --appendonly no 2>/dev/null &
fi

if [[ "${ENABLE_MARIADB}" == "true" ]]; then
    if [ ! -d "/var/lib/mysql/mysql" ]; then
        mysql_install_db --user=mysql --basedir=/usr --datadir=/var/lib/mysql 2>/dev/null
    fi
    mysqld_safe --skip-grant-tables --bind-address=127.0.0.1 2>/dev/null &
    sleep 3
    if [ ! -z "${MYSQL_ROOT_PASSWORD}" ]; then
        mysql -e "FLUSH PRIVILEGES; ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}'; FLUSH PRIVILEGES;" 2>/dev/null
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
C_WHITE="\e[1;37m"
C_GRAY="\e[0;90m"
C_MAGENTA="\e[1;35m"

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

LOCATION=$(curl -s ipinfo.io/country 2>/dev/null || echo 'Unknown')
CITY=$(curl -s ipinfo.io/city 2>/dev/null || echo 'Unknown')
OS=$(grep -oP '(?<=^PRETTY_NAME=).+' /etc/os-release | tr -d '"')
CPU_MODEL=$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | xargs | cut -c1-35)
CPU_CORES=$(grep -c ^processor /proc/cpuinfo)
UPTIME=$(uptime -p | sed 's/up //')

RAM_USED=$(free -m | awk '/Mem:/ {print $3}')
RAM_TOTAL=$(free -m | awk '/Mem:/ {print $2}')
RAM_PERCENT=$(free -m | awk '/Mem:/ {printf "%.0f", ($3/$2)*100}')

DISK_USED=$(df -h / | awk 'NR==2 {print $3}')
DISK_TOTAL=$(df -h / | awk 'NR==2 {print $2}')
DISK_PERCENT=$(df -h / | awk 'NR==2 {print $5}')

echo -e "${C_BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
echo -e "${C_WHITE}  📍 ${C_CYAN}${CITY}, ${LOCATION} ${C_GRAY}• ${C_WHITE}${OS}${C_RESET}"
echo -e "${C_WHITE}  🖥️  ${C_CYAN}${CPU_MODEL} ${C_GRAY}(${CPU_CORES} cores)${C_RESET}"
echo -e "${C_WHITE}  💾 ${C_GREEN}${RAM_USED}MB${C_WHITE}/${C_CYAN}${RAM_TOTAL}MB ${C_YELLOW}${RAM_PERCENT}% ${C_GRAY}• ${C_WHITE}💿 ${C_GREEN}${DISK_USED}${C_WHITE}/${C_CYAN}${DISK_TOTAL} ${C_YELLOW}${DISK_PERCENT}${C_RESET}"
echo -e "${C_WHITE}  ⏱️  ${C_CYAN}${UPTIME}${C_RESET}"
echo -e "${C_BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
echo -e "${C_MAGENTA}▸ Bot Frameworks${C_RESET}"
print_lang "discord.js" "npm list -g discord.js 2>/dev/null | grep discord.js | awk '{print \$2}' | sed 's/@//'"
print_lang "Telegraf" "npm list -g telegraf 2>/dev/null | grep telegraf | awk '{print \$2}' | sed 's/@//'"
print_lang "py-telegram" "pip3 show python-telegram-bot 2>/dev/null | grep Version | awk '{print \$2}'"

echo ""
echo -e "${C_MAGENTA}▸ Database & ORM${C_RESET}"
print_lang "Prisma" "prisma --version 2>/dev/null | head -n1 | awk '{print \$3}'"
print_lang "TypeORM" "typeorm --version 2>/dev/null"
print_lang "Sequelize" "sequelize --version 2>/dev/null"
print_lang "SQLAlchemy" "pip3 show sqlalchemy 2>/dev/null | grep Version | awk '{print \$2}'"
print_lang "Mongoose" "npm list -g mongoose 2>/dev/null | grep mongoose | awk '{print \$2}' | sed 's/@//'"

echo ""
echo -e "${C_MAGENTA}▸ Deployment & Cloud${C_RESET}"
print_lang "Vercel" "vercel --version 2>/dev/null"
print_lang "Netlify" "netlify --version 2>/dev/null"
print_lang "Firebase" "firebase --version 2>/dev/null"
print_lang "Serverless" "serverless --version 2>/dev/null"
print_lang "Railway" "railway --version 2>/dev/null"

echo ""
echo -e "${C_MAGENTA}▸ Mobile Development${C_RESET}"
print_lang "React Native" "react-native --version 2>/dev/null | head -n1"
print_lang "Expo" "expo --version 2>/dev/null"
print_lang "Ionic" "ionic --version 2>/dev/null"
print_lang "Cordova" "cordova --version 2>/dev/null"
print_lang "Electron" "electron --version 2>/dev/null"

echo ""
echo -e "${C_MAGENTA}▸ Monitoring & Analytics${C_RESET}"
print_lang "htop" "htop --version 2>/dev/null | head -n1 | awk '{print \$2}'"
print_lang "nload" "nload --version 2>/dev/null | head -n1 | awk '{print \$2}'"
print_lang "ncdu" "ncdu --version 2>/dev/null | head -n1 | awk '{print \$2}'"

echo ""
echo -e "${C_MAGENTA}▸ Frontend Frameworks${C_RESET}"
print_lang "React" "npm list -g create-react-app 2>/dev/null | grep create-react-app | awk '{print \$2}' | sed 's/@//'"
print_lang "Vue CLI" "vue --version 2>/dev/null"
print_lang "Angular" "ng version 2>/dev/null | head -n1 | awk '{print \$3}'"
print_lang "Next.js" "npm list -g create-next-app 2>/dev/null | grep create-next-app | awk '{print \$2}' | sed 's/@//'"

echo ""
echo -e "${C_MAGENTA}▸ Backend Frameworks${C_RESET}"
print_lang "NestJS" "nest --version 2>/dev/null"
print_lang "FastAPI" "pip3 show fastapi 2>/dev/null | grep Version | awk '{print \$2}'"
print_lang "Django" "pip3 show django 2>/dev/null | grep Version | awk '{print \$2}'"
print_lang "Flask" "pip3 show flask 2>/dev/null | grep Version | awk '{print \$2}'"

echo ""

print_lang() {
    local name=$1
    local cmd=$2
    local version=$(eval "$cmd" 2>/dev/null || echo '')
    if [[ -z "$version" ]]; then
        printf "  ${C_GRAY}%-12s Not Installed${C_RESET}\n" "$name"
    else
        printf "  ${C_GREEN}%-12s${C_RESET} ${C_CYAN}%s${C_RESET}\n" "$name" "$version"
    fi
}

echo -e "${C_MAGENTA}▸ Programming Languages${C_RESET}"
print_lang "Node.js" "node -v"
print_lang "Bun" "bun -v | sed 's/^/v/'"
print_lang "Deno" "deno --version | head -n1 | awk '{print \$2}'"
print_lang "Python" "python3 --version | awk '{print \$2}'"
print_lang "Go" "go version | awk '{print \$3}' | sed 's/go//'"
print_lang "Zig" "zig version"
print_lang "Ruby" "ruby -v | awk '{print \$2}'"
print_lang "PHP" "php -v | head -n1 | awk '{print \$2}'"
print_lang "Java" "java -version 2>&1 | head -n1 | awk -F '\"' '{print \$2}'"

echo ""
echo -e "${C_MAGENTA}▸ Package Managers & Build Tools${C_RESET}"
print_lang "npm" "npm -v"
print_lang "pnpm" "pnpm -v"
print_lang "yarn" "yarn -v"
print_lang "pip" "pip3 --version | awk '{print \$2}'"
print_lang "composer" "composer --version 2>/dev/null | awk '{print \$3}'"
print_lang "bundler" "bundler -v"
print_lang "maven" "mvn -v 2>/dev/null | head -n1 | awk '{print \$3}'"

echo ""
echo -e "${C_MAGENTA}▸ Development Tools${C_RESET}"
print_lang "PM2" "pm2 -v"
print_lang "Nodemon" "nodemon -v"
print_lang "TypeScript" "tsc -v"
print_lang "ESLint" "eslint -v"
print_lang "Playwright" "playwright --version | head -n1"
print_lang "Puppeteer" "puppeteer --version 2>/dev/null || echo 'installed'"

echo ""
echo -e "${C_MAGENTA}▸ Media & Download Tools${C_RESET}"
print_lang "FFmpeg" "ffmpeg -version | head -n1 | awk '{print \$3}'"
print_lang "ImageMagick" "convert -version | head -n1 | awk '{print \$3}'"
print_lang "yt-dlp" "yt-dlp --version"
print_lang "aria2" "aria2c --version | head -n1 | awk '{print \$3}'"

echo ""
echo -e "${C_MAGENTA}▸ Active Services${C_RESET}"

SERVICES_COUNT=0

if pgrep redis-server > /dev/null; then
    echo -e "  ${C_GREEN}✓ Redis Server${C_RESET}     ${C_CYAN}127.0.0.1:6379${C_RESET}"
    ((SERVICES_COUNT++))
fi

if pgrep mysqld > /dev/null; then
    echo -e "  ${C_GREEN}✓ MariaDB Server${C_RESET}   ${C_CYAN}127.0.0.1:3306${C_RESET}"
    ((SERVICES_COUNT++))
fi

if pgrep cloudflared > /dev/null; then
    echo -e "  ${C_GREEN}✓ CF Tunnel${C_RESET}        ${C_CYAN}Active${C_RESET}"
    ((SERVICES_COUNT++))
fi

if [ ! -z "${HTTP_PROXY}" ]; then
    PROXY_HOST=$(echo $HTTP_PROXY | awk -F[/:] '{print $4}')
    echo -e "  ${C_GREEN}✓ HTTP Proxy${C_RESET}       ${C_CYAN}${PROXY_HOST}${C_RESET}"
    ((SERVICES_COUNT++))
fi

if [ $SERVICES_COUNT -eq 0 ]; then
    echo -e "  ${C_GRAY}No services running${C_RESET}"
fi

echo ""
echo -e "${C_BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
echo -e "${C_GRAY}  📞 t.me/verlangid11  •  🤖 tiktok.com/@verlangid${C_RESET}"
echo -e "${C_BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
echo ""

exec /bin/bash
