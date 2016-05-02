#!/usr/bin/env bash


PYPICONTENTS_URL="https://raw.githubusercontent.com/LuisAlejandro/pypicontents/master/pypicontents.json"
PYPICONTENTS="$( wget -qO- "${PYPICONTENTS_URL}" )"


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

    VCS="$( extract_vcs "${DEPENDENCIES}" )"
    PIP="$( extract_pip "${DEPENDENCIES}" )"

    for REPO in ${VCS}; do
        read BIN URL NAME OPTIONS <<< "$( decompose_repo_url "${REPO}" )"
        if [ ! -e "${TEMPDIR}/${NAME}" ]; then
            ${BIN} clone ${URL} ${OPTIONS} ${TEMPDIR}/${NAME}
        fi
        if [ -e "${TEMPDIR}/${NAME}/requirements.txt" ]; then
            VCS+=" $( extract_vcs "$( cat "${TEMPDIR}/${NAME}/requirements.txt" | sed 's/^#.*//g' )" )"
            PIP+=" $( extract_pip "$( cat "${TEMPDIR}/${NAME}/requirements.txt" | sed 's/^#.*//g' )" )"
        fi
    done

    printf "%s\n" ${PIP,,} > "${TEMPFILE}"
    printf "%s\n" ${VCS,,} | sed 's/#/@@/g' >> "${TEMPFILE}"
    cd /tmp && merge_requirements "${TEMPFILE}" "/dev/null"
    printf "%s\n" $( cat "/tmp/requirements-merged.txt" ) | sed 's/@@/#/g' > "${TEMPFILE}"

    VCS="$( extract_vcs "$( cat "${TEMPFILE}" )" )"
    PIP="$( extract_pip "$( cat "${TEMPFILE}" )" )"
    printf "%s\n" ${PIP,,} > "${TEMPFILE}"
    pip-compile "${TEMPFILE}" -o "${TEMPFILE}"

    PIP="$( extract_pip "$( cat "${TEMPFILE}" | sed 's/#.*//g')" )"
    VCSEGGS="$( printf "%s\n" ${VCS} | sed 's/@@/#/g;s/ /\n/g;s/.*#//g;s/egg=//g;s/&.*//g' | xargs )"

    >"${REQFILE}"
    for PD in ${PIP,,}; do
        P="$( echo ${PD} | awk -F'==' '{print $1}' )"
        if ! echo " ${VCSEGGS} " | grep -q " ${P} "; then
            echo "${PD}" >> "${REQFILE}"
        fi
    done

    printf "%s\n" ${VCS,,} >> "${REQFILE}"
    rm -rf "${TEMPFILE}" "${TEMPDIR}"
}

function wkhtmltox_install(){
    URL="${1}"
    DIR="$( mktemp -d )"
    wget -qO- "${URL}" | tar -xJ -C "${DIR}/"
    mv "${DIR}/wkhtmltox/bin/wkhtmltopdf" "/usr/local/bin/wkhtmltopdf"
    rm -rf "${DIR}"
}
