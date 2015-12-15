FROM vauxoo/odoo-80-image

MAINTAINER Tulio Ruiz <tulio@vauxoo.com>
COPY files/entrypoint_image /entrypoint_image

ENV RUN_COMMAND_MQT_10_ENTRYPOINT_IMAGE /entrypoint_image
ENV INSTANCE_ALIVE 1

# Configure locale
RUN locale-gen en_US.UTF-8 && update-locale
RUN echo 'LANG="en_US.UTF-8"' > /etc/default/locale

# Create shippable user
RUN sudo useradd -d /home/shippable -m -s /bin/bash -p shippablepwd shippable \
    && sudo echo 'shippable ALL=(ALL) NOPASSWD:ALL' | sudo tee -a /etc/sudoers; sudo mkdir -p /home/shippable/.ssh/; sudo chown -R $USER:$USER /home/shippable/; sudo chown -R shippable:shippable /home/shippable/

# Add git config data to root user
RUN git config --global user.name Shippable \
    && git config --global user.email hello@shippable.com

# Install basic postgres
RUN sudo apt-get update \
    && sudo apt-get install -y postgresql-9.3 postgresql-contrib-9.3

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

# Change to user postgres
USER postgres

# Create shippable role to postgres
RUN /entrypoint_image \
    && psql -c  "CREATE ROLE shippable LOGIN PASSWORD 'aeK5NWNr2' SUPERUSER INHERIT CREATEDB CREATEROLE;"

# Create root role to postgres
RUN /etc/init.d/postgresql start \
    && psql -c  "CREATE ROLE root LOGIN PASSWORD 'aeK5NWNr' SUPERUSER INHERIT CREATEDB CREATEROLE;"

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

# Install curl standard package to download files
RUN apt-get install curl

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
RUN curl http://j.mp/spf13-vim3 -L -o - | sh \
	&& echo colorscheme ir_black >> ${HOME}/.vimrc \
	&& sed -i 's/ set mouse\=a/\"set mouse\=a/g' ${HOME}/.vimrc

# Install extra-developer-packages
RUN apt-get install -y bpython

# Install ssh in developer images and allow root access
RUN apt-get install openssh-server
RUN echo "PermitRootLogin yes" >> /etc/ssh/sshd_config

# Install git prompt (Show current branch in prompt)
RUN curl https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh -o /usr/local/bin/git-prompt.sh && \
    echo 'source /usr/local/bin/git-prompt.sh\nexport PS1="\033[1;35m[ \u@\e[0;35m\h ]\e[0;37m-\[[ \w ]\\n\$(__git_ps1) $: "' >> ${HOME}/.profile

# Install git commands auto-completion
RUN curl https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash -o /usr/local/bin/git-completion.bash \
    && echo 'source /usr/local/bin/git-completion.bash' >> ${HOME}/.profile

ENV OCA_RUNBOT 1

# Expose basic ports
  # Postgres database
EXPOSE 5432
  # odoo ports
EXPOSE 8069 8070 8071 8072
  # ssh port
EXPOSE 22
