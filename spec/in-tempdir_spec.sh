#!/bin/sh
# shellcheck shell=sh disable=SC2155,SC3045

eval "$(shellspec - -c) exit 1"

Describe 'in_tempdir'
  create_dummy_file() {
    echo 'dummy' >"$@"
  }

  It 'runs the callee inside a fresh temporary directory, passes arguments, and cleans up on normal completion'
    # Given
    record_pwd_and_args() {
      # Writes current PWD and all args to externally provided files
      pwd >"${PWD_FILE}"
      printf '|%s|' "$@" >"${ARGS_FILE}"
    }

    readonly PWD_FILE="$(mktemp)"
    readonly ARGS_FILE="$(mktemp)"

    When call in_tempdir record_pwd_and_args one two three

    The status should be success
    The contents of file "${PWD_FILE}" should match pattern '*shellspec-*'
    The path "$(cat "${PWD_FILE}")" should start with "${TMPDIR:-/tmp}"
    The path "$(cat "${PWD_FILE}")" should not be exist
    The contents of file "${ARGS_FILE}" should equal "|one||two||three|"

    rm -f "${PWD_FILE}" "${ARGS_FILE}"
  End

  It 'does not change the original working directory (subshell isolation)'
    # Given
    readonly orig_pwd="${PWD}"
    readonly dummy_file='dummy-file'

    When call in_tempdir create_dummy_file "${dummy_file}"

    The status should be success
    The value "${PWD}" should equal "${orig_pwd}"
    The path "${orig_pwd}/${dummy_file}" should not be exist
  End

  It 'still cleans up when the callee fails (exit non-zero)'
    # Given
    record_pwd_then_fail() {
      pwd >"${PWD_FILE}"
      printf '%s\n' "failing callee" >&2
      exit 7
    }

    readonly PWD_FILE="$(mktemp)"

    When call in_tempdir record_pwd_then_fail

    The status should be failure
    used_dir="$(cat "${PWD_FILE}")"
    The path "${used_dir}" should not be exist
    The stderr should equal "failing callee"

    rm -f "${PWD_FILE}"
  End

  It 'mktemp failure surfaces an error and does no work'
    # Given
    readonly dummy_file="$(mktemp)"
    mktemp() {
      exit 1
    }

    When call in_tempdir create_dummy_file "${dummy_file}"

    The status should be failure
    The stderr should include "Failed to create temporary directory"
  End
End
