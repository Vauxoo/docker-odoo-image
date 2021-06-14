#!/usr/bin/env bash

# Exit inmediately after an error
# See vauxoo/docker-odoo-image#108
set -e

# With a little help from my friends
. /usr/share/vx-docker-internal/ubuntu-base/library.sh
. /usr/share/vx-docker-internal/odoo150/library.sh
. /etc/lsb-release
# Let's set some defaults here
ARCH="$( dpkg --print-architecture )"
NODE_UPSTREAM_REPO="deb http://deb.nodesource.com/node_8.x trusty main"
NODE_UPSTREAM_KEY="https://deb.nodesource.com/gpgkey/nodesource.gpg.key"
WKHTMLTOX_URL="https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1.${DISTRIB_CODENAME}_${ARCH}.deb"
PHANTOMJS_VERSION="2.1.1"
GEOIP2_URLS="https://s3.vauxoo.com/GeoLite2-City_20191224.tar.gz \
             https://s3.vauxoo.com/GeoLite2-Country_20191224.tar.gz \
             https://s3.vauxoo.com/GeoLite2-ASN_20191224.tar.gz"
DPKG_DEPENDS="nodejs \
              antiword \
              python3-dev \
              poppler-utils \
              xmlstarlet \
              xsltproc \
              xz-utils \
              swig \
              libpq-dev \
              libldap2-dev \
              libsasl2-dev \
              libssl-dev \
              build-essential \
              gfortran \
              libfreetype6-dev \
              zlib1g-dev \
              libjpeg-dev \
              libblas-dev \
              liblapack-dev \
              libxml2-dev \
              libxslt1-dev \
              libgeoip-dev \
              cython \
              fontconfig \
              ghostscript \
              cloc \
              ruby-dev \
              compass-blueprint-plugin \
              autoconf \
              automake \
              libtool \
              libltdl-dev \
              libcups2-dev \
              xfonts-75dpi \
              xfonts-base \
              npm"
DPKG_UNNECESSARY=""
NPM_OPTS="-g"
NPM_DEPENDS="less \
             less-plugin-clean-css \
             jshint"
PIP_OPTS="--upgrade \
          --no-cache-dir"

PIP_DEPENDS_EXTRA="requirements-parser \
                   git+https://github.com/vauxoo/pylint-odoo@master#egg=pylint-odoo \
                   git+https://github.com/vauxoo/panama-dv@master#egg=ruc"

PIP_DPKG_BUILD_DEPENDS=""

RUBY_DEPENDS="compass \
              bootstrap-sass"

# Let's add the NodeJS upstream repo to install a newer version
add_custom_aptsource "${NODE_UPSTREAM_REPO}" "${NODE_UPSTREAM_KEY}"

# Release the apt monster!
apt-get update
apt-get upgrade
apt-get install ${DPKG_DEPENDS} ${PIP_DPKG_BUILD_DEPENDS}

# Install node dependencies
npm install ${NPM_OPTS} ${NPM_DEPENDS}

pip3 install ${PIP_OPTS} reqgen
# Let's recursively find our pip dependencies
pip3 install ${PIP_OPTS} ${PIP_DEPENDS_EXTRA}

# Cleans incorrect dependency lines
#clean_requirements ${DEPENDENCIES_FILE}

# Install qt patched version of wkhtmltopdf because of maintainer nonsense
wkhtmltox_install "${WKHTMLTOX_URL}"

# Install GeoIP database
geoip_install "${GEOIP2_URLS}"

phantomjs_install "https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-${PHANTOMJS_VERSION}-linux-x86_64.tar.bz2"

# Force install rake before dependencies
gem install rake

# Install ruby dependencies
gem install ${RUBY_DEPENDS}

# Install mc (MinioClient)
wget https://dl.min.io/client/mc/release/linux-amd64/mc
chmod +x ./mc
mv ./mc /usr/bin

# Remove build depends for pip
apt-get purge ${PIP_DPKG_BUILD_DEPENDS} ${DPKG_UNNECESSARY}
apt-get autoremove

# Final cleaning
rm -rf /tmp/*
find /var/tmp -type f -print0 | xargs -0r rm -rf
find /var/log -type f -print0 | xargs -0r rm -rf
find /var/lib/apt/lists -type f -print0 | xargs -0r rm -rf
