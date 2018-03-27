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

ARG BUILD_DATE="1970-01-01T00:00:00Z"
ARG VERSION="1.0.0"
ARG VCS_URL="http://localhost/"
ARG VCS_REF="master"
LABEL org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.name="Container-Notify" \
    org.label-schema.description="Signal docker containers upon filesystem changes." \
    org.label-schema.url="https://github.com/UiP9AV6Y/container-notify" \
    org.label-schema.vcs-url=$VCS_URL \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vendor="Gordon Bleux" \
    org.label-schema.version=$VERSION \
    org.label-schema.schema-version="1.0" \
    com.microscaling.docker.dockerfile="/Dockerfile" \
    com.microscaling.license="MIT"
