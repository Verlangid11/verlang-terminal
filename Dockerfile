FROM debian:bullseye-slim

LABEL author="verlangid" maintainer="verlangid@gmail.com" \
      version="3.0.0-stable"

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
    ZIG_VERSION=0.11.0

ENV PATH="$NODE_INSTALL_DIR/bin:$BUN_INSTALL/bin:$DENO_INSTALL/bin:/usr/local/go/bin:/usr/local/zig:$HOME/.cargo/bin:$HOME/go/bin:$PATH"

RUN apt-get update && apt-get install -y --no-install-recommends \
        curl wget git ca-certificates gnupg lsb-release \
    && mkdir -p --mode=0755 /usr/share/keyrings \
    && curl -fsSL https://pkg.cloudflare.com/cloudflare-public-v2.gpg | gpg --dearmor > /usr/share/keyrings/cloudflare-public-v2.gpg \
    && echo 'deb [signed-by=/usr/share/keyrings/cloudflare-public-v2.gpg] https://pkg.cloudflare.com/cloudflared any main' | tee /etc/apt/sources.list.d/cloudflared.list \
    && apt-get update && apt-get install -y cloudflared \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y --no-install-recommends \
        zip unzip tar gzip bzip2 p7zip-full zstd rar unrar xz-utils \
        jq yq nano vim sudo \
        net-tools iputils-ping dnsutils whois traceroute \
        procps htop iotop iftop nethogs nload \
        screen tmux byobu zsh fish \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential make gcc g++ cmake \
        autoconf automake libtool pkg-config \
        libssl-dev zlib1g-dev libbz2-dev libreadline-dev \
        libsqlite3-dev libncursesw5-dev tk-dev libffi-dev \
        liblzma-dev libxml2-dev libxslt1-dev \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y --no-install-recommends \
        ffmpeg imagemagick graphicsmagick webp libwebp-dev \
        libavcodec-extra mediainfo exiftool \
        gifsicle optipng jpegoptim pngquant libjpeg-turbo-progs \
        sox lame flac vorbis-tools opus-tools \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y --no-install-recommends \
        redis-server mariadb-server mariadb-client sqlite3 \
        postgresql-client mongodb-clients \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y --no-install-recommends \
        chromium chromium-driver \
        fonts-liberation fonts-noto-color-emoji \
        libasound2 libgbm1 libgtk-3-0 libnss3 libnspr4 \
        libatk1.0-0 libatk-bridge2.0-0 libcups2 libdrm2 \
        libdbus-1-3 libexpat1 libx11-xcb1 libxcb-dri3-0 \
        libxss1 libxtst6 libxrandr2 libxcomposite1 \
        libxcursor1 libxdamage1 libxi6 libpangocairo-1.0-0 \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y --no-install-recommends \
        speedtest-cli python3-pip aria2 rsync rclone \
        nginx apache2-utils \
    && rm -rf /var/lib/apt/lists/*

RUN cd /tmp \
    && wget -q https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz \
    && tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz \
    && rm go${GO_VERSION}.linux-amd64.tar.gz

RUN cd /tmp \
    && wget -q https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz \
    && tar xzf Python-${PYTHON_VERSION}.tgz \
    && cd Python-${PYTHON_VERSION} \
    && ./configure --enable-optimizations --with-ensurepip=install \
    && make -j$(nproc) altinstall \
    && ln -sf /usr/local/bin/python3.13 /usr/local/bin/python3 \
    && ln -sf /usr/local/bin/pip3.13 /usr/local/bin/pip3 \
    && cd /tmp && rm -rf Python-${PYTHON_VERSION}*

RUN pip3 install --no-cache-dir --upgrade pip setuptools wheel

RUN pip3 install --no-cache-dir \
        yt-dlp you-get streamlink gallery-dl instaloader

RUN pip3 install --no-cache-dir \
        requests beautifulsoup4 lxml selenium playwright

RUN pip3 install --no-cache-dir \
        pillow opencv-python-headless numpy pandas

RUN pip3 install --no-cache-dir \
        flask fastapi uvicorn gunicorn django

RUN pip3 install --no-cache-dir \
        scrapy aiohttp httpx websockets

RUN pip3 install --no-cache-dir \
        celery redis python-telegram-bot discord.py

RUN pip3 install --no-cache-dir \
        pytest black isort flake8 mypy

RUN pip3 install --no-cache-dir \
        sqlalchemy pymongo psycopg2-binary

RUN pip3 install --no-cache-dir \
        pydantic python-dotenv click rich

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
    && gem install bundler rails \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        php php-cli php-common php-curl php-mbstring \
        php-xml php-zip php-gd php-mysql php-sqlite3 \
    && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update \
    && apt-get install -y --no-install-recommends default-jdk maven \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p $PLAYWRIGHT_BROWSERS_PATH

RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs

RUN npm install -g npm@latest

RUN npm install -g pm2 nodemon pnpm yarn

RUN npm install -g typescript ts-node @types/node

RUN npm install -g playwright puppeteer

RUN npm install -g @nestjs/cli create-react-app @vue/cli @angular/cli

RUN npm install -g eslint prettier jest

RUN npm install -g http-server serve

RUN npm install -g serverless vercel netlify-cli firebase-tools

RUN npm install -g prisma typeorm sequelize-cli

RUN npm install -g discord.js telegraf

RUN npm install -g sharp jimp

RUN npm install -g dotenv-cli cross-env

RUN PLAYWRIGHT_BROWSERS_PATH=$PLAYWRIGHT_BROWSERS_PATH npx playwright install --with-deps chromium

RUN apt-get purge -y nodejs \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*

RUN chmod -R 777 $PLAYWRIGHT_BROWSERS_PATH

RUN mkdir -p /var/run/mysqld && chown -R mysql:mysql /var/run/mysqld \
    && mkdir -p /var/lib/mysql && chown -R mysql:mysql /var/lib/mysql

RUN useradd -m -d /home/container -s /bin/bash container

RUN mkdir -p $NODE_INSTALL_DIR && chown -R container:container $NODE_INSTALL_DIR

USER container
WORKDIR /home/container

COPY ./entrypoint.sh /entrypoint.sh
CMD [ "/bin/bash", "/entrypoint.sh" ]
