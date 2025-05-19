#!/usr/bin/env sh

# SPDX-FileCopyrightText: © 2025 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

set -eu

readonly db_name="${POSTGRES_DB:-postgres}"

if [ -n "${POSTGRES_USER_FILE+x}" ]; then
  if [ ! -f "${POSTGRES_USER_FILE}" ]; then
    printf "superuser file '%s' does not exist\n" "${POSTGRES_USER_FILE}" >&2
    exit 1
  fi
  postgres_user="$(cat "${POSTGRES_USER_FILE}")"
  if [ -z "${postgres_user}" ]; then
    printf "superuser file '%s' is empty\n" "${POSTGRES_USER_FILE}" >&2
    exit 2
  fi
elif [ -n "${POSTGRES_USER+x}" ]; then
  postgres_user="${POSTGRES_USER}"
  if [ -z "${postgres_user}" ]; then
    printf "\$POSTGRES_USER is empty\n" >&2
    exit 3
  fi
else
  printf "either POSTGRES_USER_FILE or POSTGRES_USER needs to be set in the environment\n" >&2
  exit 4
fi
readonly postgres_user

psql \
  --set ON_ERROR_STOP=1 \
  --set=ad_pw="$( cat /run/secrets/sd-admin-pw )" \
  --set=ow_pw="$( cat /run/secrets/sd-example-ow-pw )" \
  --set=rw_pw="$( cat /run/secrets/sd-example-rw-pw )" \
  --set=ro_pw="$( cat /run/secrets/sd-example-ro-pw )" \
  --username "${postgres_user}" \
  --dbname "${db_name}" \
  --file /docker-entrypoint-initdb.d/init.psql
