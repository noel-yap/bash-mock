#!/bin/bash
# shellcheck shell=bash

eval "$(shellspec - -c) exit 1"

Describe '@inject'

  # Source the library under test
  setup_lib() {
    # shellcheck source=../bash-inject.shlib
    . "${PROJECT_ROOT_DIR}/bash-inject.shlib"
  }

  It 'creates a wrapper that delegates to the executable and propagates its exit status'
    # Given
    arrange_then_invoke() {
      setup_lib

      # Create a temporary executable script (without heredoc)
      local -r script_path="${PWD}/mycmd.v1.sh"
      {
        echo '#!/bin/bash'
        echo 'printf "ran:"'
        echo 'printf "«%s»" "$@"'
        # shellcheck disable=SC2028
        echo 'printf "\n"'
        echo 'exit 5'
      } >"${script_path}"
      chmod +x "${script_path}"

      # Inject: should define function named "mycmd"
      @inject "${script_path}"

      # Call the injected function and capture output and status
      local out
      out="$(mycmd "a b" c d:e --flag x=y 2>&1)"
      local -r rc=$?
      readonly out
      printf '%s\n%s\n' "${out}" "${rc}"
    }

    When call in_tempdir arrange_then_invoke
    The status should be success
    The line 1 of stdout should equal 'ran:«a b»«c»«d:e»«--flag»«x=y»'
    The line 2 of stdout should equal '5'
    The lines of stdout should equal 2
  End

  It 'does not override when a function of the same name already exists'
    # Given
    predef_then_inject() {
      setup_lib

      # Predefine function 'tool' that should take precedence
      function tool() {
        echo "mocked:$1"
      }

      # Create a real executable that would say 'real' if called
      local -r real_path="${PWD}/tool.sh"
      {
        echo '#!/bin/bash'
        # shellcheck disable=SC2016
        echo 'echo "real:$1"'
        echo 'exit 9'
      } > "${real_path}"
      chmod +x "${real_path}"

      # Inject using the real executable; since 'tool' exists, it must not be overridden
      @inject "${real_path}"

      local o1
      o1="$(tool X 2>&1)"
      local -r r1=$?
      readonly o1
      printf '%s\n%s\n' "${o1}" "${r1}"
    }

    When call in_tempdir predef_then_inject
    The status should be success
    The line 1 of stdout should equal 'mocked:X'
    The line 2 of stdout should equal '0'
    The lines of stdout should equal 2
  End

  It 'derives the function name from the executable path’s basename (strip from first dot)'
    # Given
    basename_test() {
      setup_lib

      # Create an executable with dots in its filename; function name should strip from first dot
      local -r exec_path="${PWD}/prog.v1.2.sh"
      {
        echo '#!/bin/bash'
        echo 'echo ok'
      } >"${exec_path}"
      chmod +x "${exec_path}"

      # Inject and call the derived function name 'prog'
      @inject "${exec_path}"
      local output
      output="$(prog 2>&1)"
      local -r code=$?
      readonly output

      printf '%s\n%s\n' "${output}" "${code}"
    }

    When call in_tempdir basename_test
    The status should be success
    The line 1 of stdout should equal 'ok'
    The line 2 of stdout should equal '0'
    The lines of stdout should equal 2
  End

  It 'replaces spaces in basename with underscores to form a valid function name'
    # Given
    spaces_in_name_test() {
      setup_lib

      # Create an executable whose basename contains spaces
      local -r exec_path="${PWD}/Google Chrome"
      {
        echo '#!/bin/bash'
        echo 'echo chrome-ran'
      } >"${exec_path}"
      chmod +x "${exec_path}"

      # Inject: should define function named "Google_Chrome"
      @inject "${exec_path}"
      local output
      output="$(Google_Chrome 2>&1)"
      local -r code=$?
      readonly output

      printf '%s\n%s\n' "${output}" "${code}"
    }

    When call in_tempdir spaces_in_name_test
    The status should be success
    The line 1 of stdout should equal 'chrome-ran'
    The line 2 of stdout should equal '0'
    The lines of stdout should equal 2
  End

End
