FROM centos:centos7

ENV RUBY_VERSION 2.6.6
ENV LANG C.UTF-8
ENV APP_ROOT /usr/src/record_wod
# rbenvのpathを通す
ENV RBENV_ROOT /home/dev/.rbenv
ENV PATH ${RBENV_ROOT}/shims:${RBENV_ROOT}/bin:${PATH}

# timezone
RUN cp /usr/share/zoneinfo/Asia/Tokyo /etc/localtime

# rubyに必要なパッケージをインストール
RUN yum -y update
RUN yum -y install \
  gcc \
  gcc-c++ \
  make \
  glibc-langpack-ja \
  readline \
  readline-devel \
  tar \
  bzip2 \
  openssl-devel \
  zlib-devel

# 便利パッケージをインストール
RUN yum -y install \
  git \
  curl \
  vim \
  sudo \
  unzip

# yarnとnodejsをインストール
# ↓ 参照: https://classic.yarnpkg.com/en/docs/install/#centos-stable
RUN curl --silent --location https://dl.yarnpkg.com/rpm/yarn.repo | sudo tee /etc/yum.repos.d/yarn.repo
# ↓ 参照: https://github.com/nodesource/distributions#installation-instructions-1
RUN curl -sL https://rpm.nodesource.com/setup_10.x | sudo bash -
RUN yum -y install nodejs yarn
RUN yum clean all

# このプロジェクトに必要な他のパッケージをインストール
RUN yum -y install \
  postgresql \
  postgresql-devel

# chromeをインストール
RUN curl https://intoli.com/install-google-chrome.sh | bash

# chromedriverをインストール
# バージョン一覧 https://chromedriver.storage.googleapis.com/index.html
RUN CHROME_DRIVER_VERSION=`curl -sS chromedriver.storage.googleapis.com/LATEST_RELEASE` && \
    curl -O -L http://chromedriver.storage.googleapis.com/${CHROME_DRIVER_VERSION}/chromedriver_linux64.zip
RUN unzip chromedriver_linux64.zip
RUN rm chromedriver_linux64.zip
RUN sudo mv chromedriver /usr/local/bin

# entrypointシェルを設定
COPY script/entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]

# devユーザー作成
RUN \
 useradd -m dev; \
 echo 'dev:dev' | chpasswd; \
 echo "dev ALL=NOPASSWD: ALL" >> /etc/sudoers
# アプリケーションソースコードのルートディレクトリを作成
RUN mkdir -p ${APP_ROOT}
RUN chown -R dev:dev ${APP_ROOT}
USER dev

# rbenvとruby-buildインストール
RUN git clone https://github.com/sstephenson/rbenv.git ${RBENV_ROOT}
RUN git clone https://github.com/sstephenson/ruby-build.git ${RBENV_ROOT}/plugins/ruby-build

# rbenvを速くするために動的なbash拡張をコンパイルする
RUN ${RBENV_ROOT}/src/configure
RUN make -C ${RBENV_ROOT}/src

# シェルにrbenvを設定
RUN echo 'eval "$(rbenv init -)"' >> ~/.bash_profile
RUN rbenv init -

# rbenvの確認
RUN curl -fsSL https://github.com/rbenv/rbenv-installer/raw/master/bin/rbenv-doctor | bash

# rubyインストール
RUN rbenv install ${RUBY_VERSION}
RUN rbenv rehash
RUN rbenv global ${RUBY_VERSION}

# bundlerをインストール
RUN gem install bundler

# アプリケーションソースコードのルートディレクトリへ移動
WORKDIR ${APP_ROOT}

# bundle install
COPY --chown=dev:dev Gemfile* ${APP_ROOT}/
RUN bundle install
RUN rbenv rehash

EXPOSE 3000