FROM vauxoo/odoo-140-image

ENV PYENV_ROOT=/usr/share/pyenv \
    PYENV_VERSION=3.7.10 \
    PATH=/usr/share/pyenv/shims:/usr/bin:$PATH
RUN git clone https://github.com/pyenv/pyenv.git /usr/share/pyenv && \
    cd /usr/share/pyenv && src/configure && make -C src && \
    ln -sf /usr/share/pyenv/bin/pyenv /usr/bin/pyenv && \
    apt update && \
    apt install --no-install-recommends -y lsb-release && \
    echo "deb http://packages.cloud.google.com/apt gcsfuse-$(lsb_release -cs) main" \
        | tee /etc/apt/sources.list.d/gcsfuse.list \
    && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - \
    && apt-get -qq update \
    && apt-get install -y --no-install-recommends \
        gcsfuse \
        gnupg \
        zlibc \
        xz-utils \
        apt-utils \
        dialog \
        apt-transport-https \
        build-essential \
        libfreetype6-dev \
        libfribidi-dev \
        libghc-zlib-dev \
        libharfbuzz-dev \
        libjpeg-dev \
        libgeoip-dev \
        libmaxminddb-dev \
        liblcms2-dev \
        libldap2-dev \
        libopenjp2-7-dev \
        libpq-dev \
        libsasl2-dev \
        libtiff5-dev \
        libwebp-dev \
        procps \
        tcl-dev \
        tk-dev \
        zlib1g-dev \
    && eval "$(pyenv init -)" && \
    pyenv install $PYENV_VERSION && \
    pyenv shell $PYENV_VERSION && \
    pyenv rehash && \
    echo "export PYENV_ROOT=$PYENV_ROOT\nexport PATH=\$PYENV_ROOT/shims:\$PYENV_ROOT/bin:\$PATH" | tee -a /etc/bash.bashrc && \
    wget -O /tmp/req11.txt https://raw.githubusercontent.com/odoo/odoo/11.0/requirements.txt && \
    pip --no-cache-dir install -U pip && \
    pip --no-cache-dir install -Ur /tmp/req11.txt && \
    pip --no-cache-dir install \
        astor \
        psycogreen \
        python-magic \
        phonenumbers \
        num2words \
        qrcode \
        vobject \
        xlrd \
        python-stdnum \
        click-odoo-contrib \
        firebase-admin \
        git-aggregator \
        inotify \
        python-json-logger \
        redis \
        wdb \
        Werkzeug==0.16.1 \
        gevent==1.5.0 \
        greenlet==0.4.14 \
        coverage \
    && npm install -g rtlcss \
    && apt-get autoremove \
    && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
    && rm -rf /var/lib/apt/lists/* /tmp/* \
    && find /var/tmp -type f -print0 | xargs -0r rm -rf \
    && find /var/log -type f -print0 | xargs -0r rm -rf \
    && find /var/lib/apt/lists -type f -print0 | xargs -0r rm -rf
