FROM amazonlinux:2.0.20190508

LABEL maintainer="momospnr"

RUN set -ex

# initial setup
RUN yum update -y 
RUN yum install -y yum-plugin-security
RUN yum update --security
RUN yum install -y \
    sudo \
    shadow-utils \
    procps \
    wget \
    openssh-server \
    openssh-clients \
    glibc-langpack-ja \
    which \
    net-tools \
    mlocate \
    systat \
    man \
    git \
    gzip \
    tar \
    jq

RUN wget https://bootstrap.pypa.io/ez_setup.py -O - | sudo python

RUN useradd ec2-user
RUN echo "ec2-user ALL=NOPASSWD: ALL" >> /etc/sudoers

ENV LANG ja_JP.utf8
ENV LC_ALL ja_JP.utf8

RUN unlink /etc/localtime \
  && ln -s /usr/share/zoneinfo/Japan /etc/localtime

# install packages

## PHP
ENV PHP_VERSION 7.2
RUN amazon-linux-extras install -y php$PHP_VERSION
RUN yum install -y \
  php-mbstring \
  php-xmlrpc \
  php-pecl-memcached \
  php-gd \
  php-opcache \
  php-soap \
  php-pecl-apcu \
  php-pecl-mcrypt \
  php-pecl-zip \
  php-devel \
  php-intl \
  php-pecl-apcu-devel \
  php-pecl-redis \
  mariadb-devel

# Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin \
  && mv /usr/bin/composer.phar /usr/bin/composer


# Node
RUN curl -sL https://rpm.nodesource.com/setup_10.x | bash - \
  && yum install -y nodejs \
  && curl --silent --location https://dl.yarnpkg.com/rpm/yarn.repo | tee /etc/yum.repos.d/yarn.repo \
  && yum install -y yarn

# Dockerize
ENV DOCKERIZE_VERSION v0.6.1
RUN wget https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
    && tar -C /usr/bin -xzvf dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
    && rm dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz

# mailcatcher
RUN yum groupinstall -y "Development Tools"
RUN yum install -y \
  ruby-devel \
  sqlite-devel
RUN gem install mailcatcher

# nginx
ENV NGINX_VERSION 1.12
RUN amazon-linux-extras install -y nginx${NGINX_VERSION}

# aws-cli
RUN curl -O https://bootstrap.pypa.io/get-pip.py \
  && python get-pip.py \
  && rm -f get-pip.py \
  && pip install awscli --upgrade

# clean
RUN yum groupremove -y "Development Tools"
RUN yum clean all

COPY php.ini-development /etc/php.ini

EXPOSE 9000
CMD ["/usr/sbin/php-fpm", "-F"]