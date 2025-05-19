#!/usr/bin/env sh

# SPDX-FileCopyrightText: © 2025 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

set -eu

services="$*"
if [ -z "${services}" ]; then
  services='postgres'
fi
readonly services

# https://docs.docker.com/reference/cli/docker/compose/logs/
# shellcheck disable=SC2086
docker-compose logs --follow --tail --timestamps ${services}
