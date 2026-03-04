# supabase/postgres + pgvectorscale (DiskANN)
#
# pgvectorscale adds StreamingDiskANN + SBQ indexing for vectors >2000 dims.
# Pre-built .deb from https://github.com/timescale/pgvectorscale/releases
#
# Usage in SQL:
#   CREATE EXTENSION IF NOT EXISTS vectorscale CASCADE;
#   -- CASCADE auto-installs pgvector if not present

ARG PGVECTORSCALE_VERSION=0.9.0
ARG PG_MAJOR=17

# Stage 1: extract .deb contents using a standard Debian image
FROM debian:bookworm-slim AS builder

ARG PGVECTORSCALE_VERSION
ARG PG_MAJOR

ADD https://github.com/timescale/pgvectorscale/releases/download/${PGVECTORSCALE_VERSION}/pgvectorscale-${PGVECTORSCALE_VERSION}-pg${PG_MAJOR}-amd64.zip /tmp/pgvectorscale.zip

RUN apt-get update \
    && apt-get install -y --no-install-recommends unzip \
    && cd /tmp \
    && unzip pgvectorscale.zip \
    && mkdir -p /out \
    && dpkg-deb -x pgvectorscale-postgresql-${PG_MAJOR}_${PGVECTORSCALE_VERSION}-Linux_amd64.deb /out \
    && rm -rf /tmp/pgvectorscale*

# Stage 2: copy extension files into supabase/postgres
ARG BASE_TAG=17.6.1.087
FROM supabase/postgres:${BASE_TAG}

COPY --from=builder /out/usr/lib/postgresql/ /usr/lib/postgresql/
COPY --from=builder /out/usr/share/postgresql/ /usr/share/postgresql/
