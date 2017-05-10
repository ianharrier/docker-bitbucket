FROM alpine

MAINTAINER Ian Harrier <github@harrier.us>

#-------------------------------------------------------------------------------
#  OpenJDK
#-------------------------------------------------------------------------------

ENV JAVA_HOME=/usr/lib/jvm/default-jvm

RUN set -ex \
        && apk --no-cache add \
               openjdk8

#-------------------------------------------------------------------------------
#  gosu (https://github.com/tianon/gosu)
#-------------------------------------------------------------------------------

ARG GOSU_VERSION

RUN set -ex \
        && apk --no-cache add \
               curl \
        && curl --location --retry 3 \
               --output /usr/local/bin/gosu \
               https://github.com/tianon/gosu/releases/download/"${GOSU_VERSION}"/gosu-amd64 \
        && chmod +x /usr/local/bin/gosu \
        && gosu nobody true \
        && apk --no-cache del \
               curl

#-------------------------------------------------------------------------------
#  dumb-init (https://github.com/Yelp/dumb-init)
#-------------------------------------------------------------------------------

ARG DUMBINIT_VERSION

RUN set -ex \
        && apk --no-cache add \
               curl \
        && curl --location --retry 3 \
               --output /usr/local/bin/dumb-init \
               https://github.com/Yelp/dumb-init/releases/download/v"${DUMBINIT_VERSION}"/dumb-init_"${DUMBINIT_VERSION}"_amd64 \
        && chmod +x /usr/local/bin/dumb-init \
        && apk --no-cache del \
               curl

#-------------------------------------------------------------------------------
#  Bitbucket (https://www.atlassian.com/software/bitbucket/download)
#-------------------------------------------------------------------------------

ARG BITBUCKET_VERSION

ENV BITBUCKET_HOME=/var/atlassian/application-data/bitbucket
ENV BITBUCKET_INSTALL=/opt/atlassian/bitbucket
ENV RUN_USER=daemon
ENV RUN_GROUP=daemon

RUN set -ex \
        && apk --no-cache add \
               bash \
               curl \
               git \
               perl \
               procps \
               tar \
        && mkdir -p                           "${BITBUCKET_INSTALL}" \
        && curl --location --retry 3 \
               https://www.atlassian.com/software/stash/downloads/binary/atlassian-bitbucket-"${BITBUCKET_VERSION}".tar.gz \
             | tar -xz --directory "${BITBUCKET_INSTALL}" --strip-components=1 --no-same-owner \
        && chmod -R u=rwx,go-rwx              "${BITBUCKET_INSTALL}" \
        && chown -R ${RUN_USER}:${RUN_GROUP}  "${BITBUCKET_INSTALL}" \
        && mkdir -p                           "${BITBUCKET_HOME}" \
        && chown -R ${RUN_USER}:${RUN_GROUP}  "${BITBUCKET_HOME}" \
        && chmod -R u=rwx,go-rwx              "${BITBUCKET_HOME}" \
        && apk --no-cache del \
               curl \
               tar

EXPOSE 7990 7999

VOLUME ["${BITBUCKET_HOME}"]

WORKDIR ${BITBUCKET_INSTALL}

#-------------------------------------------------------------------------------
#  Scripts
#-------------------------------------------------------------------------------

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint

RUN set -ex \
        && chmod +x /usr/local/bin/docker-entrypoint \
        && apk --no-cache add \
               tzdata

CMD ["docker-entrypoint"]

ENTRYPOINT ["dumb-init"]
