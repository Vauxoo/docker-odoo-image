FROM vauxoo/odoo-80-image

MAINTAINER Tulio Ruiz <tulio@vauxoo.com>

# Configure locale
RUN locale-gen en_US.UTF-8 && update-locale
RUN echo 'LANG="en_US.UTF-8"' > /etc/default/locale

#RUN apt-key adv --keyserver pgp.mit.edu --recv-keys B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8
#RUN echo 'deb http://apt.postgresql.org/pub/repos/apt/ trusty-pgdg main' > /etc/apt/sources.list.d/pgdg.list

# Installing supervisor
#RUN apt-get update && apt-get upgrade -y \
#    && apt-get install -y supervisor python-software-properties \
#        software-properties-common postgresql-common python-psycopg2
#COPY files/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
#RUN echo -e "\nsudo /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf & sleep 15s" >> /etc/bash.bashrc

# Install postgres and clean
#RUN apt-get install -y postgresql-9.3 \
#        postgresql-client-9.3 postgresql-contrib-9.3 \
#    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Create shippable user
RUN sudo useradd -d /home/shippable -m -s /bin/bash -p shippablepwd shippable \
    && sudo echo 'shippable ALL=(ALL) NOPASSWD:ALL' | sudo tee -a /etc/sudoers; sudo mkdir -p /home/shippable/.ssh/; sudo chown -R $USER:$USER /home/shippable/; sudo chown -R shippable:shippable /home/shippable/

# Add git config data to root user
RUN git config --global user.name Shippable \
    && git config --global user.email hello@shippable.com

# Install basic postgres
RUN sudo apt-get update \
    && sudo apt-get install -y postgresql-9.3 postgresql-contrib-9.3

##ENV SHIPPABLE_POSTGRES_VERSION 9.3 # overwrite by shippable :(
ENV MY_CUSTOM_VAR hola_mundo

# Fix shippable key issue on start postgresql - https://github.com/docker/docker/issues/783#issuecomment-56013588
#RUN sudo mkdir /etc/ssl/private-copy \
#    && sudo mv /etc/ssl/private/* /etc/ssl/private-copy/ \
#    && sudo rm -r /etc/ssl/private \
#    && sudo mv /etc/ssl/private-copy /etc/ssl/private \
#    && sudo chmod -R 0700 /etc/ssl/private \
#    && sudo chown -R postgres /etc/ssl/private
# No work with Dockerfile, this should be into travis.yml

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
USER shippable

#RUN echo -e "\nsudo /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf &" >> ~/.bashrc

# Set the default command to run when starting the container
#ENTRYPOINT sudo /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf & /bin/bash
