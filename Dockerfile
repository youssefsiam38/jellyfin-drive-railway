ARG OSTRM_IMAGE=hienao6/ostrm@sha256:87948a8857d4e43c17d93772a10f21760856ba9d6e6650846d8b8eced4d10c56
ARG JELLYFIN_IMAGE=jellyfin/jellyfin@sha256:baba630419915985442f315f08b0cf46d9f4c8a0cc4bd38e94a6d35751dd5ef5

FROM ${OSTRM_IMAGE} AS ostrm

FROM ${JELLYFIN_IMAGE}

ARG TARGETARCH
ARG OPENLIST_VERSION=v4.2.6

USER root

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        caddy \
        curl \
        openjdk-21-jre-headless \
        tini \
    && rm -rf /var/lib/apt/lists/*

RUN set -eux; \
    case "${TARGETARCH}" in \
      amd64) archive="openlist-linux-amd64.tar.gz"; checksum="2f2a5008efe45895292018479cb05556c83e828c3eed68a8b8cd3d35e82f03cb" ;; \
      arm64) archive="openlist-linux-arm64.tar.gz"; checksum="eed743a0c3b9d67eb3b58b3e5455957a15eb2f4e199c06309fabdbfb0b571904" ;; \
      *) echo "Unsupported architecture: ${TARGETARCH}" >&2; exit 1 ;; \
    esac; \
    mkdir -p /opt/openlist; \
    curl -fsSL "https://github.com/OpenListTeam/OpenList/releases/download/${OPENLIST_VERSION}/${archive}" -o /tmp/openlist.tar.gz; \
    echo "${checksum}  /tmp/openlist.tar.gz" | sha256sum -c -; \
    tar -xzf /tmp/openlist.tar.gz -C /opt/openlist; \
    chmod 0755 /opt/openlist/openlist; \
    rm /tmp/openlist.tar.gz

COPY --from=ostrm /app/openlisttostrm.jar /opt/ostrm/openlisttostrm.jar
COPY --from=ostrm /var/www/html /opt/ostrm/web
COPY Caddyfile /etc/caddy/Caddyfile
COPY scripts/start.sh /usr/local/bin/start-media-stack

RUN chmod 0755 /usr/local/bin/start-media-stack \
    && mkdir -p /data /opt/ostrm/web

ENV DATA_ROOT=/data \
    APP_DATA_PATH=/data/ostrm \
    APP_LOG_PATH=/data/ostrm/log \
    APP_DATABASE_PATH=/data/ostrm/db/openlist2strm.db \
    APP_CONFIG_PATH=/data/ostrm/config \
    APP_USER_INFO_PATH=/data/ostrm/config/userInfo.json \
    APP_FRONTEND_LOGS_PATH=/data/ostrm/log/frontend \
    APP_STRM_PATH=/data/media \
    JELLYFIN_DATA_DIR=/data/jellyfin \
    JELLYFIN_CACHE_DIR=/data/jellyfin-cache \
    JELLYFIN_CONFIG_DIR=/data/jellyfin/config \
    JELLYFIN_LOG_DIR=/data/jellyfin/log \
    JELLYFIN_WEB_DIR=/jellyfin/jellyfin-web \
    JELLYFIN_FFMPEG=/usr/lib/jellyfin-ffmpeg/ffmpeg \
    OPENLIST_SITE_URL=/openlist \
    SPRING_PROFILES_ACTIVE=prod \
    TZ=UTC \
    PORT=3000

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=90s --retries=3 \
  CMD curl --noproxy localhost -fsS http://127.0.0.1:${PORT}/healthz || exit 1

ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/start-media-stack"]
