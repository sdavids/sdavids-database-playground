# SPDX-FileCopyrightText: © 2025 Sebastian Davids <sdavids@gmx.de>
# SPDX-License-Identifier: Apache-2.0

# https://docs.docker.com/build/bake/reference/
# https://developer.hashicorp.com/terraform/language

variable "TAG" {
  type     = string
  nullable = false
  default  = "local"
}

variable "GIT_COMMIT_ID" {
  type     = string
  nullable = false
  default  = "N/A"
}

variable "BUILD_TIME" {
  type     = string
  nullable = false
  default  = timestamp()
}

group "default" {
  targets = ["postgres"]
}

target "postgres" {
  context = "./postgres"
  tags = [
    "de.sdavids/sdavids-database-playground-postgres:latest",
    "de.sdavids/sdavids-database-playground-postgres:${TAG}",
  ]
  labels = {
    "de.sdavids.docker.group" = "sdavids-database-playground"
    "org.opencontainers.image.revision" = "${GIT_COMMIT_ID}"
    "org.opencontainers.image.created" = "${BUILD_TIME}"
  }
}
