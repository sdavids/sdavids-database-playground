#!/usr/bin/env sh

# SPDX-FileCopyrightText: © 2025 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

set -eu

while getopts ':d:i:p:' opt; do
  case "${opt}" in
    d)
      base_dir="${OPTARG}"
      ;;
    i)
      init_db_dir="${OPTARG}"
      ;;
    p)
      postgres_port="${OPTARG}"
      ;;
    ?)
      echo "Usage: $0 [-d <base directory>] [-i <initdb directory>] [-p <port>]" >&2
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
readonly postgres_port="${postgres_port:-5432}"

init_db_dir="${init_db_dir:-${base_dir}/initdb}"

readonly tag='local'

# https://docs.docker.com/reference/cli/docker/image/tag/#description
readonly namespace='de.sdavids'
readonly repository='sdavids-database-playground'

readonly label_group='de.sdavids.docker.group'

readonly label="${label_group}=${repository}"

readonly image_name="${namespace}/${repository}-postgres"

readonly container_name='sdavids-database-playground-postgres'

readonly host_name='localhost'

readonly network_name='sdavids_database_playground_postgres'

umask 077

secrets_dir="${base_dir}/.docker/secrets"
if [ ! -d "${secrets_dir}" ]; then
  printf "secrets directory '%s' does not exist\n" "${secrets_dir}" >&2
  exit 2
fi

if [ ! -d "${init_db_dir}" ]; then
  printf "initdb directory '%s' does not exist\n" "${init_db_dir}" >&2
  exit 3
fi

passwd_file="${base_dir}/.docker/secrets/etc-passwd"
postgres_data_dir="${base_dir}/.docker/postgres-data"

mkdir -p "${postgres_data_dir}"

# non-root user needs an entry in /etc/passwd
docker container run \
  --rm \
  --security-opt='no-new-privileges=true' \
  --cap-drop=all \
  --network=none \
  --label "${label}" \
  "${image_name}:${tag}" cat /etc/passwd >"${passwd_file}"

echo "$(whoami):x:$(id -u):$(id -g):postgres:/nonexistent:/usr/bin/false" >>"${passwd_file}"

# https://github.com/devcontainers/features/tree/main/src/docker-outside-of-docker#1-use-the-localworkspacefolder-as-environment-variable-in-your-code
if [ -n "${LOCAL_WORKSPACE_FOLDER+x}" ]; then
  secrets_dir="${LOCAL_WORKSPACE_FOLDER}/.docker/secrets"
  init_db_dir="${LOCAL_WORKSPACE_FOLDER}/initdb"
  passwd_file="${LOCAL_WORKSPACE_FOLDER}/.docker/secrets/passwd"
  postgres_data_dir="${LOCAL_WORKSPACE_FOLDER}/.docker/postgres-data"
else
  secrets_dir="$(realpath "${secrets_dir}")"
  init_db_dir="$(realpath "${init_db_dir}")"
  passwd_file="$(realpath "${passwd_file}")"
  postgres_data_dir="$(realpath "${postgres_data_dir}")"
fi
readonly secrets_dir
readonly init_db_dir
readonly passwd_file
readonly postgres_data_dir

if [ -n "$(docker ps --all --filter name="${container_name}" --filter status=exited --format '{{.Status}}')" ] \
  && [ -d "${postgres_data_dir}" ]; then
  docker container start "${container_name}" >/dev/null
else
  docker network inspect "${network_name}" >/dev/null 2>&1 \
    || docker network create \
      --driver bridge "${network_name}" \
      --label "${label_group}=${namespace}" >/dev/null

  # to ensure ${label} is set, we use --label "${label}"
  # which might overwrite the label ${label_group} of the image
  #
  # https://hub.docker.com/_/postgres
  docker container run \
    --detach \
    --env POSTGRES_USER_FILE=/run/secrets/postgres-superuser \
    --env POSTGRES_PASSWORD_FILE=/run/secrets/postgres-superuser-pw \
    --env POSTGRES_DB=postgres \
    --security-opt='no-new-privileges=true' \
    --cap-drop=all \
    --user "$(id -u):$(id -g)" \
    --network="${network_name}" \
    --publish "${postgres_port}:5432" \
    --mount "type=bind,source=${secrets_dir},target=/run/secrets,readonly" \
    --mount "type=bind,source=${passwd_file},target=/etc/passwd,readonly" \
    --mount "type=bind,source=${init_db_dir},target=/docker-entrypoint-initdb.d,readonly" \
    --mount "type=bind,source=${postgres_data_dir},target=/var/lib/postgresql/data" \
    --name "${container_name}" \
    --label "${label}" \
    "${image_name}:${tag}" >/dev/null
fi

readonly url="${host_name}:${postgres_port}"

printf '\nListen local: %s\n' "${url}"
