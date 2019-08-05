FROM amazonlinux:2.0.20190508

LABEL maintainer="momospnr"

ENV APP_DEPS \
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

ENV PHP_DEPS \
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
  php-pecl-redis

ENV BUILD_DEPS \
  php-pecl-apcu-devel \
  mariadb-devel \
  ruby-devel \
  sqlite-devel

ENV PHP_VERSION 7.2
ENV NGINX_VERSION 1.12
ENV DOCKERIZE_VERSION v0.6.1

# setup
RUN set -ex \
  && yum update -y \
  && yum install -y yum-plugin-security \
  && yum update --security \
  && yum install -y \
    ${APP_DEPS} \
    ${BUILD_DEPS} \
  && wget https://bootstrap.pypa.io/ez_setup.py -O - | sudo python \
  && useradd ec2-user \
  && echo "ec2-user ALL=NOPASSWD: ALL" >> /etc/sudoers \
  && unlink /etc/localtime \
  && ln -s /usr/share/zoneinfo/Japan /etc/localtime \
# install packages
  ## PHP
  && amazon-linux-extras install -y php$PHP_VERSION \
  && yum install -y \
  ${PHP_DEPS} \
  && cat /etc/php.d/40-apcu.ini|(rm /etc/php.d/40-apcu.ini;sed -e s/\;apc.enable_cli=0/apc.enable_cli=1/g > /etc/php.d/40-apcu.ini) \
  ## Composer
  && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin \
  && mv /usr/bin/composer.phar /usr/bin/composer \
  ## Node
  && curl -sL https://rpm.nodesource.com/setup_10.x | bash - \
  && yum install -y nodejs \
  && curl --silent --location https://dl.yarnpkg.com/rpm/yarn.repo | tee /etc/yum.repos.d/yarn.repo \
  && yum install -y yarn \
  ## Dockerize
  && wget https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
  && tar -C /usr/bin -xzvf dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
  && rm dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
  ## nginx
  && amazon-linux-extras install -y nginx${NGINX_VERSION} \
  ## aws-cli
  && curl -O https://bootstrap.pypa.io/get-pip.py \
  && python get-pip.py \
  && rm -f get-pip.py \
  && pip install awscli --upgrade \
  ## mailcatcher
  && yum groupinstall -y "Development Tools" \
  && gem install mailcatcher \
# clean
  && yum groupremove -y "Development Tools" \
  && yum remove -y ${BUILD_DEPS} \
  && yum clean all \
  && rm -rf /var/cache/yum

ENV LANG ja_JP.utf8
ENV LC_ALL ja_JP.utf8

COPY php.ini-development /etc/php.ini

EXPOSE 9000
CMD ["/usr/sbin/php-fpm", "-F"]