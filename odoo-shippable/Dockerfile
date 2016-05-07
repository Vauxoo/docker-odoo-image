FROM vauxoo/odoo-80-image

MAINTAINER Tulio Ruiz <tulio@vauxoo.com>
COPY files/entrypoint_image /entrypoint_image
COPY files/bash_colors /root/.bash_colors
COPY files/etc_initd_postgresql /tmp/etc_initd_postgresql
COPY files/get_odoo_git_compress.sh /get_odoo_git_compress.sh

ENV RUN_COMMAND_MQT_10_ENTRYPOINT_IMAGE="/entrypoint_image" \
    INSTANCE_ALIVE="1" PSQL_VERSION="9.3" \
    REPO_REQUIREMENTS="/.repo_requirements" \
    WITHOUT_DEPENDENCIES="1" OCA_RUNBOT="1"

# Create shippable user
# Add git config data to root user
RUN useradd -d /home/shippable -m -s /bin/bash -p shippablepwd shippable \
    && echo 'shippable ALL=(ALL) NOPASSWD:ALL' | tee -a /etc/sudoers; mkdir -p /home/shippable/.ssh/; chown -R $USER:$USER /home/shippable/; chown -R shippable:shippable /home/shippable/ \
    && git config --global user.name Shippable \
    && git config --global user.email hello@shippable.com

# Install postgres common files
# Do not create postgres main clusters so we can name them mainVV where VV is postgres version 93 or 95 do far
# Install basic postgres 9.3 and 9.5
# Create the clusters with the proper naming
# Set custom configuration of max connections, port and locks
# Install pgbadger
RUN apt-get update && apt-get install postgresql-common \
    && sed -ri 's/#(create_main_cluster) .*$/\1 = false/' /etc/postgresql-common/createcluster.conf \
    && apt-get install -y postgresql-9.3 postgresql-contrib-9.3 \
    postgresql-9.5 postgresql-contrib-9.5 perl-modules make pgtune \
    && mv /tmp/etc_initd_postgresql /etc/init.d/postgresql \
    && chmod +x /etc/init.d/postgresql \
    && rm -rf /var/lib/apt/lists/* \
    && pg_createcluster 9.3 main -e=utf8 \
    && pg_createcluster 9.5 main -e=utf8 \
    && sed -i 's/#max_pred_locks_per_transaction = 64/max_pred_locks_per_transaction = 100/g' /etc/postgresql/*/main*/postgresql.conf \
    && sed -i 's/max_connections = 100/max_connections = 200/g' /etc/postgresql/*/main*/postgresql.conf \
    && sed -i 's/^port = .*/port = 5432/g' /etc/postgresql/*/main*/postgresql.conf \
    && git clone https://github.com/dalibo/pgbadger.git /tmp/pgbadger \
    && (cd /tmp/pgbadger && perl Makefile.PL && make && make install) \
    && mv /tmp/pgbadger/pgbadger /usr/bin/pgbadger \
    && rm -rf /tmp/pgbadger

# Create shippable role to postgres and shippable for postgres 9.5 and default version
RUN PSQL_VERSION="9.5" /entrypoint_image \
    && su - postgres -c "psql -c  \"CREATE ROLE shippable LOGIN PASSWORD 'aeK5NWNr2' SUPERUSER INHERIT CREATEDB CREATEROLE;\"" \
    && su - postgres -c "psql -c  \"CREATE ROLE root LOGIN PASSWORD 'aeK5NWNr' SUPERUSER INHERIT CREATEDB CREATEROLE;\"" \
    && /etc/init.d/postgresql stop \
    && /entrypoint_image \
    && su - postgres -c "psql -c  \"CREATE ROLE shippable LOGIN PASSWORD 'aeK5NWNr2' SUPERUSER INHERIT CREATEDB CREATEROLE;\"" \
    && su - postgres -c "psql -c  \"CREATE ROLE root LOGIN PASSWORD 'aeK5NWNr' SUPERUSER INHERIT CREATEDB CREATEROLE;\""

