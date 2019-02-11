#!/usr/bin/env bash

git_clone_copy(){
    URL="${1}"
    BRANCH="${2}"
    WHAT="${3}"
    WHERE="${4}"
    TEMPDIR="$( mktemp -d )"
    echo "Cloning ${URL} ..."
    mkdir -p $( dirname "${WHERE}" )
    git clone ${URL} --depth 1 -b ${BRANCH} -q --single-branch --recursive ${TEMPDIR}
    rsync -aqz "${TEMPDIR}/${WHAT}" "${WHERE}"
    rm -rf ${TEMPDIR}
}

zip_download_copy(){
    URL="${1}"
    WHAT="${2}"
    WHERE="${3}"
    TEMPDIR="$( mktemp -d )"
    echo "Downloading ${URL} ..."
    mkdir -p $( dirname "${WHERE}" )
    wget -qO- "${URL}" | bsdtar -xf - -C "${TEMPDIR}/"
    rsync -aqz "${TEMPDIR}/${WHAT}" "${WHERE}"
    rm -rf "${TEMPDIR}"
}

git_clone_execute(){
    URL="${1}"
    BRANCH="${2}"
    SCRIPT="${3}"
    TEMPDIR="$( mktemp -d )"
    echo "Cloning ${URL} ..."
    git clone ${URL} --depth 1 -b ${BRANCH} -q --single-branch --recursive ${TEMPDIR}
    (cd ${TEMPDIR} && ./${SCRIPT})
    rm -rf ${TEMPDIR}
}

targz_download_execute(){
    URL="${1}"
    SCRIPT="${2}"
    TEMPDIR="$( mktemp -d )"
    echo "Downloading ${URL} ..."
    wget -qO- "${URL}" | tar -xz -C "${TEMPDIR}/"
    bash ${TEMPDIR}/*/${SCRIPT}
    rm -rf "${TEMPDIR}"
}


createuser_custom(){
    USER="${1}"
    useradd -d "/home/${USER}" -m -s "/bin/bash" "${USER}"
    su - ${USER} -c "git config --global user.name ${USER}"
    su - ${USER} -c "git config --global user.email ${USER}@email.com"
}

psql_create_role(){
    su - postgres -c "psql -c  \"CREATE ROLE ${1} LOGIN PASSWORD '${2}' SUPERUSER INHERIT CREATEDB CREATEROLE;\""
}

service_postgres_without_sudo(){
    USER="${1}"
    VERSIONS=$(pg_lsclusters  | sed '1d' | awk '{print $1}' )
    for version in $VERSIONS; do
        pg_dropcluster --stop $version main
    done
    adduser ${USER} postgres
    chown -R ${USER}:postgres /var/run/postgresql
    for version in $VERSIONS; do
        pg_createcluster -u ${USER} -g postgres -s /var/run/postgresql -p 15432 --lc-collate=${LC_COLLATE} --start-conf auto --start $version main
        echo "include = '/etc/postgresql-common/common-vauxoo.conf'" >> /etc/postgresql/$version/main/postgresql.conf
        su - ${USER} -c "psql -p 15432 -d postgres -c  \"ALTER ROLE ${USER} WITH PASSWORD 'aeK5NWNr2';\""
        su - ${USER} -c "psql -p 15432 -d postgres -c  \"CREATE ROLE postgres LOGIN SUPERUSER INHERIT CREATEDB CREATEROLE;\""
        /etc/init.d/postgresql stop $version
        sed -i "s/port = 15432/port = 5432/g" /etc/postgresql/$version/main/postgresql.conf
    done

}

install_py37(){
    # Based on https://github.com/docker-library/python/blob/7a794688c7246e7eff898f5288716a3e7dc08484/3.7/stretch/Dockerfile
    export GPG_KEY=0D96DF4D4110E5C43FBFB17F2D347EA6AA65421D
    export PYTHON_VERSION=3.7.0
    wget -O python.tar.xz "https://www.python.org/ftp/python/${PYTHON_VERSION%%[a-z]*}/Python-$PYTHON_VERSION.tar.xz" \
    && wget -O python.tar.xz.asc "https://www.python.org/ftp/python/${PYTHON_VERSION%%[a-z]*}/Python-$PYTHON_VERSION.tar.xz.asc" \
    && export GNUPGHOME="$(mktemp -d)" \
    && gpg --batch --keyserver ha.pool.sks-keyservers.net --recv-keys "$GPG_KEY" \
    && gpg --batch --verify python.tar.xz.asc python.tar.xz \
    && { command -v gpgconf > /dev/null && gpgconf --kill all || :; } \
    && rm -rf "$GNUPGHOME" python.tar.xz.asc \
    && mkdir -p /usr/src/python \
    && tar -xJC /usr/src/python --strip-components=1 -f python.tar.xz \
    && rm python.tar.xz \
    \
    && (cd /usr/src/python \
    && gnuArch="$(dpkg-architecture -qDEB_BUILD_GNU_TYPE)" \
    && ./configure \
        --build="$gnuArch" \
        --enable-loadable-sqlite-extensions \
        --enable-shared \
        --with-system-expat \
        --with-system-ffi \
        --without-ensurepip \
        --silent > /dev/null 2>&1 \
    && make -j "$(nproc)" --silent > /dev/null 2>&1\
    && make install --silent > /dev/null 2>&1 \
    && ldconfig) \
    \
    && find /usr/local -depth \
        \( \
            \( -type d -a \( -name test -o -name tests \) \) \
            -o \
            \( -type f -a \( -name '*.pyc' -o -name '*.pyo' \) \) \
        \) -exec rm -rf '{}' + \
    && rm -rf /usr/src/python \
    \
    && python3.7 --version
    unset GPG_KEY PYTHON_VERSION GNUPGHOME
}

install_pyflame(){
    apt-get update
    apt-get install autoconf automake autotools-dev g++ libtool pkg-config git -y
    git clone --depth=1 --single-branch https://github.com/uber/pyflame.git /tmp/pyflame
    (cd /tmp/pyflame && \
        ./autogen.sh && \
        ./configure && \
        make && \
        make install)
    rm -rf /tmp/pyflame
    git clone --depth=1 --single-branch https://github.com/brendangregg/FlameGraph /tmp/flamegraph
    cp /tmp/flamegraph/flamegraph.pl /usr/local/bin/
}

install_tmux(){
    git clone -b 2.8 --single-branch --depth=1 https://github.com/tmux/tmux.git /tmp/tmux
    apt-get install -y libevent-dev
    (cd /tmp/tmux && \
        ./autogen.sh --silent && \
        ./configure --silent && make --silent && \
        make install
    )
    rm -rf /tmp/tmux
}
