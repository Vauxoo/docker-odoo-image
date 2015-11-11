FROM ubuntu:12.04
RUN echo Etc/Utc > /etc/timezone && dpkg-reconfigure --frontend noninteractive tzdata
RUN locale-gen es_MX \
    && locale-gen es_MX.UTF-8 \
    && dpkg-reconfigure locales \
    && update-locale LANG=es_MX.UTF-8 \
    && update-locale LC_ALL=es_MX.UTF-8 \
    && echo 'LANG="es_MX.UTF-8"' > /etc/default/locale
RUN apt-key adv --keyserver pgp.mit.edu --recv-keys B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8
RUN echo 'deb http://apt.postgresql.org/pub/repos/apt/ precise-pgdg main' > /etc/apt/sources.list.d/pgdg.list
RUN apt-get update -q &&  \
    apt-get install -y vim wget git bzr supervisor python-setuptools \
    python-chardet python-pychart python-zsi python-lazr.restfulclient \
    libfreetype6-dev python-dev libpq-dev python-gobject python-gobject-dev \
    python-utidylib  libqrencode-dev libldap2-dev libsasl2-dev libgpgme11-dev \
    g++ libpng-dev libxml2-dev libxslt1-dev python-m2crypto swig python-geoip \
    libjpeg-dev libfreetype6-dev zlib1g-dev python-imaging supervisor \
    openssl xsltproc python-soappy bzip2 postgresql-client-9.3 \
    postgresql-common libpq-dev
RUN easy_install pip
RUN easy_install -U distribute
RUN cd /tmp \
    && wget http://wkhtmltopdf.googlecode.com/files/wkhtmltopdf-0.11.0_rc1-static-amd64.tar.bz2 \
    && tar -xjf wkhtmltopdf-0.11.0_rc1-static-amd64.tar.bz2 \
    && mv wkhtmltopdf-amd64 /usr/bin/wkhtmltopdf
COPY files/requirements61.txt /tmp/requirements61.txt
RUN pip install -r /tmp/requirements61.txt
RUN pip install egenix-mx-base

