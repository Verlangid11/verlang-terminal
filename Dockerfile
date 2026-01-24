FROM debian:bullseye-slim

LABEL author="verlangid" maintainer="verlangid@gmail.com" \
      description="Ultimate Multi-Runtime Terminal for Pterodactyl" \
      version="2.0.0"

ENV DEBIAN_FRONTEND=noninteractive \
    USER=container \
    HOME=/home/container \
    NODE_INSTALL_DIR=/home/container/node \
    BUN_INSTALL=/usr/local/bun \
    DENO_INSTALL=/usr/local \
    PLAYWRIGHT_BROWSERS_PATH=/usr/local/share/playwright \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium \
    PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true \
    GO_VERSION=1.24.0 \
    PYTHON_VERSION=3.13.0 \
    ZIG_VERSION=0.11.0 \
    DOTNET_VERSION=8.0

ENV PATH="$NODE_INSTALL_DIR/bin:$BUN_INSTALL/bin:$DENO_INSTALL/bin:/usr/local/go/bin:/usr/local/zig:$HOME/.cargo/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

RUN apt-get update && apt-get install -y --no-install-recommends \
        curl wget git zip unzip tar gzip bzip2 p7zip-full zstd rar unrar \
        jq yq nano vim emacs sudo ca-certificates gnupg lsb-release apt-transport-https \
        net-tools iputils-ping dnsutils whois traceroute mtr-tiny nmap \
        procps htop iotop iftop nethogs nload bmon vnstat ncdu \
        build-essential make gcc g++ cmake autoconf automake libtool pkg-config \
        libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev \
        libncursesw5-dev xz-utils tk-dev libffi-dev liblzma-dev libxml2-dev libxslt1-dev \
        ffmpeg imagemagick graphicsmagick webp libwebp-dev libavcodec-extra \
        mediainfo exiftool gifsicle optipng jpegoptim pngquant libjpeg-turbo-progs \
        sox lame flac vorbis-tools opus-tools \
        redis-server mariadb-server mariadb-client sqlite3 postgresql-client \
        chromium chromium-driver fonts-liberation fonts-noto-color-emoji \
        speedtest-cli python3-pip aria2 rsync rclone syncthing \
        screen tmux byobu zsh fish \
        nginx apache2-utils \
        mongodb-clients \
    && mkdir -p --mode=0755 /usr/share/keyrings \
    && curl -fsSL https://pkg.cloudflare.com/cloudflare-public-v2.gpg | gpg --dearmor > /usr/share/keyrings/cloudflare-public-v2.gpg \
    && echo 'deb [signed-by=/usr/share/keyrings/cloudflare-public-v2.gpg] https://pkg.cloudflare.com/cloudflared any main' | tee /etc/apt/sources.list.d/cloudflared.list \
    && apt-get update && apt-get install -y cloudflared

