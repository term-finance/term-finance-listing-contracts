#!/usr/bin/env bash

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

set -o allexport
source "${script_dir}/.env" set
set +o allexport

export CERTORAKEY="${CERTORAKEY:?"CERTORAKEY is not set. Please set one in your .env file"}"
export SOLC_VERSION=0.8.18

usage="Usage: $0 <conf_file> <message>"

conf_file="${1?"${usage}"}"
msg="${2:-"$(hostname) - ${conf_file} - $(date +%s)"}"

set -eux -o pipefail

certoraRun "${conf_file}" --msg "${msg}" --wait_for_results all --rule_sanity basic
