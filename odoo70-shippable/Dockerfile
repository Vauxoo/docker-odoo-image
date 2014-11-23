FROM vauxoo/odoo-80-image

MAINTAINER Tulio Ruiz <tulio@vauxoo.com>

# Configure locale
RUN locale-gen en_US.UTF-8 && update-locale
RUN echo 'LANG="en_US.UTF-8"' > /etc/default/locale

RUN apt-key adv --keyserver pgp.mit.edu --recv-keys B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8
RUN echo 'deb http://apt.postgresql.org/pub/repos/apt/ trusty-pgdg main' > /etc/apt/sources.list.d/pgdg.list

RUN apt-get update && apt-get upgrade -y \
    && apt-get install -y supervisor python-software-properties \
        software-properties-common postgresql-common python-psycopg2

# Do not create main cluster
##RUN sed -ri 's/#(create_main_cluster) .*$/\1 = false/' /etc/postgresql-common/createcluster.conf

# Install postgres and clean
RUN apt-get install -y postgresql-9.3 \
        postgresql-client-9.3 postgresql-contrib-9.3 \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN mkdir -p /var/log/supervisor

# Create shippable user
RUN sudo useradd -d /home/shippable -m -s /bin/bash -p shippablepwd shippable \
    && sudo echo 'shippable ALL=(ALL) NOPASSWD:ALL' | sudo tee -a /etc/sudoers; sudo mkdir -p /home/shippable/.ssh/; sudo chown -R $USER:$USER /home/shippable/; sudo chown -R shippable:shippable /home/shippable/

# Add git config data to root user
RUN git config --global user.name Shippable \
    && git config --global user.email hello@shippable.com

# Change to user postgres
USER postgres

# Create shippable role to postgres
RUN /etc/init.d/postgresql start \
    && psql -c  "CREATE ROLE shippable LOGIN SUPERUSER INHERIT CREATEDB CREATEROLE;"

# Expose the PostgreSQL port
EXPOSE 5432

# Change to user shippable
USER shippable

# Add git config data to shippable user
#RUN git config --global user.name Shippable \
#    && git config --global user.email hello@shippable.com


# Set the default command to run when starting the container
CMD ["sudo", "su", "postgres", "--command", "/usr/lib/postgresql/9.3/bin/postgres -D /var/lib/postgresql/9.3/main -c config_file=/etc/postgresql/9.3/main/postgresql.conf"]
