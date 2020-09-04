FROM ruby:2.7.1-alpine

ENV LANG=ja_JP.UTF-8 \
    TZ=Asia/Tokyo \
    ROOT=/myapp \
    GEM_HOME=/bundle \
    BUNDLE_PATH=$GEM_HOME \
    BUNDLE_BIN=$BUNDLE_PATH/bin
ENV PATH /app/bin:$BUNDLE_BIN:$PATH


WORKDIR $ROOT

RUN apk update && \
    apk upgrade && \
    apk add --no-cache \
    gcc \
    g++ \
    libc-dev \
    libxml2-dev \
    linux-headers \
    make \
    nodejs \
    postgresql \
    postgresql-dev \
    tzdata \
    yarn && \
    apk add --virtual build-packs --no-cache \
    build-base \
    curl-dev

COPY Gemfile $ROOT
COPY Gemfile.lock $ROOT

RUN bundle install -j4
#　不要ファイル削除
RUN rm -rf /usr/local/bundle/cache/* /usr/local/share/.cache/* /var/cache/* /tmp/* && \
    apk del build-packs

COPY . $ROOT

# Add a script to be executed every time the container starts.
COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["sh", "/usr/bin/entrypoint.sh"]
EXPOSE 3000

# Start the main process.
CMD ["rails", "server", "-b", "0.0.0.0"]