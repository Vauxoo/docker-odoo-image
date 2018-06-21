#!/usr/bin/env bash

# Exit inmediately after an error
# See vauxoo/docker-odoo-image#108
set -e

# With a little help from my friends
. /usr/share/vx-docker-internal/ubuntu-base/library.sh
. /usr/share/vx-docker-internal/odoo110/library.sh
. /etc/lsb-release
# Let's set some defaults here
ARCH="$( dpkg --print-architecture )"
NODE_UPSTREAM_REPO="deb http://deb.nodesource.com/node_5.x trusty main"
NODE_UPSTREAM_KEY="https://deb.nodesource.com/gpgkey/nodesource.gpg.key"
WKHTMLTOX_URL="https://downloads.wkhtmltopdf.org/0.12/0.12.4/wkhtmltox-0.12.4_linux-generic-${ARCH}.tar.xz"
ODOO_DEPENDENCIES="git+https://github.com/vauxoo/odoo@11.0 \
                   git+https://github.com/vauxoo/server-tools@11.0 \
                   git+https://github.com/vauxoo/addons-vauxoo@11.0 \
                   git+https://github.com/vauxoo/pylint-odoo@master"
DEPENDENCIES_FILE="/usr/share/vx-docker-internal/odoo110/11.0-full_requirements.txt"
DPKG_DEPENDS="nodejs \
              phantomjs \
              antiword \
              python3-dev \
              poppler-utils \
              xmlstarlet \
              xsltproc \
              xz-utils \
              swig \
              geoip-database-contrib \
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
              postgresql-common \
              postgresql-${PSQL_VERSION} \
              postgresql-client-${PSQL_VERSION} \
              postgresql-contrib-${PSQL_VERSION} \
              pgbadger \
              ruby-dev \
              ruby-compass \
              autoconf \
              automake \
              libtool \
              libltdl-dev \
              libcups2-dev"
DPKG_UNNECESSARY=""
NPM_OPTS="-g"
NPM_DEPENDS="less \
             less-plugin-clean-css \
             jshint"
PIP_OPTS="--upgrade \
          --no-cache-dir"

PIP_DEPENDS_EXTRA="reqgen \
                   requirements-parser \
                   git+https://github.com/vauxoo/pylint-odoo@master#egg=pylint-odoo \
                   git+https://github.com/vauxoo/panama-dv@master#egg=ruc \
                   hg+https://bitbucket.org/birkenfeld/sphinx-contrib@default#egg=sphinxcontrib-youtube&subdirectory=youtube"

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

# Let's recursively find our pip dependencies
collect_pip_dependencies "${ODOO_DEPENDENCIES}" "${PIP_DEPENDS_EXTRA}" "${DEPENDENCIES_FILE}"

# Cleans incorrect dependency lines  
clean_requirements ${DEPENDENCIES_FILE}

# install reqgenv
pip2 install reqgen

# Install python dependencies
pip3 install ${PIP_OPTS} -r ${DEPENDENCIES_FILE}

# Install qt patched version of wkhtmltopdf because of maintainer nonsense
wkhtmltox_install "${WKHTMLTOX_URL}"

# Install ruby dependencies
gem install ${RUBY_DEPENDS}

# Remove build depends for pip
apt-get purge ${PIP_DPKG_BUILD_DEPENDS} ${DPKG_UNNECESSARY}
apt-get autoremove

# Final cleaning
rm -rf /tmp/*
find /var/tmp -type f -print0 | xargs -0r rm -rf
find /var/log -type f -print0 | xargs -0r rm -rf
find /var/lib/apt/lists -type f -print0 | xargs -0r rm -rf
echo "include = '/etc/postgresql-common/common-vauxoo.conf'" >> /etc/postgresql/${PSQL_VERSION}/main/postgresql.conf
echo "host all  all    0.0.0.0/0  md5" >> /etc/postgresql/$PSQL_VERSION/main/pg_hba.conf
