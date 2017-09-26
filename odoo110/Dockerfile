FROM vauxoo/docker-ubuntu-base:16.04-p3
MAINTAINER Tulio Ruiz <tulio@vauxoo.com>

ENV PSQL_VERSION="9.6"
COPY scripts/* /usr/share/vx-docker-internal/odoo110/
RUN bash /usr/share/vx-docker-internal/odoo110/build-image.sh
