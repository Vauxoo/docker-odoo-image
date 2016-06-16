#!/usr/bin/env bash

# Exit inmediately after an error
set -e

# With a little help from my friends
. /usr/share/vx-docker-internal/ubuntu-base/library.sh
. /usr/share/vx-docker-internal/odoo80/library.sh
. /usr/share/vx-docker-internal/odoo-shippable/library.sh

# Let's set some defaults here
ARCH="$( dpkg --print-architecture )"

# git-core PPA data
GITCORE_PPA_REPO="deb http://ppa.launchpad.net/git-core/ppa/ubuntu trusty main"
GITCORE_PPA_KEY="http://keyserver.ubuntu.com:11371/pks/lookup?op=get&search=0xA1715D88E1DF1F24"

# Extra software download URLs
HUB_ARCHIVE="https://github.com/github/hub/releases/download/v2.2.3/hub-linux-${ARCH}-2.2.3.tgz"
NGROK_ARCHIVE="https://dl.ngrok.com/ngrok_2.0.19_linux_${ARCH}.zip"

# Extra software clone URLs
ZSH_THEME_REPO="https://gist.github.com/9931af23bbb59e772eec.git"
OH_MY_ZSH_REPO="https://github.com/robbyrussell/oh-my-zsh.git"
SPF13_REPO="https://github.com/spf13/spf13-vim.git"
VIM_OPENERP_REPO="https://github.com/vauxoo/vim-openerp.git"
GIT_REPO="https://github.com/git/git.git"
HUB_REPO="https://github.com/github/hub.git"
ODOO_REPO="https://github.com/vauxoo/odoo.git"
MQT_REPO="https://github.com/vauxoo/maintainer-quality-tools.git"
GIST_VAUXOO_REPO="https://github.com/vauxoo/gist-vauxoo.git"
PYLINT_REPO="https://github.com/vauxoo/pylint-conf.git"

DEPENDENCIES_FILE="$( mktemp -d )/odoo-requirements.txt"

DPKG_DEPENDS="postgresql-9.3 postgresql-contrib-9.3 \
              postgresql-9.5 postgresql-contrib-9.5 \
              perl-modules make pgbadger pgtune \
              xsltproc xmlstarlet openssl \
              poppler-utils antiword p7zip-full \
              expect-dev mosh bpython bsdtar rsync \
              ghostscript graphviz openssh-server zsh \
              lua50 liblua50-dev liblualib50-dev \
              exuberant-ctags git rake"
PIP_OPTS="--upgrade \
          --no-cache-dir"
PIP_DEPENDS_EXTRA="SOAPpy pyopenssl suds \
                   pillow qrcode xmltodict M2Crypto \
                   recaptcha-client egenix-mx-base \
                   PyWebDAV mygengo pandas==0.16.2 numexpr==2.4.4 \
                   ndg-httpsclient pyasn1 line-profiler \
                   watchdog isort coveralls"
PIP_DPKG_BUILD_DEPENDS="build-essential \
                        gfortran \
                        cython \
                        python-dev \
                        libfreetype6-dev \
                        zlib1g-dev \
                        libjpeg-dev \
                        libblas-dev \
                        liblapack-dev \
                        libpq-dev \
                        libldap2-dev \
                        libsasl2-dev \
                        libxml2-dev \
                        libxslt1-dev \
                        libgeoip-dev"

# Let's add the git-core ppa for having a more up-to-date git
add_custom_aptsource "${GITCORE_PPA_REPO}" "${GITCORE_PPA_KEY}"

# Release the apt monster!
apt-get update
apt-get upgrade
apt-get install ${DPKG_DEPENDS} ${PIP_DPKG_BUILD_DEPENDS}

# Install python dependencies
pip install ${PIP_OPTS} ${PIP_DEPENDS_EXTRA}

