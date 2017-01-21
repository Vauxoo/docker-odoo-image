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

# ppa sources
PYTHON_PPA_REPO="deb http://ppa.launchpad.net/fkrull/deadsnakes/ubuntu trusty main"
PYTHON_PPA_KEY="http://keyserver.ubuntu.com:11371/pks/lookup?op=get&search=0x5BB92C09DB82666C"
VIM_PPA_REPO="deb http://ppa.launchpad.net/pkg-vim/vim-daily/ubuntu trusty main"
VIM_PPA_KEY="http://keyserver.ubuntu.com:11371/pks/lookup?op=get&search=0xA7266A2DD31525A0"

# Extra software download URLs
HUB_ARCHIVE="https://github.com/github/hub/releases/download/v2.2.3/hub-linux-${ARCH}-2.2.3.tgz"
NGROK_ARCHIVE="https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-${ARCH}.zip"

# Extra software clone URLs
ZSH_THEME_REPO="https://gist.github.com/9931af23bbb59e772eec.git"
OH_MY_ZSH_REPO="https://github.com/robbyrussell/oh-my-zsh.git"
SPF13_REPO="https://github.com/spf13/spf13-vim.git"
VIM_OPENERP_REPO="https://github.com/vauxoo/vim-openerp.git"
HUB_REPO="https://github.com/github/hub.git"
ODOO_VAUXOO_REPO="https://github.com/vauxoo/odoo.git"
ODOO_VAUXOO_DEV_REPO="https://github.com/vauxoo-dev/odoo.git"
ODOO_ODOO_REPO="https://github.com/odoo/odoo.git"
ODOO_OCA_REPO="https://github.com/oca/ocb.git"
MQT_REPO="https://github.com/vauxoo/maintainer-quality-tools.git"
GIST_VAUXOO_REPO="https://github.com/vauxoo-dev/gist-vauxoo.git"
PYLINT_REPO="https://github.com/vauxoo/pylint-conf.git"

DPKG_DEPENDS="postgresql-9.3 postgresql-contrib-9.3 postgresql-9.5 postgresql-contrib-9.5 \
              pgbadger pgtune perl-modules make openssl p7zip-full expect-dev mosh bpython \
              bsdtar rsync graphviz openssh-server cmake zsh \
              lua50 liblua50-dev liblualib50-dev exuberant-ctags rake \
              python3.3 python3.3-dev python3.4 python3.4-dev python3.5 python3.5-dev \
              python3-pip software-properties-common Xvfb libmagickwand-dev"
PIP_OPTS="--upgrade \
          --no-cache-dir"
PIP_DEPENDS_EXTRA="line-profiler watchdog isort coveralls diff-highlight pg-activity virtualenv"
PIP_DPKG_BUILD_DEPENDS=""
NPM_OPTS="-g"
NPM_DEPENDS="localtunnel fs-extra eslint"

# Let's add the git-core ppa for having a more up-to-date git
add_custom_aptsource "${GITCORE_PPA_REPO}" "${GITCORE_PPA_KEY}"
# Let's add the fkrull deadsnakes ppa for get python3.x versions
add_custom_aptsource "${PYTHON_PPA_REPO}" "${PYTHON_PPA_KEY}"
# Let's add the vim ppa for having a more up-to-date vim
add_custom_aptsource "${VIM_PPA_REPO}" "${VIM_PPA_KEY}"

# Release the apt monster!
apt-get update
apt-get upgrade
apt-get install ${DPKG_DEPENDS} ${PIP_DPKG_BUILD_DEPENDS}

# Install node dependencies
npm install ${NPM_OPTS} ${NPM_DEPENDS}

# Fix reinstalling npm packages
# See https://github.com/npm/npm/issues/9863 for details
sed -i 's/graceful-fs/fs-extra/g;s/fs.rename/fs.move/g' $(npm root -g)/npm/lib/utils/rename.js

# Install python dependencies
pip install ${PIP_OPTS} ${PIP_DEPENDS_EXTRA}

# Install xvfb daemon
wget https://raw.githubusercontent.com/travis-ci/travis-cookbooks/master/cookbooks/travis_build_environment/files/default/etc-init.d-xvfb.sh -O /etc/init.d/xvfb
chmod +x /etc/init.d/xvfb

# Init without download to add odoo remotes
git init ${REPO_REQUIREMENTS}/odoo
git --git-dir="${REPO_REQUIREMENTS}/odoo/.git" remote add vauxoo "${ODOO_VAUXOO_REPO}"
git --git-dir="${REPO_REQUIREMENTS}/odoo/.git" remote add vauxoo-dev "${ODOO_VAUXOO_DEV_REPO}"
git --git-dir="${REPO_REQUIREMENTS}/odoo/.git" remote add odoo "${ODOO_ODOO_REPO}"
git --git-dir="${REPO_REQUIREMENTS}/odoo/.git" remote add oca "${ODOO_OCA_REPO}"

