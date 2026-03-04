# Unleashed PostgreSQL: supabase/postgres + pgvectorscale (DiskANN)
#
# pgvectorscale adds StreamingDiskANN + SBQ indexing for vectors >2000 dims.
# Pre-built .deb from https://github.com/timescale/pgvectorscale/releases
#
# Build:
#   docker build -t ghcr.io/thebtf/unleashed-postgresql:17-pgvectorscale .
#   docker push ghcr.io/thebtf/unleashed-postgresql:17-pgvectorscale
#
# Usage in SQL:
#   CREATE EXTENSION IF NOT EXISTS vectorscale CASCADE;
#   -- CASCADE auto-installs pgvector if not present

ARG BASE_TAG=17.6.1.087
FROM supabase/postgres:${BASE_TAG}

ARG PGVECTORSCALE_VERSION=0.9.0
ARG PG_MAJOR=17
ARG TARGETARCH=amd64

# Download and install pre-built pgvectorscale .deb
ADD https://github.com/timescale/pgvectorscale/releases/download/${PGVECTORSCALE_VERSION}/pgvectorscale-${PGVECTORSCALE_VERSION}-pg${PG_MAJOR}-${TARGETARCH}.zip /tmp/pgvectorscale.zip

RUN apt-get update \
    && apt-get install -y --no-install-recommends unzip \
    && cd /tmp \
    && unzip pgvectorscale.zip \
    && dpkg -i pgvectorscale-postgresql-${PG_MAJOR}_${PGVECTORSCALE_VERSION}-Linux_${TARGETARCH}.deb \
    && rm -rf /tmp/pgvectorscale* \
    && apt-get purge -y --auto-remove unzip \
    && rm -rf /var/lib/apt/lists/*
