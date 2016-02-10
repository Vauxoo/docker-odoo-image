FROM vauxoo/docker-ubuntu-base

MAINTAINER Tulio Ruiz <tulio@vauxoo.com>

RUN wget -qO- https://deb.nodesource.com/setup | sudo bash - \
    && apt-get upgrade -q \
    && apt-get install --allow-unauthenticated -q \
    antiword \
    bash-completion \
    libfreetype6-dev \
    libgeoip-dev \
    libjpeg-dev \
    libldap2-dev \
    libqrencode-dev \
    libxml2-dev \
    libxslt1-dev  \
    libyaml-dev \
    M2Crypto \
    nodejs \
    phantomjs \
    poppler-utils \
    python-imaging \
    python-libxml2 \
    python-lxml \
    python-pandas \
    python-qrcode \
    python-suds \
    ttf-dejavu \
    xmlstarlet \
    xsltproc \
    zlib1g-dev \
    && npm install -g less \
    && npm install -g less-plugin-clean-css
RUN ln -s /usr/include/freetype2 /usr/local/include/freetype \
    && ln -s /usr/lib/x86_64-linux-gnu/libjpeg.so /usr/lib/ \
    && ln -s /usr/lib/x86_64-linux-gnu/libfreetype.so /usr/lib/ \
    && ln -s /usr/lib/x86_64-linux-gnu/libz.so /usr/lib/
RUN pip install --upgrade pyyaml pillow GeoIP SOAPpy pyopenssl suds xmltodict recaptcha-client egenix-mx-base git+https://github.com/Vauxoo/panama-dv.git \
    && cd /tmp && git clone --depth=1 https://github.com/thewtex/sphinx-contrib.git \
    && cd sphinx-contrib/youtube && python setup.py install \
    && wget -q https://raw.githubusercontent.com/ruiztulio/gist-vauxoo/master/travis_run.py \
    && python travis_run.py \
    && wget -q https://raw.githubusercontent.com/Vauxoo/odoo-network/8.0/addons/network/scripts/odoo-server/05-install-dependencies-python-v80.sh \
    && sh 05-install-dependencies-python-v80.sh \
    && wget -q https://raw.githubusercontent.com/vauxoo/odoo/8.0/requirements.txt \
    && pip install -r requirements.txt \
    && wget -q http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz \
    && gunzip GeoLiteCity.dat.gz && mkdir -p /usr/share/GeoIP && mv GeoLiteCity.dat /usr/share/GeoIP/GeoLiteCity.dat \
    && wget -O wkhtmltox-0.12.1_linux-trusty-amd64.deb http://download.gna.org/wkhtmltopdf/0.12/0.12.1/wkhtmltox-0.12.1_linux-trusty-amd64.deb \
    && dpkg -i wkhtmltox-0.12.1_linux-trusty-amd64.deb \
    && apt-get clean && rm -rf /var/lib/apt/lists/* && rm -rf /tmp/*