# Download the cached branches from vauxoo/odoo to avoid the download by each build
git --git-dir="${REPO_REQUIREMENTS}/odoo/.git" fetch vauxoo 8.0 --depth=10
git --git-dir="${REPO_REQUIREMENTS}/odoo/.git" fetch vauxoo 9.0 --depth=10

# Clean
git --git-dir="${REPO_REQUIREMENTS}/odoo/.git" gc --aggressive

# Clone tools
git_clone_copy "${GIST_VAUXOO_REPO}" "master" "" "~/tools/gist-vauxoo"
git_clone_copy "${MQT_REPO}" "master" "" "${REPO_REQUIREMENTS}/linit_hook"
git_clone_copy "${PYLINT_REPO}" "master" "conf/pylint_vauxoo_light.cfg" "${REPO_REQUIREMENTS}/linit_hook/travis/cfg/travis_run_pylint.cfg"
git_clone_copy "${PYLINT_REPO}" "master" "conf/pylint_vauxoo_light_pr.cfg" "${REPO_REQUIREMENTS}/linit_hook/travis/cfg/travis_run_pylint_pr.cfg"
git_clone_copy "${PYLINT_REPO}" "master" "conf/pylint_vauxoo_light_beta.cfg" "${REPO_REQUIREMENTS}/linit_hook/travis/cfg/travis_run_pylint_beta.cfg"
git_clone_copy "${PYLINT_REPO}" "master" "conf/pylint_vauxoo_light_vim.cfg" "${REPO_REQUIREMENTS}/linit_hook/travis/cfg/travis_run_pylint_vim.cfg"
git_clone_copy "${PYLINT_REPO}" "master" "conf/.jslintrc" "${REPO_REQUIREMENTS}/linit_hook/travis/cfg/.jslintrc"
ln -sf ${REPO_REQUIREMENTS}/linit_hook/git/* /usr/share/git-core/templates/hooks/

# Execute travis_install_nightly
LINT_CHECK=1 TESTS=0 ${REPO_REQUIREMENTS}/linit_hook/travis/travis_install_nightly
pip install --user -q --no-binary pycparser -r ${REPO_REQUIREMENTS}/linit_hook/travis/requirements.txt

# Install hub & ngrok
targz_download_execute "${HUB_ARCHIVE}" "install"
zip_download_copy "${NGROK_ARCHIVE}" "ngrok" "/usr/local/bin/"
chmod +x /usr/local/bin/ngrok

# Configure diff-highlight on git after install
cat >> /etc/gitconfig << EOF
[pager]
    log = diff-highlight | less
    show = diff-highlight | less
    diff = diff-highlight | less
EOF

# Install & configure zsh
git_clone_execute "${OH_MY_ZSH_REPO}" "master" "tools/install.sh"
git_clone_copy "${ZSH_THEME_REPO}" "master" "schminitz.zsh-theme" "~/.oh-my-zsh/themes/odoo-shippable.zsh-theme"
sed -i 's/robbyrussell/odoo-shippable/g' ~/.zshrc

# Upgrade & configure vim
apt-get upgrade vim
wget -q -O /usr/share/vim/vim74/spell/es.utf-8.spl http://ftp.vim.org/pub/vim/runtime/spell/es.utf-8.spl
git_clone_execute "${SPF13_REPO}" "3.0" "bootstrap.sh"
git_clone_copy "${VIM_OPENERP_REPO}" "master" "vim/" "~/.vim/bundle/vim-openerp"

sed -i 's/ set mouse\=a/\"set mouse\=a/g' ~/.vimrc
sed -i "s/let g:neocomplete#enable_at_startup = 1/let g:neocomplete#enable_at_startup = 0/g" ~/.vimrc

# Install YouCompleteMe
git clone https://github.com/Valloric/YouCompleteMe.git ~/.vim/bundle/YouCompleteMe
(cd ~/.vim/bundle/YouCompleteMe && git submodule update --init --recursive && ./install.py)

# Install WakaTime
git clone --depth=1 --single-branch git://github.com/wakatime/vim-wakatime.git ~/.vim/bundle/wakatime

cat >> ~/.vimrc << EOF
colorscheme heliotrope
set colorcolumn=80
set spelllang=en,es
EOF

# Configure pylint_odoo plugin and the .conf file
# to enable python pylint_odoo checks and eslint checks into the vim editor.
cat >> ~/.vimrc << EOF
:filetype on
let g:syntastic_aggregate_errors = 1
let g:syntastic_python_checkers = ['pylint', 'flake8']
let g:syntastic_auto_loc_list = 1
let g:syntastic_python_pylint_args =
    \ '--rcfile=/.repo_requirements/linit_hook/travis/cfg/travis_run_pylint_vim.cfg --load-plugins=pylint_odoo'
let g:syntastic_python_flake8_args =
    \ '--config=/.repo_requirements/linit_hook/travis/cfg/travis_run_flake8.cfg'
let g:syntastic_javascript_checkers = ['eslint']
let g:syntastic_javascript_eslint_args =
    \ '--config /.repo_requirements/linit_hook/travis/cfg/.jslintrc'
EOF

cat >> ~/.vimrc.bundles.local << EOF
" Odoo snippets {
if count(g:spf13_bundle_groups, 'odoovim')
    Bundle 'vim-openerp'
endif
" }
" wakatime bundle {
if filereadable(expand("~/.wakatime.cfg")) && count(g:spf13_bundle_groups, 'wakatime')
    Bundle 'vim-wakatime'
endif
" }
EOF

cat >> ~/.vimrc.before.local << EOF
let g:spf13_bundle_groups = ['general', 'writing', 'odoovim', 'wakatime',
                           \ 'programming', 'youcompleteme', 'php', 'ruby',
                           \ 'python', 'javascript', 'html',
                           \ 'misc']
EOF

cat >> /etc/bash.bashrc << EOF
PYTHONPATH=${PYTHONPATH}:/.repo_requirements/odoo
EOF

# Configure shell, shell colors & shell completion
chsh --shell /bin/bash root
git_clone_copy "${HUB_REPO}" "master" "etc/hub.bash_completion.sh" "/etc/bash_completion.d/"

cat >> ~/.bashrc << 'EOF'
Purple="\[\033[0;35m\]"
BIPurple="\[\033[1;95m\]"
Color_Off="\[\033[0m\]"
PathShort="\w"
UserMachine="$BIPurple[\u@$Purple\h]"
GREEN_WOE="\001\033[0;32m\002"
RED_WOE="\001\033[0;91m\002"
git_ps1_style(){
    local git_branch="$(__git_ps1 2>/dev/null)";
    local git_ps1_style="";
    if [ -n "$git_branch" ]; then
        if [ -n "$GIT_STATUS" ]; then
            (git diff --quiet --ignore-submodules HEAD 2>/dev/null)
            local git_changed=$?
            if [ "$git_changed" == 0 ]; then
                git_ps1_style=$GREEN_WOE;
            else
                git_ps1_style=$RED_WOE;
            fi
        fi
        git_ps1_style=$git_ps1_style$git_branch
    fi
    echo -e "$git_ps1_style"
}
PS1=$UserMachine$Color_Off$PathShort\$\\n"\$(git_ps1_style)"$Color_Off\$" "
EOF

# Add alias for psql logs
cat >> /etc/bash.bashrc << EOF
alias psql_logs_enable='export PGOPTIONS="$PGOPTIONS -c client_min_messages=notice -c log_min_messages=warning -c log_min_error_statement=error -c log_min_duration_statement=0 -c log_connections=on -c log_disconnections=on -c log_duration=off -c log_error_verbosity=verbose -c log_lock_waits=on -c log_statement=none -c log_temp_files=0"'
alias psql_logs_disable='unset PGOPTIONS'
alias psql_logs_clean='echo "" | tee /var/lib/postgresql/*/main/pg_log/postgresql.log'
alias psql_logs_tail='tail -f /var/lib/postgresql/*/main/pg_log/postgresql.log'
EOF

