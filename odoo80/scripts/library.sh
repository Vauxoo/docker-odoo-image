#!/usr/bin/env bash


PYPICONTENTS_URL="https://raw.githubusercontent.com/LuisAlejandro/pypicontents/master/pypicontents.json"
PYPICONTENTS="$( wget -qO- "${PYPICONTENTS_URL}" )"


function decompose_repo_url(){
    REPO="${1}"
    VCS="$( echo "${REPO}" | awk -F'+' '{print $1}' )"
    [ -z "${VCS}" ] && VCS="git"
    BRANCH="$( echo "${REPO}" | awk -F'@' '{print $2}' | awk -F'#' '{print $1}' )"
    [ -z "${BRANCH}" ] && [ "${VCS}" == "git" ] && BRANCH="master"
    [ -z "${BRANCH}" ] && [ "${VCS}" == "hg" ] && BRANCH="default"
    URL="$( echo "${REPO}" | sed "s|${VCS}+||g;s|@${BRANCH}.*||g" )"
    [ "${VCS}" == "git" ] && OPTIONS="--depth 1 -q -b ${BRANCH}"
    [ "${VCS}" == "hg" ] && OPTIONS="-q -b ${BRANCH}"
    NAME="$( python -c "
import os, urlparse
print os.path.basename(urlparse.urlparse('${URL}').path)" )"
    echo "${VCS} ${URL} ${NAME} ${OPTIONS}"
}

function search_pypicontents(){
    MODULE="${1}"
    PACKAGES="$( python -c "
import json
pypicontents = json.loads('''${PYPICONTENTS}''')
def find_package(contents, module):
    for pkg, data in contents.items():
        for mod in data['modules']:
            if mod == module:
                yield pkg
print ' '.join(list(find_package(pypicontents, '${MODULE}')))" )"
    echo "${PACKAGES}"
}

function collect_dependencies(){
    REPOLIST="${1}"
    TEMPDIR="$( mktemp -d )"

    for REPO in ${REPOLIST}; do
        read VCS URL NAME OPTIONS <<< "$( decompose_repo_url "${REPO}" )"
        if [ ! -e "${TEMPDIR}/${NAME}" ]; then
            ${VCS} clone ${URL} ${OPTIONS} ${TEMPDIR}/${NAME}
        fi
    done

    for OCA in $( find ${TEMPDIR} -type f -iname "oca_dependencies.txt" ); do
        read VCS URL NAME OPTIONS <<< "$( decompose_repo_url "$( echo "${OCA}" | awk '{print $2}' )" )"
        if [ ! -e "${TEMPDIR}/${NAME}" ]; then
            ${VCS} clone ${URL} ${OPTIONS} ${TEMPDIR}/${NAME}
        fi
    done

    for REQ in $( find ${TEMPDIR} -type f -iname "requirements.txt" ); do
        DEPENDENCIES+=" $( cat "${REQ}" | xargs )"
    done

    for ODOO in $( find ${TEMPDIR} -type f -iname "__openerp__.py" ); do
        MODULES="$( python -c "
x=$( cat "${ODOO}" | sed 's/#.*//g;/^$/d' )
if 'external_dependencies' in x:
    if 'python' in x['external_dependencies']:
        print ' '.join(x['external_dependencies']['python'])" )"
        for MODULE in ${MODULES}; do
            DEPENDENCIES+=" $( search_pypicontents "${MODULE}" )"
        done
    done

    echo "$( echo "${DEPENDENCIES}" )"
    rm -rf "${TEMPDIR}"
}

function process_dependencies(){
    TEMPDIR="$( mktemp -d )"
    TEMPFILE="$( tempfile )"
    DEPENDENCIES="${1}"
    SCM="$( python -c "
import re
x='''${DEPENDENCIES}'''
print ' '.join(re.findall(r'((?:git|hg)\+https?://[^\s]+)', x))" )"
    PIP="$( python -c "
import re
regex=r'(?:git|hg)\+\w+:\/{2}[\d\w-]+(\.[\d\w-]+)*(?:(?:\/[^\s/]*))*'
x='''${DEPENDENCIES}'''
print re.sub(regex, '', x)" )"

    for S in ${SCM}; do
        read VCS URL NAME OPTIONS <<< "$( decompose_repo_url "${S}" )"
        if [ ! -e "${TEMPDIR}/${NAME}" ]; then
            ${VCS} clone ${URL} ${OPTIONS} ${TEMPDIR}/${NAME}
        fi
        if [ -e "${TEMPDIR}/${NAME}/requirements.txt" ]; then
            pip install -q -r "${TEMPDIR}/${NAME}/requirements.txt"
        fi
    done

    printf "%s\n" ${PIP} > "${TEMPFILE}"
    cd /tmp && merge_requirements "${TEMPFILE}" "/dev/null" > /dev/null 2>&1
    mv "/tmp/requirements-merged.txt" "${TEMPFILE}"
    printf "\n-e %s" ${SCM} >> "${TEMPFILE}"
    pip-compile --no-header "${TEMPFILE}"
    rm -rf "${TEMPFILE}" "${TEMPDIR}"
}

function wkhtmltox_install(){
    URL="${1}"
    DIR="$( mktemp -d )"
    wget -qO- "${URL}" | tar -xJ -C "${DIR}/"
    mv "${DIR}/wkhtmltox/bin/wkhtmltopdf" "/usr/local/bin/wkhtmltopdf"
    rm -rf "${DIR}"
}
