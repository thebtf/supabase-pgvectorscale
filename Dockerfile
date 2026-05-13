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

# supabase/postgres uses Nix — extensions must land in Nix paths, not /usr/lib.
# .so  → pg_config --pkglibdir
# .sql/.control → pg_config --sharedir + /extension/
RUN PG_LIBDIR=$(pg_config --pkglibdir) \
    && PG_SHAREDIR=$(pg_config --sharedir)/extension \
    && echo "PG_LIBDIR=$PG_LIBDIR" > /tmp/pg_paths \
    && echo "PG_SHAREDIR=$PG_SHAREDIR" >> /tmp/pg_paths

COPY --from=builder /out/usr/lib/postgresql/${PG_MAJOR}/lib/ /tmp/pgvs-lib/
COPY --from=builder /out/usr/share/postgresql/${PG_MAJOR}/extension/ /tmp/pgvs-ext/

RUN . /tmp/pg_paths \
    && cp /tmp/pgvs-lib/*.so "$PG_LIBDIR/" \
    && cp /tmp/pgvs-ext/* "$PG_SHAREDIR/" \
    && rm -rf /tmp/pgvs-lib /tmp/pgvs-ext /tmp/pg_paths
