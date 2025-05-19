#!/usr/bin/env sh

# SPDX-FileCopyrightText: © 2025 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

set -eu

# https://docs.docker.com/reference/cli/docker/compose/stop/
docker compose --profile '*' stop
