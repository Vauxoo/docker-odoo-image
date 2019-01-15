#!/usr/bin/env bash

function decompose_repo_url(){
    REPO="${1}"
    BIN="$( echo "${REPO}" | awk -F'+' '{print $1}' )"
    [ -z "${BIN}" ] && BIN="git"
    [ "${BIN}" != "git" ] && [ "${BIN}" != "hg"  ] && BIN="git"
    BRANCH="$( echo "${REPO}" | awk -F'@' '{print $2}' | awk -F'#' '{print $1}' )"
    [ -z "${BRANCH}" ] && [ "${BIN}" == "git" ] && BRANCH="8.0"
    [ -z "${BRANCH}" ] && [ "${BIN}" == "hg" ] && BRANCH="default"
    URL="$( echo "${REPO}" | sed "s|${BIN}+||g;s|@${BRANCH}.*||g" )"
    [ "${BIN}" == "git" ] && OPTIONS="--depth 1 -q -b ${BRANCH}"
    [ "${BIN}" == "hg" ] && OPTIONS="-q -b ${BRANCH}"
    NAME="$( python -c "
import os
import urlparse
print os.path.basename(urlparse.urlparse('${URL}').path)" )"
    echo "${BIN} ${URL} ${NAME} ${OPTIONS}"
}

function extract_vcs(){
    python -c "
import re
x='''${1}'''
print ' '.join(re.findall(r'((?:git|hg)\+https?://[^\s]+)', x))"
}

function extract_pip(){
    python -c "
import re
regex=r'(?:git|hg)\+\w+:\/{2}[\d\w-]+(\.[\d\w-]+)*(?:(?:\/[^\s/]*))*'
x='''${1}'''
print re.sub(regex, '', x)"
}

function clean_requirements(){
    python -c "
import re
req = open('$1', 'r').read()
req = list(set(req.split('\n')))
req2 = []
regex = r'([a-z](([0-9][a-z])|([a-z]+)))(((==|>=)[0-9].+)|'')'
for i in req:
    match = re.match(regex, i, re.I)
    if match:
        req2.append(i)
open('$1', 'w').writelines('\n'.join(req2))"
}

function wkhtmltox_install(){
    URL="${1}"
    DIR="$( mktemp -d )"
    wget -qO "${DIR}/wkhtmltox.deb" "${URL}"
    dpkg -i "${DIR}/wkhtmltox.deb"
    rm -rf "${DIR}"
}

function geoip_install(){
    URLS="${1}"
    DIR="$( mktemp -d )"
    mkdir -p "/usr/share/GeoIP"
    for URL in ${URLS}; do
        wget -qO- "${URL}" | tar -xz -C "${DIR}/"
        mv "$(find ${DIR} -name "GeoLite2*mmdb")" "/usr/share/GeoIP/"
    done
    rm -rf "${DIR}"
}

function phantomjs_install(){
    URL="${1}"
    DIR="$( mktemp -d )"
    wget -qO "${DIR}/phantomjs.tar.bz2" "${URL}"
    mkdir -p "${DIR}/phantomjs"
    tar xvjf "${DIR}/phantomjs.tar.bz2" -C "${DIR}/phantomjs/" --strip-components=1
    mv "${DIR}/phantomjs/" /usr/local/share
    ln -sf /usr/local/share/phantomjs/bin/phantomjs /usr/local/bin
    rm -rf "${DIR}"
}
