FROM vauxoo/docker-ubuntu-base:latest
MAINTAINER Tulio Ruiz <tulio@vauxoo.com>

ENV PSQL_VERSION="9.6"
COPY scripts/* /usr/share/vx-docker-internal/odoo80/
RUN bash /usr/share/vx-docker-internal/odoo80/build-image.sh
