FROM vauxoo/docker-ubuntu-base:latest
MAINTAINER Tulio Ruiz <tulio@vauxoo.com>

COPY scripts/* /usr/share/vx-docker-internal/odoo90/
COPY files/hgrc /root/.hgrc
RUN bash /usr/share/vx-docker-internal/odoo90/build-image.sh
