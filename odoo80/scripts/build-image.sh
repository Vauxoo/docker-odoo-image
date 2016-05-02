#!/usr/bin/env bash

# With a little help from my friends
. /usr/share/vx-docker-internal/ubuntu-base/library.sh
. /usr/share/vx-docker-internal/odoo80/library.sh

# Let's set some defaults here
ARCH="$( dpkg --print-architecture )"
NODE_UPSTREAM_REPO="deb http://deb.nodesource.com/node_5.x trusty main"
NODE_UPSTREAM_KEY="https://deb.nodesource.com/gpgkey/nodesource.gpg.key"
WKHTMLTOX_URL="http://download.gna.org/wkhtmltopdf/0.12/0.12.3/wkhtmltox-0.12.3_linux-generic-${ARCH}.tar.xz"
ODOO_DEPENDENCIES="git+https://github.com/vauxoo/odoo@8.0 \
                   git+https://github.com/vauxoo/server-tools@8.0 \
                   git+https://github.com/vauxoo/addons-vauxoo@8.0 \
                   git+https://github.com/vauxoo/odoo-venezuela@8.0 \
                   git+https://github.com/vauxoo/pylint-odoo@master"
                   # git+https://github.com/vauxoo/odoo-mexico-v2@8.0 \
DEPENDENCIES_FILE="$( mktemp -d )/odoo-requirements.txt"
DPKG_DEPENDS="nodejs \
              phantomjs \
              antiword \
              poppler-utils \
              xmlstarlet \
              xsltproc \
              xz-utils \
              swig \
              geoip-database-contrib"
DPKG_UNNECESSARY=""
NPM_OPTS="-g"
NPM_DEPENDS="less \
             less-plugin-clean-css \
             jshint"
PIP_OPTS="--upgrade \
          --no-cache-dir"
PIP_DEPENDS_EXTRA="pyyaml \
                   pillow \
                   pillow-pil \
                   M2Crypto \
                   GeoIP \
                   SOAPpy \
                   suds \
                   lxml \
                   pandas \
                   qrcode \
                   xmltodict \
                   flake8 \
                   pylint-mccabe \
                   PyWebDAV \
                   mygengo \
                   recaptcha-client \
                   egenix-mx-base \
                   hg+https://bitbucket.org/birkenfeld/sphinx-contrib@default#egg=sphinxcontrib-youtube&subdirectory=youtube \
                   git+https://github.com/vauxoo/pylint-odoo@master#egg=pylint-odoo \
                   git+https://github.com/vauxoo/panama-dv@master#egg=ruc"
PIP_DPKG_BUILD_DEPENDS="gcc \
                        g++ \
                        gfortran \
                        libblas-dev \
                        liblapack-dev \
                        cython \
                        python-dev \
                        libpq-dev \
                        libldap2-dev \
                        libsasl2-dev \
                        libxml2-dev \
                        libxslt1-dev \
                        libgeoip-dev \
                        zlib1g-dev"

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

# Install python dependencies
pip install ${PIP_OPTS} -r ${DEPENDENCIES_FILE}

# Install qt patched version of wkhtmltopdf because of maintainer nonsense
wkhtmltox_install "${WKHTMLTOX_URL}"

# Remove build depends for pip
apt-get purge ${PIP_DPKG_BUILD_DEPENDS} ${DPKG_UNNECESSARY}
apt-get autoremove

# Final cleaning
find /tmp -type f -print0 | xargs -0r rm -rf
find /var/tmp -type f -print0 | xargs -0r rm -rf
find /var/log -type f -print0 | xargs -0r rm -rf
find /var/lib/apt/lists -type f -print0 | xargs -0r rm -rf
