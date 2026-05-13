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
ARG BASE_TAG=17.6.1.121

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

# Stage 2: copy extension files into supabase/postgres (Nix-based layout)
ARG BASE_TAG
FROM supabase/postgres:${BASE_TAG}

ARG PG_MAJOR

# supabase/postgres uses Nix with two separate store paths:
#   pg_config --pkglibdir  → lib-only derivation (NOT used by runtime)
#   postgres binary $libdir → postgresql-and-plugins derivation (USED by runtime)
# Extensions must go into the postgres binary's store path, not pg_config's.

COPY --from=builder /out/usr/lib/postgresql/${PG_MAJOR}/lib/ /tmp/pgvs-lib/
COPY --from=builder /out/usr/share/postgresql/${PG_MAJOR}/extension/ /tmp/pgvs-ext/

RUN PG_BIN=$(readlink -f /nix/var/nix/profiles/default/bin/postgres) \
    && PG_RUNTIME_LIBDIR="$(dirname "$(dirname "$PG_BIN")")/lib" \
    && PG_SHAREDIR="$(pg_config --sharedir)/extension" \
    && echo "Runtime libdir: $PG_RUNTIME_LIBDIR" \
    && echo "Share dir: $PG_SHAREDIR" \
    && cp /tmp/pgvs-lib/*.so "$PG_RUNTIME_LIBDIR/" \
    && cp /tmp/pgvs-ext/* "$PG_SHAREDIR/" \
    && rm -rf /tmp/pgvs-lib /tmp/pgvs-ext
