FROM ubuntu:14.04
MAINTAINER Tulio Ruiz <tulio@vauxoo.com>
# Always asume yes when installing using apt (this is for travis integration)
RUN echo 'APT::Get::Assume-Yes "true";' >> /etc/apt/apt.conf \
    && echo 'APT::Get::force-yes "true";' >> /etc/apt/apt.conf
RUN locale-gen fr_FR \
    && locale-gen en_US.UTF-8 \
    && dpkg-reconfigure locales \
    && update-locale LANG=en_US.UTF-8 \
    && update-locale LC_ALL=en_US.UTF-8

ENV PYTHONIOENCODING utf-8
RUN apt-get update -q && apt-get upgrade -q \
    && apt-get install --allow-unauthenticated -q bzr \
    python \
    python-psycopg2 \
    python-setuptools \
    python-dev \
    libssl-dev \
    libyaml-dev \
    libjpeg-dev \
    libgeoip-dev \
    libffi-dev \
    libqrencode-dev \
    libfreetype6-dev \
    zlib1g-dev \
    git \
    wget \
    supervisor \
    openssh-client \
    python-lxml \
    vim
RUN ln -s /usr/include/freetype2 /usr/local/include/freetype \
    && ln -s /usr/lib/x86_64-linux-gnu/libjpeg.so /usr/lib/ \
    && ln -s /usr/lib/x86_64-linux-gnu/libfreetype.so /usr/lib/ \
    && ln -s /usr/lib/x86_64-linux-gnu/libz.so /usr/lib/
RUN cd /tmp && wget https://raw.githubusercontent.com/pypa/pip/master/contrib/get-pip.py && python get-pip.py
RUN pip install pyopenssl
RUN cd /tmp && git clone --depth=1 https://github.com/thewtex/sphinx-contrib.git \
    && cd sphinx-contrib/youtube && python setup.py install
RUN pip install pyyaml && pip install xmltodict && cd /tmp \
    && wget https://raw.githubusercontent.com/ruiztulio/gist-vauxoo/master/travis_run.py \
    && python travis_run.py

RUN apt-get clean && rm -rf /var/lib/apt/lists/* && rm -rf /tmp/*
