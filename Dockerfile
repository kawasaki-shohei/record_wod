FROM ruby:2.6.6

ENV APP_PATH /usr/src/record_wod
ENV LANG C.UTF-8

RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN apt-get update -qq && apt-get install -y --no-install-recommends build-essential libpq-dev vim postgresql-client yarn \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
RUN yarn global add n && n 12.13.0

# chromeをインストール
#RUN curl https://intoli.com/install-google-chrome.sh | bash

# chromedriverをインストール
# バージョン一覧 https://chromedriver.storage.googleapis.com/index.html
#RUN CHROME_DRIVER_VERSION=`curl -sS chromedriver.storage.googleapis.com/LATEST_RELEASE` && \
#    curl -O -L http://chromedriver.storage.googleapis.com/${CHROME_DRIVER_VERSION}/chromedriver_linux64.zip
#RUN unzip chromedriver_linux64.zip
#RUN rm chromedriver_linux64.zip
#RUN sudo mv chromedriver /usr/local/bin

COPY script/entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]

# bashの設定
COPY .bashrc /root/.bashrc

RUN mkdir ${APP_PATH}
WORKDIR ${APP_PATH}

COPY Gemfile ${APP_PATH}/Gemfile
COPY Gemfile.lock ${APP_PATH}/Gemfile.lock
RUN gem install bundler -v '2.2.7'
RUN bundle install

COPY package.json ${APP_PATH}/package.json
COPY yarn.lock ${APP_PATH}/yarn.lock
RUN yarn install --check-files