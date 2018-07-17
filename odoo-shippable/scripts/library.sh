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
