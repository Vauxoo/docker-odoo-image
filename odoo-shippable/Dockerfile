FROM vauxoo/odoo-80-image

MAINTAINER Tulio Ruiz <tulio@vauxoo.com>
COPY files/entrypoint_image /entrypoint_image
COPY files/bash_colors /root/.bash_colors

ENV RUN_COMMAND_MQT_10_ENTRYPOINT_IMAGE /entrypoint_image
ENV INSTANCE_ALIVE 1

# Configure locale
RUN locale-gen en_US.UTF-8 && update-locale
RUN echo 'LANG="en_US.UTF-8"' > /etc/default/locale
ENV LANG C.UTF-8

# Create shippable user
RUN sudo useradd -d /home/shippable -m -s /bin/bash -p shippablepwd shippable \
    && sudo echo 'shippable ALL=(ALL) NOPASSWD:ALL' | sudo tee -a /etc/sudoers; sudo mkdir -p /home/shippable/.ssh/; sudo chown -R $USER:$USER /home/shippable/; sudo chown -R shippable:shippable /home/shippable/

# Add git config data to root user
RUN git config --global user.name Shippable \
    && git config --global user.email hello@shippable.com

# Install postgres common files
RUN sudo apt-get install postgresql-common

# Do not create postgres main clusters so we can name them mainVV where VV is postgres persion 93 or 95 do far
RUN sed -ri 's/#(create_main_cluster) .*$/\1 = false/' /etc/postgresql-common/createcluster.conf

# Install basic postgres 9.3 and 9.5
RUN sudo apt-get update \
    && sudo apt-get install -y postgresql-9.3 postgresql-contrib-9.3 \
    postgresql-9.5 postgresql-contrib-9.5

# Create the clusters with the proper naming
RUN pg_createcluster 9.3 main93 -e=utf8

RUN pg_createcluster 9.5 main95 -e=utf8

# Install pgbadger
RUN apt-get install perl-modules make
RUN git clone https://github.com/dalibo/pgbadger.git
RUN (cd pgbadger && perl Makefile.PL && make && make install)
RUN mv pgbadger ${HOME}/tools/

RUN sed -i 's/#max_pred_locks_per_transaction = 64/max_pred_locks_per_transaction = 100/g' /etc/postgresql/*/main*/postgresql.conf
RUN sed -i 's/max_connections = 100/max_connections = 200/g' /etc/postgresql/*/main*/postgresql.conf
RUN sed -i 's/^port = .*/port = 5432/g' /etc/postgresql/*/main*/postgresql.conf

ENV PSQL_VERSION 9.5
# Create shippable role to postgres and shippable for postgres 9.5
RUN /entrypoint_image \
    && su - postgres -c "psql -c  \"CREATE ROLE shippable LOGIN PASSWORD 'aeK5NWNr2' SUPERUSER INHERIT CREATEDB CREATEROLE;\"" \
    && su - postgres -c "psql -c  \"CREATE ROLE root LOGIN PASSWORD 'aeK5NWNr' SUPERUSER INHERIT CREATEDB CREATEROLE;\""
RUN /etc/init.d/postgresql stop

ENV PSQL_VERSION 9.3
# Create shippable role to postgres and shippable for postgres 9.3, as the version is not changed from this point on
# default will be 9.3 unless overriden
RUN /entrypoint_image \
    && su - postgres -c "psql -c  \"CREATE ROLE shippable LOGIN PASSWORD 'aeK5NWNr2' SUPERUSER INHERIT CREATEDB CREATEROLE;\"" \
    && su - postgres -c "psql -c  \"CREATE ROLE root LOGIN PASSWORD 'aeK5NWNr' SUPERUSER INHERIT CREATEDB CREATEROLE;\""


# Install some depends
##MX PACKAGES
RUN sudo apt-get install xsltproc xmlstarlet openssl
RUN sudo pip install SOAPpy pyopenssl suds \
                     pillow qrcode xmltodict M2Crypto
##ADDONS-VAUXOO PACKAGES#FIXME: This modules make error use or not use it
RUN sudo pip install recaptcha-client egenix-mx-base
##ODOO PACKAGES#FIXME: This package should be within the main script. # pdftotext is proppler-utils
RUN sudo pip install PyWebDAV mygengo
RUN sudo apt-get install poppler-utils antiword

# Forecast depends
RUN pip install --upgrade pandas numexpr

# Fix https://urllib3.readthedocs.org/en/latest/security.html#insecureplatformwarning
RUN sudo pip install --upgrade pyopenssl ndg-httpsclient pyasn1


# Expose the PostgreSQL port
EXPOSE 5432

# Change to user shippable
#USER shippable #  Not use this user because enviroment variable is set with last user used.
#WORKDIR /home/shippable
USER root
WORKDIR /root

ENV REPO_REQUIREMENTS /.repo_requirements

