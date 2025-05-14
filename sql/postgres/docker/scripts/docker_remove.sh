#!/usr/bin/env bash

# SPDX-FileCopyrightText: © 2025 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

set -Eeu -o pipefail -o posix

while getopts ':d:y' opt; do
  case "${opt}" in
    d)
      base_dir="${OPTARG}"
      ;;
    y)
      yes='true'
      ;;
    ?)
      echo "Usage: $0 [-d <directory>] [-y]" >&2
      exit 1
      ;;
  esac
done

readonly base_dir="${base_dir:-$PWD}"
readonly yes="${yes:-false}"

readonly container_name='sdavids-database-playground-postgres'

readonly secrets_dir="${base_dir}/.docker/secrets"
readonly passwd_file="${secrets_dir}/etc-passwd"
readonly postgres_data_dir="${base_dir}/.docker/postgres-data"
readonly history_dir="${base_dir}/.docker/psql-history"

if [ -n "$(docker container ls --all --quiet --filter="name=^/${container_name}$")" ]; then
  docker container stop "${container_name}" >/dev/null
fi

# container not started with --rm ?
if [ -n "$(docker container ls --all --quiet --filter="name=^/${container_name}$")" ]; then
  docker container remove --force --volumes "${container_name}" >/dev/null
fi

readonly network_name='sdavids_database_playground_postgres'

if docker network inspect "${network_name}" >/dev/null 2>&1; then
  docker network rm "${network_name}" >/dev/null
fi

rm -rf "${history_dir}" "${passwd_file}"

if [ -d "${secrets_dir}" ] && [ -z "$(ls -A "${secrets_dir}")" ]; then
  rmdir "${secrets_dir}"
fi

if [ "${yes}" = 'false' ]; then
  printf "Do you want to irreversibly delete the Postgres data directory '%s' (Y/N)? " "${postgres_data_dir}"
  read -n 1 -r should_delete

  case "${should_delete}" in
    y | Y) printf '\n' ;;
    *)
      printf '\n'
      exit 0
      ;;
  esac
fi

rm -rf "${postgres_data_dir}"
