#!/usr/bin/env bash

# Exit inmediately after an error
# See vauxoo/docker-odoo-image#108
set -e

# With a little help from my friends
. /usr/share/vx-docker-internal/ubuntu-base/library.sh
. /usr/share/vx-docker-internal/odoo100/library.sh
. /etc/lsb-release
# Let's set some defaults here
ARCH="$( dpkg --print-architecture )"
NODE_UPSTREAM_REPO="deb http://deb.nodesource.com/node_5.x trusty main"
NODE_UPSTREAM_KEY="https://deb.nodesource.com/gpgkey/nodesource.gpg.key"
WKHTMLTOX_URL="https://downloads.wkhtmltopdf.org/0.12/0.12.4/wkhtmltox-0.12.4_linux-generic-${ARCH}.tar.xz"
ODOO_DEPENDENCIES="git+https://github.com/vauxoo/odoo@10.0 \
                   git+https://github.com/vauxoo/server-tools@10.0 \
                   git+https://github.com/vauxoo/addons-vauxoo@10.0 \
                   git+https://github.com/vauxoo/pylint-odoo@master"
DEPENDENCIES_FILE="/usr/share/vx-docker-internal/odoo100/10.0-full_requirements.txt"
GEOIP2_URLS="https://s3.vauxoo.com/GeoLite2-City_20191224.tar.gz \
             https://s3.vauxoo.com/GeoLite2-Country_20191224.tar.gz \
             https://s3.vauxoo.com/GeoLite2-ASN_20191224.tar.gz"
EGENIX_BASE_URL="https://files.pythonhosted.org/packages/66/e6/e0709aedeb4a5c92a1aeb8c47ab50e9506eafc865806801bd3f01d72b671/egenix-mx-base-3.2.9.zip"
DPKG_DEPENDS="nodejs \
              phantomjs \
              antiword \
              python-dev \
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
              fontconfig \
              ghostscript \
              cloc"
DPKG_UNNECESSARY=""
NPM_OPTS="-g"
NPM_DEPENDS="less \
             less-plugin-clean-css \
             jshint"
PIP_OPTS="--upgrade \
          --no-cache-dir"

PIP_DEPENDS_EXTRA="requirements-parser==0.1.0 \
                   setuptools==33.1.1 \
                   git+https://github.com/vauxoo/pylint-odoo@master#egg=pylint-odoo \
                   git+https://github.com/vauxoo/panama-dv@master#egg=ruc \
                   hg+https://bitbucket.org/birkenfeld/sphinx-contrib@default#egg=sphinxcontrib-youtube&subdirectory=youtube"

PIP_DPKG_BUILD_DEPENDS=""

# Let's add the NodeJS upstream repo to install a newer version
add_custom_aptsource "${NODE_UPSTREAM_REPO}" "${NODE_UPSTREAM_KEY}"

# Release the apt monster!
apt-get update
apt-get upgrade
apt-get install ${DPKG_DEPENDS} ${PIP_DPKG_BUILD_DEPENDS}

# Install node dependencies
npm install ${NPM_OPTS} ${NPM_DEPENDS}

# Let's recursively find our pip dependencies
collect_pip_dependencies "${ODOO_DEPENDENCIES}" "${PIP_DEPENDS_EXTRA}" "${DEPENDENCIES_FILE}"

# Cleans incorrect dependency lines  
clean_requirements ${DEPENDENCIES_FILE}

# Install python dependencies
pip install ${PIP_OPTS} -r ${DEPENDENCIES_FILE} --no-use-pep517

python --version

# Install qt patched version of wkhtmltopdf because of maintainer nonsense
wkhtmltox_install "${WKHTMLTOX_URL}"

# Install GeoIP database
geoip_install "${GEOIP2_URLS}"

egenixbase_install "${EGENIX_BASE_URL}"

# Remove build depends for pip
apt-get purge ${PIP_DPKG_BUILD_DEPENDS} ${DPKG_UNNECESSARY}
apt-get autoremove

# Final cleaning
rm -rf /tmp/*
find /var/tmp -type f -print0 | xargs -0r rm -rf
find /var/log -type f -print0 | xargs -0r rm -rf
find /var/lib/apt/lists -type f -print0 | xargs -0r rm -rf
