FROM alpine:3.7

COPY . /src
RUN set -xe; \
  apk add --no-cache \
    ruby \
    ruby-json \
  && apk add --no-cache --virtual .builddeps \
    ruby-bundler \
    build-base \
    ruby-dev \
    git \
  && cd /src \
  && bundler install \
  && bundler exec rake build \
  && gem install --no-document \
    pkg/*.gem \
  && mv docker-entrypoint.sh /usr/local/bin/ \
  && cd / \
  && rm -rf /src \
  && apk del .builddeps

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD [ "container-notify" ]
