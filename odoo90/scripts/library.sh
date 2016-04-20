#!/usr/bin/env bash

function parse_requirements(){
    URL="${1}"
    wget -qO- ${URL} | sed 's/pip install//g;s/--upgrade//g;s/#.*//g' | xargs
}

function wkhtmltox_install(){
    URL="${1}"
    DIR="$( mktemp -d )"
    wget -qO- ${URL} | tar -xJ -C ${DIR}/
    mv ${DIR}/wkhtmltox/bin/wkhtmltopdf /usr/local/bin/wkhtmltopdf
    rm -rf ${DIR}
}

