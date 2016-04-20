#!/usr/bin/env bash

# With a little help from my friends
. /usr/share/vx-docker-internal/ubuntu-base/library.sh
. /usr/share/vx-docker-internal/odoo80/library.sh

# Let's set some defaults here
ARCH="$( dpkg --print-architecture )"
NODE_UPSTREAM_REPO="deb http://deb.nodesource.com/node_5.x trusty main"
NODE_UPSTREAM_KEY="https://deb.nodesource.com/gpgkey/nodesource.gpg.key"
WKHTMLTOX_URL="http://download.gna.org/wkhtmltopdf/0.12/0.12.3/wkhtmltox-0.12.3_linux-generic-${ARCH}.tar.xz"
REQ_ODOO="https://raw.githubusercontent.com/vauxoo/odoo/8.0/requirements.txt"
REQ_ODOO_SERVER="https://raw.githubusercontent.com/Vauxoo/odoo-network/8.0/addons/network/scripts/odoo-server/05-install-dependencies-python-v80.sh"
DPKG_DEPENDS="nodejs \
              antiword \
              phantomjs \
              poppler-utils \
              python-imaging \
              python-libxml2 \
              ttf-dejavu \
              xmlstarlet \
              xsltproc \
              xz-utils \
              geoip-database-contrib"
DPKG_UNNECESSARY=""
NPM_OPTS="-g"
NPM_DEPENDS="less \
             less-plugin-clean-css"
PIP_OPTS="--upgrade \
          --no-cache-dir"
PIP_DEPENDS="pyyaml \
             pillow \
             M2Crypto \
             GeoIP \
             SOAPpy \
             suds \
             lxml \
             pandas \
             qrcode \
             xmltodict \
             recaptcha-client \
             egenix-mx-base"
PIP_VCS_DEPENDS="hg+https://bitbucket.org/birkenfeld/sphinx-contrib#subdirectory=youtube \
                 git+https://github.com/Vauxoo/panama-dv.git"
PIP_DPKG_BUILD_DEPENDS="gcc"

# Let's add the NodeJS upstream repo to install a newer version
add_custom_aptsource "${NODE_UPSTREAM_REPO}" "${NODE_UPSTREAM_KEY}"

# Release the apt monster!
apt-get update
apt-get upgrade
apt-get install ${DPKG_DEPENDS} ${PIP_DPKG_BUILD_DEPENDS}

# Install node dependencies
npm install ${NPM_OPTS} ${NPM_DEPENDS}

# Install python dependencies
pip install ${PIP_OPTS} ${PIP_DEPENDS}
pip install ${PIP_OPTS} $( parse_requirements ${REQ_ODOO} )
pip install ${PIP_OPTS} $( parse_requirements ${REQ_ODOO_SERVER} )
pip install ${PIP_OPTS} ${PIP_VCS_DEPENDS}

# Install qt patched version of wkhtmltopdf because of maintainer nonsense
wkhtmltox_install ${WKHTMLTOX_URL}

# Remove build depends for pip
apt-get purge ${PIP_DPKG_BUILD_DEPENDS} ${DPKG_UNNECESSARY}
apt-get autoremove

# Final cleaning
find /var/lib/apt/lists -type f -print0 | xargs -0r rm -rf
