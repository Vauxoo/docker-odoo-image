FROM vauxoo/docker-ubuntu-base:16.04
MAINTAINER Tulio Ruiz <tulio@vauxoo.com>

ENV PSQL_VERSION="9.6"
COPY scripts/* /usr/share/vx-docker-internal/odoo100/
RUN bash /usr/share/vx-docker-internal/odoo100/build-image.sh
