#!/usr/bin/env sh

# SPDX-FileCopyrightText: © 2025 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

set -eu

while getopts ':dnt:' opt; do
  case "${opt}" in
    d)
      daemon=' --detach'
      ;;
    n)
      no_cache=' --pull --no-cache'
      ;;
    t)
      tag="${OPTARG}"
      ;;
    ?)
      echo "Usage: $0 [-d] [-n] [-t tag]" >&2
      exit 1
      ;;
  esac
done

readonly daemon="${daemon:-}"
readonly no_cache="${no_cache:-}"

readonly tag="${tag:-local}"

# https://reproducible-builds.org/docs/source-date-epoch/
if [ -z "${SOURCE_DATE_EPOCH+x}" ]; then
  if [ -z "$(git status --porcelain=v1 2>/dev/null)" ]; then
    SOURCE_DATE_EPOCH="$(git log --max-count=1 --pretty=format:%ct)"
  else
    SOURCE_DATE_EPOCH="$(date +%s)"
  fi
  export SOURCE_DATE_EPOCH
fi

if [ "$(uname)" = 'Darwin' ]; then
  created_at="$(date -r "${SOURCE_DATE_EPOCH}" -Iseconds -u | sed -e 's/+00:00$/Z/')"
else
  created_at="$(date -d "@${SOURCE_DATE_EPOCH}" -Iseconds -u | sed -e 's/+00:00$/Z/')"
fi
readonly created_at

if [ -n "${GITHUB_SHA+x}" ]; then
  # https://docs.github.com/en/actions/learn-github-actions/variables#default-environment-variables
  commit="${GITHUB_SHA}"
elif [ "$(git rev-parse --is-inside-work-tree 2>/dev/null)" != 'true' ]; then
  commit='N/A'
else
  if [ -z "$(git status --porcelain=v1 2>/dev/null)" ]; then
    ext=''
  else
    ext='-next'
  fi
  commit="$(git rev-parse --verify HEAD)${ext}"
  unset ext
fi
readonly commit

export TAG="${tag}"
export BUILD_TIME="${created_at}"
export GIT_COMMIT_ID="${commit}"

export COMPOSE_BAKE=true

# https://docs.docker.com/reference/cli/docker/compose/up/
# shellcheck disable=SC2086
docker compose --profile 'default' up${daemon}${no_cache}