#  Download repositories requirements
RUN mkdir -p ${REPO_REQUIREMENTS}/odoo/ \
 && git init ${REPO_REQUIREMENTS}/odoo/ \
 && git --git-dir=${REPO_REQUIREMENTS}/odoo/.git remote add odoo https://github.com/odoo/odoo.git \
 && git --git-dir=${REPO_REQUIREMENTS}/odoo/.git remote add oca https://github.com/oca/ocb.git \
 && git --git-dir=${REPO_REQUIREMENTS}/odoo/.git remote add vauxoo https://github.com/vauxoo/odoo.git \
 && git --git-dir=${REPO_REQUIREMENTS}/odoo/.git fetch --all \

 && mkdir -p ${REPO_REQUIREMENTS}/addons-vauxoo/ \
 && git init ${REPO_REQUIREMENTS}/addons-vauxoo/ \
 && git --git-dir=${REPO_REQUIREMENTS}/addons-vauxoo/.git remote add vauxoo https://github.com/vauxoo/addons-vauxoo.git \
 && git --git-dir=${REPO_REQUIREMENTS}/addons-vauxoo/.git fetch --all

# Install git hook with pylint-odoo
RUN mkdir -p ${REPO_REQUIREMENTS}/linit_hook/ \
 && git clone https://github.com/OCA/maintainer-quality-tools.git ${REPO_REQUIREMENTS}/linit_hook/ \
 && ln -sf ${REPO_REQUIREMENTS}/linit_hook/git/* /usr/share/git-core/templates/hooks/

RUN pip install pylint_odoo

#  Setting global env for next shippable build
ENV WITHOUT_DEPENDENCIES 1

# Install standard packages
RUN apt-get install -y p7zip-full \
  && pip install watchdog isort coveralls

# Install ngrok to run fowardporting in developer environment
RUN  curl https://dl.ngrok.com/ngrok_2.0.19_linux_amd64.zip -o /tmp/ngrok.zip \
    && unzip -o /tmp/ngrok.zip -d /usr/local/bin/ \
    && rm -rf /tmp/ngrok.zip

# Add compatibility with "travis_wait" command.
RUN touch /usr/bin/travis_wait \
  && echo "#!/bin/bash\n\$@" > /usr/bin/travis_wait \
  && chmod +x /usr/bin/travis_wait

# Install "unbuffer" command used in MQT
RUN apt-get install -y expect-dev

# Install spf13 for vim, fix comments hidden, fix select text
#  and install lua (required by vim-neocomplete)
RUN curl http://j.mp/spf13-vim3 -L -o - | sh \
  && echo colorscheme ir_black >> ${HOME}/.vimrc \
  && echo 'let &colorcolumn=join(range(80,999),",")' >> ${HOME}/.vimrc \
  && sed -i 's/ set mouse\=a/\"set mouse\=a/g' ${HOME}/.vimrc \
  && apt-get install lua50 liblua50-dev liblualib50-dev \
  && echo "Plugin 'vim-airline/vim-airline-themes'" >> ~/.vimrc.bundles \
  && vim +PluginInstall +qall


# Install extra-developer-packages
RUN apt-get install -y mosh bpython \
  && wget https://github.com/github/hub/releases/download/v2.2.2/hub-linux-amd64-2.2.2.tgz -O /tmp/hub.tgz \
  && tar -xvzf /tmp/hub.tgz -C /tmp/ \
  && cp /tmp/hub*/bin/hub /usr/bin/hub \
  && wget https://raw.githubusercontent.com/github/hub/master/etc/hub.bash_completion.sh -O /usr/local/bin/hub.bash_completion.sh \
  && echo "if [ -f /usr/local/bin/hub.bash_completion.sh   ]; then . /usr/local/bin/hub.bash_completion.sh; fi" >> ${HOME}/.profile

# Install ghostscript and graphviz to allow print pdf
RUN apt-get install ghostscript graphviz

# Install ssh in developer images and allow root access
RUN apt-get install openssh-server
RUN echo "PermitRootLogin yes" >> /etc/ssh/sshd_config

# Install git prompt (Show current branch in prompt)
RUN curl https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh -o /usr/local/bin/git-prompt.sh && \
    echo 'source /usr/local/bin/git-prompt.sh\nsource ${HOME}/.bash_colors' >> ${HOME}/.profile

# Install zsh shell and Oh-my-Zsh!
RUN apt-get install zsh \
    && sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"; exit 0

# Copy Theme a set to use
RUN sed -i 's/robbyrussell/odoo-shippable/g' /root/.zshrc \
    && curl https://gist.githubusercontent.com/schminitz/9931af23bbb59e772eec/raw/cb524246fc93df242696bc3f502cababb03472ec/schminitz.zsh-theme -o /root/.oh-my-zsh/themes/odoo-shippable.zsh-theme

# Install git commands auto-completion
RUN curl https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash -o /usr/local/bin/git-completion.bash \
    && echo 'source /usr/local/bin/git-completion.bash' >> ${HOME}/.profile

RUN git clone https://github.com/vauxoo-dev/gist-vauxoo.git -b master ${HOME}/tools/gist-vauxoo

ENV OCA_RUNBOT 1

# Expose basic ports
  # Postgres database
EXPOSE 5432
  # odoo ports
EXPOSE 8069 8070 8071 8072
  # ssh port
EXPOSE 22
  # mosh port
EXPOSE 60000-60005/udp