# Clone odoo & tools
git_clone_copy "${ODOO_REPO}" "8.0" "" "${REPO_REQUIREMENTS}/odoo"
#git_clone_copy "${GIST_VAUXOO_REPO}" "master" "" "/root/tools/gist-vauxoo"
git_clone_copy "${MQT_REPO}" "master" "" "${REPO_REQUIREMENTS}/linit_hook"
git_clone_copy "${PYLINT_REPO}" "master" "conf/pylint_vauxoo_light.cfg" "${REPO_REQUIREMENTS}/linit_hook/travis/cfg/travis_run_pylint.cfg"
git_clone_copy "${PYLINT_REPO}" "master" "conf/pylint_vauxoo_light_pr.cfg" "${REPO_REQUIREMENTS}/linit_hook/travis/cfg/travis_run_pylint_pr.cfg"
git_clone_copy "${PYLINT_REPO}" "master" "conf/pylint_vauxoo_light_beta.cfg" "${REPO_REQUIREMENTS}/linit_hook/travis/cfg/travis_run_pylint_beta.cfg"
ln -sf ${REPO_REQUIREMENTS}/linit_hook/git/* /usr/share/git-core/templates/hooks/

# Execute travis_install_nightly
LINT_CHECK=1 TESTS=0 ${REPO_REQUIREMENTS}/linit_hook/travis/travis_install_nightly

# Install hub & ngrok
targz_download_execute "${HUB_ARCHIVE}" "install"
zip_download_copy "${NGROK_ARCHIVE}" "ngrok" "/usr/local/bin/"

# Install & configure zsh
git_clone_execute "${OH_MY_ZSH_REPO}" "master" "tools/install.sh"
git_clone_copy "${ZSH_THEME_REPO}" "master" "schminitz.zsh-theme" "/root/.oh-my-zsh/themes/odoo-shippable.zsh-theme"
sed -i 's/robbyrussell/odoo-shippable/g' /root/.zshrc

# Install & configure vim
git_clone_execute "${SPF13_REPO}" "3.0" "bootstrap.sh"
git_clone_copy "${VIM_OPENERP_REPO}" "master" "vim/" "/root/.vim/bundle/vim-openerp"

sed -i 's/ set mouse\=a/\"set mouse\=a/g' /root/.vimrc
sed -i "s/let g:neocomplete#enable_at_startup = 1/let g:neocomplete#enable_at_startup = 0/g" /root/.vimrc

cat >> /root/.vimrc << EOF
colorscheme ir_black
set colorcolumn=80
set spelllang=en,es
EOF

cat >> /root/.vimrc.bundles << EOF
" Odoo snippets {
if count(g:spf13_bundle_groups, 'odoovim')
    Bundle 'vim-openerp'
endif
" }
EOF

cat >> /root/.vimrc.before << EOF
let g:spf13_bundle_groups = ['general', 'writing', 'odoovim',
                           \ 'programming', 'php', 'ruby',
                           \ 'python', 'javascript', 'html',
                           \ 'misc']
EOF

# Configure shell completion
git_clone_copy "${HUB_REPO}" "master" "etc/hub.bash_completion.sh" "/usr/local/bin/"
git_clone_copy "${GIT_REPO}" "master" "contrib/completion/git-prompt.sh" "/usr/local/bin/"
git_clone_copy "${GIT_REPO}" "master" "contrib/completion/git-completion.bash" "/usr/local/bin/"

cat >> /root/.profile << EOF
. /usr/local/bin/git-prompt.sh
. /usr/local/bin/git-completion.bash
. /usr/local/bin/hub.bash_completion.sh
. /usr/share/vx-docker-internal/odoo-shippable/bash-colors.sh
EOF

# Create travis_wait
echo "#\!/bin/bash\n\$@" > /usr/bin/travis_wait
chmod +x /usr/bin/travis_wait

# Configure ssh to allow root login
echo "PermitRootLogin yes" >> /etc/ssh/sshd_config

# Extend root config to every user created from now on
cp -r /root/.profile /root/.vim* /etc/skel/

# Create shippable user with sudo powers and git configuration
createuser "shippable" "shippablepwd" "Shippable" "hello@shippable.com"

# Set custom configuration of max connections, port and locks for postgresql
sed -i 's/#max_pred_locks_per_transaction = 64/max_pred_locks_per_transaction = 100/g' /etc/postgresql/*/main*/postgresql.conf
sed -i 's/max_connections = 100/max_connections = 200/g' /etc/postgresql/*/main*/postgresql.conf
sed -i 's/^port = .*/port = 5432/g' /etc/postgresql/*/main*/postgresql.conf

# Overwrite get_versions function to avoid overwriting the init script
# See https://github.com/vauxoo/docker-odoo-image/issues/114 for details
cat >> /usr/share/postgresql-common/init.d-functions << 'EOF'
get_versions() {
    versions="$( pg_lsclusters -h | grep online | awk '{print $1}' )"
    if [ -z "${versions}" ]; then
        if [ -n "${PSQL_VERSION}" ]; then
            versions="${PSQL_VERSION}"
        else
            versions="9.3"
        fi
    fi
}
EOF

# Create shippable role to postgres and shippable for postgres 9.5 and default version
PSQL_VERSION="9.5" /entrypoint_image
psql_create_role "shippable" "aeK5NWNr2"
psql_create_role "root" "aeK5NWNr2"

/etc/init.d/postgresql stop

PSQL_VERSION="9.3" /entrypoint_image
psql_create_role "shippable" "aeK5NWNr2"
psql_create_role "root" "aeK5NWNr2"

# Final cleaning
find /tmp -type f -print0 | xargs -0r rm -rf
find /var/tmp -type f -print0 | xargs -0r rm -rf
find /var/log -type f -print0 | xargs -0r rm -rf
find /var/lib/apt/lists -type f -print0 | xargs -0r rm -rf
