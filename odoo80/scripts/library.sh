#!/usr/bin/env bash

#
# PYPICONTENTS_URL="https://raw.githubusercontent.com/LuisAlejandro/pypicontents/master/pypicontents.json"
# PYPICONTENTS="$( wget -qO- "${PYPICONTENTS_URL}" )"
#

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
#
# function search_pypicontents(){
#     MODULE="${1}"
#     PACKAGES="$( python -c "
# import json
# pypicontents = json.loads('''${PYPICONTENTS}''')
# def find_package(contents, module):
#     for pkg, data in contents.items():
#         for mod in data['modules']:
#             if mod == module:
#                 yield pkg
# print ' '.join(list(find_package(pypicontents, '${MODULE}')))" )"
#     echo "${PACKAGES}"
# }

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

function collect_pip_dependencies(){
    REPOLIST="${1}"
    DEPENDENCIES="${2}"
    REQFILE="${3}"
    TEMPDIR="$( mktemp -d )"
    TEMPFILE="$( tempfile )"
    PIP_OPTS="--upgrade"

    for REPO in ${REPOLIST}; do
        read BIN URL NAME OPTIONS <<< "$( decompose_repo_url "${REPO}" )"
        if [ ! -e "${TEMPDIR}/${NAME}" ]; then
            ${BIN} clone ${URL} ${OPTIONS} ${TEMPDIR}/${NAME}
        fi
    done

    for OCA in $( find ${TEMPDIR} -type f -iname "oca_dependencies.txt" ); do
        read BIN URL NAME OPTIONS <<< "$( decompose_repo_url "$( cat "${OCA}" | awk '{print $2}' )" )"
        if [ ! -e "${TEMPDIR}/${NAME}" ]; then
            ${BIN} clone ${URL} ${OPTIONS} ${TEMPDIR}/${NAME}
        fi
    done

    # Install PIP_DEPENDS_EXTRA and
    # the required requirements-parser for the next step

    pip install ${PIP_OPTS} ${DEPENDENCIES}

    for REQ in $( find ${TEMPDIR} -type f -iname "requirements.txt" ); do
        /usr/share/vx-docker-internal/odoo80/gen_pip_deps ${REQ} ${DEPENDENCIES_FILE}
    done
}

function wkhtmltox_install(){
    URL="${1}"
    DIR="$( mktemp -d )"
    wget -q "${URL}" -O wkhtmltox.deb
    dpkg -i wkhtmltox.deb
    rm wkhtmltox.deb
}