# Install depends
RUN apt-get remove -y git \
    && apt-get update \
    && apt-get install -y software-properties-common \
    && add-apt-repository ppa:git-core/ppa -y \
    && apt-get update \
    && apt-get install -y xsltproc xmlstarlet openssl \
        poppler-utils antiword p7zip-full expect-dev mosh bpython \
        ghostscript graphviz openssh-server zsh \
        lua50 liblua50-dev liblualib50-dev \
        exuberant-ctags \
        git \
    && pip install --upgrade SOAPpy pyopenssl suds \
        pillow qrcode xmltodict M2Crypto \
        recaptcha-client egenix-mx-base \
        PyWebDAV mygengo pandas==0.16.2 numexpr==2.4.4 \
        ndg-httpsclient pyasn1 \
        pylint_odoo watchdog isort coveralls \
    && echo "PermitRootLogin yes" >> /etc/ssh/sshd_config \
    && curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh | sh; echo "$?" \
    && sed -i 's/robbyrussell/odoo-shippable/g' /root/.zshrc \
    && curl https://gist.githubusercontent.com/schminitz/9931af23bbb59e772eec/raw/cb524246fc93df242696bc3f502cababb03472ec/schminitz.zsh-theme -o /root/.oh-my-zsh/themes/odoo-shippable.zsh-theme \
    && rm -rf /var/lib/apt/lists/*

# Install hub, git prompt, git auto-completion, other dev packages
# Install spf13 for vim, fix comments hidden, fix select text
#  and disable neocomplete at startup
# Add compatibility with "travis_wait" command.
RUN wget https://github.com/github/hub/releases/download/v2.2.2/hub-linux-amd64-2.2.2.tgz -O /tmp/hub.tgz \
  && tar -xvzf /tmp/hub.tgz -C /tmp/ \
  && cp /tmp/hub*/bin/hub /usr/bin/hub \
  && rm -rf /tmp/hub*/ && rm /tmp/hub.tgz \
  && wget https://raw.githubusercontent.com/github/hub/master/etc/hub.bash_completion.sh -O /usr/local/bin/hub.bash_completion.sh \
  && echo "if [ -f /usr/local/bin/hub.bash_completion.sh   ]; then . /usr/local/bin/hub.bash_completion.sh; fi" >> ${HOME}/.profile \
  && curl https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh -o /usr/local/bin/git-prompt.sh \
  && echo 'source /usr/local/bin/git-prompt.sh\nsource ${HOME}/.bash_colors' >> ${HOME}/.profile \
  && curl https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash -o /usr/local/bin/git-completion.bash \
  && echo 'source /usr/local/bin/git-completion.bash' >> ${HOME}/.profile \
  && git clone https://github.com/vauxoo-dev/gist-vauxoo.git -b master ${HOME}/tools/gist-vauxoo \
  && mkdir -p ${REPO_REQUIREMENTS}/linit_hook/ \
  && git clone https://github.com/OCA/maintainer-quality-tools.git ${REPO_REQUIREMENTS}/linit_hook/ \
  && wget https://raw.githubusercontent.com/Vauxoo/pylint-conf/master/conf/pylint_vauxoo_light.cfg -O ${REPO_REQUIREMENTS}/linit_hook/travis/cfg/travis_run_pylint.cfg \
  && wget https://raw.githubusercontent.com/Vauxoo/pylint-conf/master/conf/pylint_vauxoo_light_pr.cfg -O ${REPO_REQUIREMENTS}/linit_hook/travis/cfg/travis_run_pylint_pr.cfg \
  && ln -sf ${REPO_REQUIREMENTS}/linit_hook/git/* /usr/share/git-core/templates/hooks/ \
  && curl http://ftp.vim.org/pub/vim/runtime/spell/es.utf-8.spl -o /usr/share/vim/vim74/spell/es.utf-8.spl \
  && curl https://dl.ngrok.com/ngrok_2.0.19_linux_amd64.zip -o /tmp/ngrok.zip \
  && unzip -o /tmp/ngrok.zip -d /usr/local/bin/ \
  && rm -rf /tmp/ngrok.zip \
  && curl http://j.mp/spf13-vim3 -L -o - | sh \
  && git clone --recursive --single-branch --depth=1 https://github.com/Vauxoo/vim-openerp.git /tmp/vim-openerp \
  && mkdir -p ${HOME}/.vim/bundle/vim-openerp \
  && cp -r /tmp/vim-openerp/vim/* ${HOME}/.vim/bundle/vim-openerp/. \
  && echo "" >> ${HOME}/.vimrc.bundles \
  && echo "\" Odoo snippets { " >> ${HOME}/.vimrc.bundles \
  && echo "    if count(g:spf13_bundle_groups, 'odoovim')" >> ${HOME}/.vimrc.bundles \
  && echo "        Bundle 'vim-openerp' " >> ${HOME}/.vimrc.bundles \
  && echo "    endif " >> ${HOME}/.vimrc.bundles \
  && echo "\" } " >> ${HOME}/.vimrc.bundles \
  && echo "let g:spf13_bundle_groups=['general', 'writing', 'odoovim', 'programming', 'php', 'ruby', 'python', 'javascript', 'html', 'misc',]" >> ${HOME}/.vimrc.before \
  && rm -rf /tmp/vim-openerp \
  && echo "colorscheme ir_black" >> ${HOME}/.vimrc \
  && echo "set colorcolumn=80" >> ${HOME}/.vimrc \
  && echo "set spelllang=en,es" >> ${HOME}/.vimrc \
  && sed -i 's/ set mouse\=a/\"set mouse\=a/g' ${HOME}/.vimrc \
  && sed -i "s/let g:neocomplete#enable_at_startup = 1/let g:neocomplete#enable_at_startup = 0/g" ${HOME}/.vimrc \
  && touch /usr/bin/travis_wait \
  && echo "#\!/bin/bash\n\$@" > /usr/bin/travis_wait \
  && chmod +x /usr/bin/travis_wait

#  Download repositories requirements
#  NOTE: The "git gc" command is executed with "unbuffer" to get output status
#        and avoid timeout build in CI and hub.docker.com
RUN mkdir -p ${REPO_REQUIREMENTS}/odoo \
  && wget -O /tmp/odoo_git.tar.gz -nv https://www.dropbox.com/s/4e982wpsis63xf6/odoo_git.tar.gz?dl=0 \
  && mkdir -p /tmp/odoo_git_uncompress \
  && tar -xf /tmp/odoo_git.tar.gz -C /tmp/odoo_git_uncompress \
  && mv /tmp/odoo_git_uncompress/.git ${REPO_REQUIREMENTS}/odoo/.git \
  && rm /tmp/odoo_git.tar.gz

# Expose postgresql, odoo, ssh and mosh ports
EXPOSE 5432 8069 8070 8071 8072 22 60000-60005/udp
