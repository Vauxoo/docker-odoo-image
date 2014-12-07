FROM vauxoo/odoo-80-image

MAINTAINER Tulio Ruiz <tulio@vauxoo.com>

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
# Install webkit
RUN sudo apt-get install wkhtmltopdf

#RUN mkdir ${HOME}/odoo \
#    && git init ${HOME}/odoo \
#    && git --git-dir=${HOME}/odoo/.git remote add odoo https://github.com/odoo/odoo.git \
#    && git --git-dir=${HOME}/odoo/.git remote add vauxoo https://github.com/vauxoo/odoo.git \
#    && git --git-dir=${HOME}/odoo/.git remote add Vauxoo https://github.com/vauxoo/odoo.git \
#    && git --git-dir=${HOME}/odoo/.git remote add oca https://github.com/oca/ocb.git \
#    && git --git-dir=${HOME}/odoo/.git remote add OCA https://github.com/oca/ocb.git \
#    && git --git-dir=${HOME}/odoo/.git remote add -t 8.0 odoo-8.0 git@github.com:odoo/odoo.git
#    && git --git-dir=${HOME}/odoo/.git fetch --all \
#    && ln -sf ${HOME}/odoo ${HOME}/odoo-8.0 \
#    && ln -sf ${HOME}/odoo ${HOME}/odoo-7.0 \
#    && ln -sf ${HOME}/odoo ${HOME}/Vauxoo-8.0 \
#    && ln -sf ${HOME}/odoo ${HOME}/Vauxoo-7.0 \
#    && ln -sf ${HOME}/odoo ${HOME}/vauxoo-8.0 \
#    && ln -sf ${HOME}/odoo ${HOME}/vauxoo-7.0 \
#    && ln -sf ${HOME}/odoo ${HOME}/OCA-8.0 \
#    && ln -sf ${HOME}/odoo ${HOME}/OCA-7.0 \
#    && ln -sf ${HOME}/odoo ${HOME}/oca-8.0 \
#    && ln -sf ${HOME}/odoo ${HOME}/oca-7.0
#RUN git clone https://github.com/Vauxoo/addons-vauxoo.git ${HOME}/addons-vauxoo-upd

ENV CMD_STRS_STARTS SHIPPABLE_CMD_

ENV SHIPPABLE_CMD_POSTGRESQL_START sudo su -c "sudo -u postgres /usr/lib/postgresql/9.3/bin/postgres -c "config_file=/etc/postgresql/9.3/main/postgresql.conf" > /tmp/pg.log 2>&1 & sleep 5s"

# Fix shippable key issue on start postgresql - https://github.com/docker/docker/issues/783#issuecomment-56013588
RUN sudo mkdir -p /etc/ssl/private-copy \
        && sudo mkdir -p /etc/ssl/private \
        && sudo mv /etc/ssl/private/* /etc/ssl/private-copy/ \
        && sudo rm -rf /etc/ssl/private \
        && sudo mv /etc/ssl/private-copy /etc/ssl/private \
        && sudo chmod -R 0700 /etc/ssl/private \
        && sudo chown -R postgres /etc/ssl/private
ENV SHIPPABLE_CMD_FIX_ROOT_ODOO find ${HOME} -name server.py -exec sed -i "s/== 'root'/== 'force_root'/g" {} \;

# Change to user postgres
USER postgres

# Create shippable role to postgres
RUN /etc/init.d/postgresql start \
    && psql -c  "CREATE ROLE shippable LOGIN SUPERUSER INHERIT CREATEDB CREATEROLE;"

# Create root role to postgres
RUN /etc/init.d/postgresql start \
    && psql -c  "CREATE ROLE root LOGIN SUPERUSER INHERIT CREATEDB CREATEROLE;"

# Expose the PostgreSQL port
EXPOSE 5432

# Change to user shippable
#USER shippable #  Not use this user because enviroment variable is set with last user used.
#WORKDIR /home/shippable
USER root
WORKDIR /root

ENV REPO_REQUIREMENTS ${HOME}/.repo_requirements

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

