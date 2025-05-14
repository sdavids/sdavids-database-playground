# syntax=docker/dockerfile:1
# check=error=true

# SPDX-FileCopyrightText: © 2025 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

# https://docs.docker.com/engine/reference/builder/

# https://hub.docker.com/_/postgres
FROM postgres:17.5-bookworm

RUN localedef -i de_DE -c -f UTF-8 -A /usr/share/locale/locale.alias de_DE.UTF-8

HEALTHCHECK --interval=5s --timeout=5s --start-period=5s \
    CMD psql -U "$(cat $POSTGRES_USER_FILE)" -d "${POSTGRES_DB}" -c ''SELECT 1'' || exit 1

# https://github.com/opencontainers/image-spec/blob/master/annotations.md
LABEL org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.vendor="Sebastian Davids" \
      org.opencontainers.image.title="sdavids-database-playground-postgres" \
      de.sdavids.docker.group="sdavids-database-playground" \
      de.sdavids.docker.type="production"
