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

ENV CMD_STRS_STARTS SHIPPABLE_CMD_

ENV SHIPPABLE_CMD_POSTGRESQL_START sudo su -c "sudo -u postgres /usr/lib/postgresql/9.3/bin/postgres -c "config_file=/etc/postgresql/9.3/main/postgresql.conf" > /tmp/pg.log 2>&1 & sleep 5s"

# Fix shippable key issue on start postgresql - https://github.com/docker/docker/issues/783#issuecomment-56013588
ENV SHIPPABLE_CMD_FIX_POSTGRES_SSL sudo mkdir -p /etc/ssl/private-copy \
        && sudo mkdir -p /etc/ssl/private \
        && sudo mv /etc/ssl/private/ /etc/ssl/private-copy/ \
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
