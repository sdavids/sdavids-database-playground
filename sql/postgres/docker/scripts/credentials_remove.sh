#!/usr/bin/env sh

# SPDX-FileCopyrightText: © 2024 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

set -eu

while getopts ':d:' opt; do
  case "${opt}" in
    d)
      base_dir="${OPTARG}"
      ;;
    ?)
      echo "Usage: $0 [-d <directory>]" >&2
      exit 1
      ;;
  esac
done

readonly base_dir="${base_dir:-$PWD/.docker}"

readonly secrets_dir="${base_dir}/secrets"

rm -f "${secrets_dir}/postgres-superuser" \
  "${secrets_dir}/postgres-superuser-pw" \
  "${secrets_dir}/sd-admin-pw" \
  "${secrets_dir}/sd-example-ow-pw" \
  "${secrets_dir}/sd-example-rw-pw" \
  "${secrets_dir}/sd-example-ro-pw"

if [ -d "${secrets_dir}" ] && [ -z "$(ls -A "${secrets_dir}")" ]; then
  rmdir "${secrets_dir}"
fi
