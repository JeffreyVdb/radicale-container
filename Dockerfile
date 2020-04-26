FROM docker.io/library/python:3.8.2-alpine AS base

ENV PYTHONFAULTHANDLER=1 \
    PYTHONHASHSEED=random \
    PYTHONUNBUFFERED=1

FROM base AS builder

# Install deps
RUN set -xe \
    && apk --no-cache add build-base libffi-dev ca-certificates openssl

ARG RADICALE_VER=2.1.11

# Build radicale
RUN set -xe \
    && wget --quiet https://github.com/Kozea/Radicale/archive/${RADICALE_VER}.tar.gz -O radicale.tar.gz \
    && tar xzf radicale.tar.gz \
    && python -m venv /venv \
    && . /venv/bin/activate \
    && pip3 install ./Radicale-${RADICALE_VER}[md5,bcrypt] \
    && rm -r radicale.tar.gz Radicale-${RADICALE_VER}

FROM base AS final

ARG VCS_REF='HEAD'
ARG BUILD_DATE

ARG UID=1000
ARG GID=1000

LABEL maintainer="Jeffrey Vandenborne <jeffrey@vandenborne.co>" \
    org.opencontainers.image.source="https://github.com/JeffreyVdb/radicale-container" \
    org.opencontainers.image.title="Production tuned container for radicale Open-Source CalDAV and CardDAV Server" \
    org.opencontainers.image.revision="${VCS_REF}" \
    org.opencontainers.image.created="${BUILD_DATE}"

COPY --from=builder /venv /venv

RUN set -xe \
    && /venv/bin/pip3 install gunicorn \
    && addgroup -g $GID radicale \
    && adduser -D -s /bin/false -H -u $UID -G radicale radicale \
    && mkdir -p /var/lib/radicale /etc/radicale \
    && chmod 770 /var/lib/radicale \
    && chown radicale:radicale /var/lib/radicale

VOLUME /var/lib/radicale /etc/radicale
EXPOSE 5232

COPY ./container-entrypoint.sh /radicale-entrypoint

USER radicale:radicale
ENTRYPOINT [ "/radicale-entrypoint" ]