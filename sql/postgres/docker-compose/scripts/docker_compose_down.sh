#!/usr/bin/env sh

# SPDX-FileCopyrightText: © 2025 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

set -eu

while getopts ':v' opt; do
  case "${opt}" in
    v)
      volumes=' --volumes'
      ;;
    ?)
      echo "Usage: $0 [-v]" >&2
      exit 1
      ;;
  esac
done

readonly volumes="${volumes:-}"

# https://docs.docker.com/reference/cli/docker/compose/down/
# shellcheck disable=SC2086
docker compose --profile '*' down --remove-orphans${volumes}
