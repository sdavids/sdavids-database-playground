#!/usr/bin/env sh

# SPDX-FileCopyrightText: © 2025 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

set -eu

while getopts ':u:' opt; do
  case "${opt}" in
    u)
      user="${OPTARG}"
      ;;
    ?)
      echo "Usage: $0 [-u <user>] <service>" >&2
      exit 1
      ;;
  esac
done
shift $((OPTIND - 1))

if [ -z "${1+x}" ]; then
  echo "Usage: $0 [-u <user>] <service>" >&2
  exit 2
fi

readonly service="$1"

if [ -n "${user+x}" ]; then
  user=" --user ${user}"
else
  user=''
fi
readonly user

# https://docs.docker.com/reference/cli/docker/compose/down/
# shellcheck disable=SC2086
docker compose exec${user} "${service}" sh
