#!/usr/bin/env sh

# SPDX-FileCopyrightText: © 2025 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

set -eu

while getopts ':d:f:n:u:' opt; do
  case "${opt}" in
    d)
      base_dir="${OPTARG}"
      ;;
    n)
      db_name="${OPTARG}"
      ;;
    f)
      format="${OPTARG}"
      ;;
    u)
      postgres_user="${OPTARG}"
      ;;
    ?)
      echo "Usage: $0 [-d <directory>] [-f <format>] [-n <database>] [-u <postgres_user>]" >&2
      exit 1
      ;;
  esac
done

# https://stackoverflow.com/a/3915420
# https://stackoverflow.com/questions/3915040/how-to-obtain-the-absolute-path-of-a-file-via-shell-bash-zsh-sh#comment100267041_3915420
command -v realpath >/dev/null 2>&1 || realpath() {
  if [ -h "$1" ]; then
    # shellcheck disable=SC2012
    ls -ld "$1" | awk '{ print $11 }'
  else
    echo "$(
      cd "$(dirname -- "$1")" >/dev/null
      pwd -P
    )/$(basename -- "$1")"
  fi
}

readonly base_dir="${base_dir:-$PWD}"
readonly db_name="${db_name:-sd_example}"
readonly format="${format:-custom}"

secrets_dir="${base_dir}/.docker/secrets"

if [ ! -d "${secrets_dir}" ]; then
  printf "secrets directory '%s' does not exist\n" "${secrets_dir}" >&2
  exit 1
fi

# https://github.com/devcontainers/features/tree/main/src/docker-outside-of-docker#1-use-the-localworkspacefolder-as-environment-variable-in-your-code
if [ -n "${LOCAL_WORKSPACE_FOLDER+x}" ]; then
  secrets_dir="${LOCAL_WORKSPACE_FOLDER}/.docker/secrets"
fi
readonly secrets_dir

if [ -z "${postgres_user+x}" ]; then
  postgres_user_file="${secrets_dir}/postgres-superuser"

  if [ ! -f "${postgres_user_file}" ]; then
    printf "superuser file '%s' does not exist\n" "${postgres_user_file}" >&2
    exit 2
  fi

  postgres_user="$(cat "${postgres_user_file}")"

  if [ -z "${postgres_user}" ]; then
    printf "superuser file '%s' is empty\n" "${postgres_user_file}" >&2
    exit 3
  fi
fi
readonly postgres_user

readonly tag='local'

# https://docs.docker.com/reference/cli/docker/image/tag/#description
readonly namespace='de.sdavids'
readonly repository='sdavids-database-playground'

readonly image_name="${namespace}/${repository}-postgres"

readonly network_name='sdavids_database_playground_postgres_db'

dumps_dir="$(realpath "${base_dir}/.docker/dumps")"

mkdir -p "${dumps_dir}"

# https://github.com/devcontainers/features/tree/main/src/docker-outside-of-docker#1-use-the-localworkspacefolder-as-environment-variable-in-your-code
if [ -n "${LOCAL_WORKSPACE_FOLDER+x}" ]; then
  dumps_dir="${LOCAL_WORKSPACE_FOLDER}/.docker/dumps"
fi
readonly dumps_dir

dump_file="/run/dumps/dump_$(date +%Y-%m-%d-%H-%M-%S).sql"
readonly dump_file

# https://www.postgresql.org/docs/current/app-pgdump.html
# https://man7.org/linux/man-pages/man7/capabilities.7.html
# https://docs.docker.com/desktop/features/networking/#i-want-to-connect-from-a-container-to-a-service-on-the-host
docker container run \
  --interactive \
  --tty \
  --rm \
  --read-only \
  --security-opt='no-new-privileges=true' \
  --cap-drop=all \
  --mount "type=bind,source=${dumps_dir},target=/run/dumps" \
  --network "${network_name}" \
  "${image_name}:${tag}" \
  pg_dump \
  --host=host.docker.internal \
  --username="${postgres_user}" \
  --dbname="${db_name}" \
  --format="${format}" \
  --file="${dump_file}"