cat >> /etc/bash.bashrc << EOF
if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        . /etc/bash_completion
    fi
fi
EOF

# Create travis_wait
echo $'#!/bin/bash\n$@' > /usr/bin/travis_wait
chmod +x /usr/bin/travis_wait

# Configure ssh to allow root login but just using ssh key
cat >> /etc/ssh/sshd_config << EOF
PermitRootLogin yes
PasswordAuthentication no
EOF

# Extend root config to every user created from now on
ln -sf ~/.profile ~/.bash* ~/.vim* /etc/skel/

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

# Enable PG LOGS AND NON DURABILITY
PG_NON_DURABILITY=1 PG_LOGS_ENABLE=1 python ${REPO_REQUIREMENTS}/linit_hook/travis/psql_log.py

# Install & Configure RVM
curl -sSL https://rvm.io/mpapis.asc | gpg --import -
\curl -sSL https://get.rvm.io | /bin/bash -s stable --ruby

cat >> /etc/bash.bashrc << EOF

# Load RVM into a shell session *as a function*
source "/usr/local/rvm/scripts/rvm"

EOF

# Final cleaning
rm -rf /tmp/*
find /var/tmp -type f -print0 | xargs -0r rm -rf
find /var/log -type f -print0 | xargs -0r rm -rf
find /var/lib/apt/lists -type f -print0 | xargs -0r rm -rf
