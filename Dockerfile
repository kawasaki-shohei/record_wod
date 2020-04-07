FROM centos:centos7

ENV RUBY_VERSION 2.7.1
ENV LANG C.UTF-8
ENV APP_ROOT /usr/src/random_wod
# rbenvのpathを通す
ENV RBENV_ROOT /usr/local/rbenv
ENV PATH $RBENV_ROOT/shims:$RBENV_ROOT/bin:$PATH

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

# このプロジェクトに必要な他のパッケージをインストール
RUN yum -y install \
  postgresql \
  postgresql-devel

# ログインユーザーを作成
RUN \
 useradd -m dev; \
 echo 'dev:dev' | chpasswd; \
 echo "dev ALL=NOPASSWD: ALL" >> /etc/sudoers
RUN chown -R dev:dev /home/dev

# chromeをインストール
RUN curl https://intoli.com/install-google-chrome.sh | bash

# chromedriverをインストール
# バージョン一覧 https://chromedriver.storage.googleapis.com/index.html
RUN CHROME_DRIVER_VERSION=`curl -sS chromedriver.storage.googleapis.com/LATEST_RELEASE` && \
    curl -O -L http://chromedriver.storage.googleapis.com/$CHROME_DRIVER_VERSION/chromedriver_linux64.zip
RUN unzip chromedriver_linux64.zip
RUN rm chromedriver_linux64.zip
RUN sudo mv chromedriver /usr/local/bin

# rbenvとruby-buildインストール
RUN git clone https://github.com/sstephenson/rbenv.git $RBENV_ROOT
RUN git clone https://github.com/sstephenson/ruby-build.git $RBENV_ROOT/plugins/ruby-build

# rbenvを速くするために動的なbash拡張をコンパイルする
RUN $RBENV_ROOT/src/configure
RUN make -C $RBENV_ROOT/src

# rbenvの確認
RUN curl -fsSL https://github.com/rbenv/rbenv-installer/raw/master/bin/rbenv-doctor | bash

# rubyインストール
RUN rbenv install $RUBY_VERSION
RUN rbenv rehash
RUN rbenv global $RUBY_VERSION

# bundlerをインストール
RUN gem install bundler

# bundlerのための権限変更
RUN chown -R dev:dev /usr/local/rbenv

# アプリケーションソースコードのルートディレクトリへ移動
WORKDIR $APP_ROOT

# entrypointのための処理
COPY script/entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]

USER dev

# bundle install
COPY Gemfile* $APP_ROOT/
RUN bundle install
RUN rbenv rehash

EXPOSE 3000