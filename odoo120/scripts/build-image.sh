#!/usr/bin/env bash

# Exit inmediately after an error
# See vauxoo/docker-odoo-image#108
set -e

# With a little help from my friends
. /usr/share/vx-docker-internal/ubuntu-base/library.sh
. /usr/share/vx-docker-internal/odoo120/library.sh
. /etc/lsb-release
# Let's set some defaults here
ARCH="$( dpkg --print-architecture )"
WKHTMLTOX_URL="https://downloads.wkhtmltopdf.org/0.12/0.12.4/wkhtmltox-0.12.4_linux-generic-${ARCH}.tar.xz"
DPKG_DEPENDS="nodejs \
              npm \
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
NPM_DEPENDS="phantomjs-prebuilt \
             less \
             less-plugin-clean-css \
             jshint"
PIP_OPTS="--upgrade \
          --no-cache-dir"

PIP_DEPENDS_EXTRA="requirements-parser \
                   git+https://github.com/vauxoo/pylint-odoo@master#egg=pylint-odoo \
                   git+https://github.com/vauxoo/panama-dv@master#egg=ruc \
                   hg+https://bitbucket.org/birkenfeld/sphinx-contrib@default#egg=sphinxcontrib-youtube&subdirectory=youtube"

PIP_DPKG_BUILD_DEPENDS=""

RUBY_DEPENDS="compass \
              bootstrap-sass"

# Let's add the NodeJS upstream repo to install a newer version
#add_custom_aptsource "${NODE_UPSTREAM_REPO}" "${NODE_UPSTREAM_KEY}"

# Release the apt monster!
apt-get update
apt-get upgrade
apt-get install ${DPKG_DEPENDS} ${PIP_DPKG_BUILD_DEPENDS}

# Install node dependencies
npm install ${NPM_OPTS} ${NPM_DEPENDS}

pip2 install ${PIP_OPTS} reqgen
# Let's recursively find our pip dependencies
pip3 install ${PIP_OPTS} ${PIP_DEPENDS_EXTRA}

# Cleans incorrect dependency lines
#clean_requirements ${DEPENDENCIES_FILE}

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