RUN apt-get install -y --no-install-recommends \
        libasound2 libgbm1 libgtk-3-0 libnss3 libnspr4 libatk1.0-0 libatk-bridge2.0-0 \
        libcups2 libdrm2 libdbus-1-3 libexpat1 libx11-xcb1 libxcb-dri3-0 libxss1 libxtst6 \
        libxrandr2 libxcomposite1 libxcursor1 libxdamage1 libxi6 libpangocairo-1.0-0 \
    && rm -rf /var/lib/apt/lists/*

RUN cd /tmp \
    && wget -q https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz \
    && tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz \
    && rm go${GO_VERSION}.linux-amd64.tar.gz \
    && go install github.com/cosmtrek/air@latest

RUN cd /tmp \
    && wget -q https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz \
    && tar xzf Python-${PYTHON_VERSION}.tgz \
    && cd Python-${PYTHON_VERSION} \
    && ./configure --enable-optimizations --with-ensurepip=install \
    && make -j$(nproc) altinstall \
    && ln -sf /usr/local/bin/python3.13 /usr/local/bin/python3 \
    && ln -sf /usr/local/bin/pip3.13 /usr/local/bin/pip3 \
    && pip3 install --upgrade pip setuptools wheel \
    && pip3 install yt-dlp you-get streamlink gallery-dl instaloader tiktok-downloader \
    && pip3 install requests beautifulsoup4 lxml selenium playwright pyppeteer \
    && pip3 install pillow opencv-python-headless numpy pandas matplotlib seaborn \
    && pip3 install flask fastapi uvicorn gunicorn django tornado sanic \
    && pip3 install scrapy aiohttp httpx websockets \
    && pip3 install celery redis python-telegram-bot discord.py pyrogram telethon \
    && pip3 install pytest black isort flake8 mypy pylint autopep8 \
    && pip3 install sqlalchemy psycopg2-binary pymongo motor aiomysql \
    && pip3 install pydantic python-dotenv python-multipart \
    && pip3 install click typer rich colorama termcolor \
    && pip3 install schedule apscheduler \
    && cd /tmp && rm -rf Python-${PYTHON_VERSION}*

RUN cd /tmp \
    && wget -q https://github.com/oven-sh/bun/releases/latest/download/bun-linux-x64.zip \
    && unzip -q bun-linux-x64.zip \
    && mkdir -p $BUN_INSTALL/bin \
    && mv bun-linux-x64/bun $BUN_INSTALL/bin/bun \
    && chmod +x $BUN_INSTALL/bin/bun \
    && rm -rf bun-linux-x64*

RUN curl -fsSL https://deno.land/x/install/install.sh | DENO_INSTALL=/usr/local sh \
    && chmod +x /usr/local/bin/deno

RUN cd /tmp \
    && wget -q https://ziglang.org/download/${ZIG_VERSION}/zig-linux-x86_64-${ZIG_VERSION}.tar.xz \
    && tar -xf zig-linux-x86_64-${ZIG_VERSION}.tar.xz \
    && mv zig-linux-x86_64-${ZIG_VERSION} /usr/local/zig \
    && ln -s /usr/local/zig/zig /usr/local/bin/zig \
    && rm zig-linux-x86_64-${ZIG_VERSION}.tar.xz

RUN apt-get update \
    && apt-get install -y --no-install-recommends ruby ruby-dev \
    && gem install bundler rails sinatra rake \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        php php-cli php-fpm php-common php-curl php-mbstring php-xml php-zip \
        php-gd php-mysql php-pgsql php-sqlite3 php-redis php-imagick \
        php-intl php-bcmath php-json \
    && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update \
    && apt-get install -y --no-install-recommends default-jdk maven gradle \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p $PLAYWRIGHT_BROWSERS_PATH \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g npm@latest \
    && npm install -g pm2 nodemon pnpm yarn forever \
    && npm install -g typescript ts-node @types/node tsx swc \
    && npm install -g playwright puppeteer puppeteer-core selenium-webdriver \
    && npm install -g @nestjs/cli @angular/cli create-react-app vite \
    && npm install -g eslint prettier jest mocha chai ava tap \
    && npm install -g http-server serve live-server browser-sync \
    && npm install -g dotenv-cli cross-env concurrently wait-on \
    && npm install -g express-generator koa-generator \
    && npm install -g webpack webpack-cli parcel-bundler rollup esbuild \
    && npm install -g @vue/cli nuxt create-next-app create-t3-app \
    && npm install -g serverless netlify-cli vercel wrangler \
    && npm install -g firebase-tools heroku supabase railway \
    && npm install -g prisma typeorm sequelize-cli mongoose knex \
    && npm install -g nodemailer axios node-fetch cheerio jsdom \
    && npm install -g discord.js telegraf whatsapp-web.js baileys \
    && npm install -g sharp jimp gm qrcode-terminal qrcode \
    && npm install -g socket.io ws mqtt socket.io-client \
    && npm install -g chalk ora inquirer commander yargs \
    && npm install -g rimraf mkdirp fs-extra glob \
    && npm install -g node-gyp node-pre-gyp prebuild-install \
    && npm install -g standard xo \
    && npm install -g localtunnel ngrok-cli \
    && npm install -g npm-check-updates depcheck \
    && npm install -g expo-cli react-native-cli ionic cordova \
    && npm install -g electron electron-builder \
    && npx playwright install --with-deps chromium \
    && apt-get purge -y nodejs \
    && apt-get autoremove -y \
    && chmod -R 777 $PLAYWRIGHT_BROWSERS_PATH \
    && mkdir -p /var/run/mysqld && chown -R mysql:mysql /var/run/mysqld \
    && mkdir -p /var/lib/mysql && chown -R mysql:mysql /var/lib/mysql

RUN useradd -m -d /home/container -s /bin/bash container

RUN mkdir -p $NODE_INSTALL_DIR && chown -R container:container $NODE_INSTALL_DIR

USER container
WORKDIR /home/container

COPY ./entrypoint.sh /entrypoint.sh
CMD [ "/bin/bash", "/entrypoint.sh" ]
