FROM vauxoo/docker-ubuntu-base
MAINTAINER Tulio Ruiz <tulio@vauxoo.com>
RUN apt-key adv --keyserver pgp.mit.edu --recv-keys B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8
RUN echo 'deb http://apt.postgresql.org/pub/repos/apt/ trusty-pgdg main' > /etc/apt/sources.list.d/pgdg.list
RUN apt-get update -q && apt-get upgrade -q \
    && apt-get install --allow-unauthenticated -q libssl-dev \
    libyaml-dev \
    libjpeg-dev \
    libgeoip-dev \
    libffi-dev \
    libqrencode-dev \
    libfreetype6-dev \
    zlib1g-dev \
    python-suds \
    python-imaging \
    python-qrcode \
    M2Crypto \
    python-lxml \
    ttf-dejavu \
    antiword \
    python-pandas \
    poppler-utils \
    postgresql-client-9.3 \
    postgresql-common \
    libpq-dev \
    libldap2-dev \
    libsasl2-dev \
    libxml2-dev \
    libxslt1-dev  \
    xsltproc \
    xmlstarlet \
    openssl \
    python-libxml2 \
    phantomjs
RUN ln -s /usr/include/freetype2 /usr/local/include/freetype \
    && ln -s /usr/lib/x86_64-linux-gnu/libjpeg.so /usr/lib/ \
    && ln -s /usr/lib/x86_64-linux-gnu/libfreetype.so /usr/lib/ \
    && ln -s /usr/lib/x86_64-linux-gnu/libz.so /usr/lib/
RUN pip install pillow GeoIP SOAPpy pyopenssl suds xmltodict recaptcha-client egenix-mx-base 
RUN cd /tmp && wget -q https://raw.githubusercontent.com/odoo/odoo/8.0/requirements.txt \
    && pip install -r requirements.txt
RUN cd /tmp && git clone --depth=1 https://github.com/thewtex/sphinx-contrib.git \
    && cd sphinx-contrib/youtube && python setup.py install
RUN pip install pyyaml && cd /tmp \
    && wget -q https://raw.githubusercontent.com/ruiztulio/gist-vauxoo/master/travis_run.py \
    && python travis_run.py
RUN cd /tmp \
    && wget -q https://raw.githubusercontent.com/Vauxoo/odoo-network/8.0/addons/network/scripts/odoo-server/05-install-dependencies-python-v80.sh \
    && sh 05-install-dependencies-python-v80.sh
RUN wget -q http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz \
    && gunzip GeoLiteCity.dat.gz && mkdir -p /usr/share/GeoIP && mv GeoLiteCity.dat /usr/share/GeoIP/GeoLiteCity.dat
RUN apt-get clean && rm -rf /var/lib/apt/lists/* && rm -rf /tmp/*
