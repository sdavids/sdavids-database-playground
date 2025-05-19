#!/usr/bin/env sh

# SPDX-FileCopyrightText: © 2024 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

set -eu

while getopts ':d:fs:' opt; do
  case "${opt}" in
    d)
      base_dir="${OPTARG}"
      ;;
    f)
      force='true'
      ;;
    s)
      superuser="${OPTARG}"
      ;;
    ?)
      echo "Usage: $0 [-d <directory>] [-f] [-s <superuser>]" >&2
      exit 1
      ;;
  esac
done

readonly base_dir="${base_dir:-$PWD/.docker}"
readonly force="${force:-false}"

superuser="${superuser:-}"

readonly secrets_dir="${base_dir}/secrets"

umask 077

mkdir -p "${secrets_dir}"

readonly superuser_file="${secrets_dir}/postgres-superuser"

if [ "${force}" = 'false' ] && [ -f "${superuser_file}" ]; then
  printf "'%s' has already been executed.\n" "$0" >&2
  exit 2
fi

export LC_ALL=C

create_password_file() {
  printf '%s' "$(
    tr -dc A-Za-z0-9 </dev/urandom | head -c 20
    echo
  )" >"${secrets_dir}/$1"
}

if [ -z "${superuser}" ]; then
  # shellcheck disable=SC2018
  superuser="$(
    tr -dc a-z </dev/urandom | head -c 6
    echo
  )"
fi
readonly superuser

printf '%s' "${superuser}" >"${superuser_file}"

create_password_file 'postgres-superuser-pw'
create_password_file 'sd-admin-pw'
create_password_file 'sd-example-ow-pw'
create_password_file 'sd-example-rw-pw'
create_password_file 'sd-example-ro-pw'

printf '\nPostgres superuser: %s\n' "${superuser}"
