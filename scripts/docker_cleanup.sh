#!/usr/bin/env sh

# SPDX-FileCopyrightText: © 2025 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

set -eu

# https://docs.docker.com/reference/cli/docker/image/tag/#description
readonly namespace='de.sdavids'
readonly repository='sdavids-database-playground'

readonly label_group='de.sdavids.docker.group'

readonly label="${label_group}=${repository}"

docker container prune --force --filter="label=${label}"

docker volume prune --force --filter="label=${label}"

docker image prune --force --filter="label=${label}" --all

docker network prune --force --filter="label=${label_group}=${namespace}"
