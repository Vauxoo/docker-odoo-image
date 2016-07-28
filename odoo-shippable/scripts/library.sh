#!/usr/bin/env bash

git_clone_copy(){
    URL="${1}"
    BRANCH="${2}"
    WHAT="${3}"
    WHERE="${4}"
    TEMPDIR="$( mktemp -d )"
    OPTIONS="--depth 1 -b ${BRANCH} -q --no-single-branch --recursive"
    echo "Cloning ${URL} ..."
    mkdir -p $( dirname "${WHERE}" )
    git clone ${URL} ${OPTIONS} ${TEMPDIR}
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
    OPTIONS="--depth 30 -b ${BRANCH} -q --single-branch --recursive"
    echo "Cloning ${URL} ..."
    git clone ${URL} ${OPTIONS} ${TEMPDIR}
    bash "${TEMPDIR}/${SCRIPT}"
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


createuser(){
    USER="${1}"
    PASSWD="$( openssl passwd -crypt "${2}" )"
    NAME="${3}"
    EMAIL="${4}"
    useradd -d "/home/${USER}" -m -s "/bin/bash" -p "${PASSWD}" "${USER}"
    echo "${USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/100-vauxoo-sudoers
    git config --global user.name "${NAME}"
    git config --global user.email "${EMAIL}"
}

psql_create_role(){
    su - postgres -c "psql -c  \"CREATE ROLE ${1} LOGIN PASSWORD '${2}' SUPERUSER INHERIT CREATEDB CREATEROLE;\""
}
