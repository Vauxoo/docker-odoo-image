FROM ubuntu:14.04
MAINTAINER Tulio Ruiz <tulio@vauxoo.com>
RUN locale-gen fr_FR && dpkg-reconfigure locales
RUN apt-get update && apt-get upgrade -y \
    && apt-get install --allow-unauthenticated -y bzr \
    graphviz \
    python python-dateutil \
    python-dev \
    python-egenix-mxdatetime \
    python-egenix-mxdatetime \
    python-feedparser \
    python-gdata \
    python-hippocanvas \
    python-imaging \
    python-ldap \
    python-libxml2 \
    python-libxslt1 \
    python-lxml \
    python-m2crypto \
    python-matplotlib \
    python-numpy \
    python-openid \
    python-psycopg2 \
    python-pybabel \
    python-pychart \
    python-setuptools \
    python-tz \
    python-vobject \
    python-webdav \
    python-xlwt \
    python-xlrd \
    python-yaml \
    python-zsi \
    python-psutil \
    python-cherrypy3 \
    python-unittest2 \
    python-gevent \
    libjpeg-dev \
    python-formencode \
    git \
    build-essential \
    libxext-dev \
    openssl \
    poppler-utils \
    libssl-dev \
    libxrender-dev \
    antiword \
    libpq-dev \
    libgeoip-dev \
    libqrencode-dev \
    xmlstarlet \
    xsltproc \
    wget \
    supervisor
RUN cd /tmp && wget https://raw.githubusercontent.com/pypa/pip/master/contrib/get-pip.py && python get-pip.py
ADD files/requirements.txt /tmp/
RUN cd /tmp && pip install -r requirements.txt
RUN cd /tmp && git clone https://github.com/kanzure/pyphantomjs && cd pyphantomjs python setup.py install
RUN cd /tmp && wget http://ufpr.dl.sourceforge.net/project/wkhtmltopdf/0.12.1/wkhtmltox-0.12.1_linux-trusty-amd64.deb  \
    && dpkg -i wkhtmltox-0.12.1_linux-trusty-amd64.deb
RUN cd /tmp && git clone https://github.com/thewtex/sphinx-contrib.git \
    && cd sphinx-contrib/youtube && python setup.py install
RUN cd /tmp && rm * -rf
