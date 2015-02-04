FROM ubuntu:12.04
RUN echo Etc/Utc > /etc/timezone && dpkg-reconfigure --frontend noninteractive tzdata
RUN locale-gen es_MX \
    && locale-gen es_MX.UTF-8 \
    && dpkg-reconfigure locales \
    && update-locale LANG=es_MX.UTF-8 \
    && update-locale LC_ALL=es_MX.UTF-8 \
    && echo 'LANG="es_MX.UTF-8"' > /etc/default/locale

RUN apt-get update -q &&  \
    apt-get install -y vim wget git bzr supervisor python-setuptools \
    python-chardet python-pychart python-zsi python-lazr.restfulclient \
    libfreetype6-dev python-dev libpq-dev python-gobject python-gobject-dev \
    python-utidylib  libqrencode-dev libldap2-dev libsasl2-dev libgpgme11-dev \
    g++ libpng-dev libxml2-dev libxslt1-dev python-m2crypto swig python-geoip \
    libjpeg-dev libfreetype6-dev zlib1g-dev python-imaging supervisor \
    openssl xsltproc python-soappy
RUN easy_install pip
RUN easy_install -U distribute

ADD files/requirements61.txt /tmp/requirements61.txt
RUN pip install -r /tmp/requirements61.txt
RUN pip install egenix-mx-base

