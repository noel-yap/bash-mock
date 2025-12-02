#!/bin/bash
# shellcheck shell=bash

eval "$(shellspec - -c) exit 1"

Describe '@inject + @mock (integration)'

  # Source the libraries under test
  setup_libs() {
    # shellcheck source=../bash-inject.shlib
    . "${PROJECT_ROOT_DIR}/bash-inject.shlib"

    # shellcheck source=../bash-mock.shlib
    . "${PROJECT_ROOT_DIR}/bash-mock.shlib"
  }

  It 'uses @inject to create a function then @mock to intercept two calls in order'
    # Given
    arrange_then_invoke() {
      setup_libs

      # Real executable that would be called by the injected function if not mocked
      local -r exec_path="${PWD}/dep.sh"
      {
        echo '#!/bin/bash'
        # shellcheck disable=SC2016
        echo 'echo "real:$1"'
        echo 'exit 3'
      } >"${exec_path}"
      chmod +x "${exec_path}"

      # Create injected function named 'dep' from the executable
      @inject "${exec_path}"

      # Now mock the same function name; this should take precedence
      @mock dep

      function dep@0() {
        echo "mock1:$1"
      }
      export -f dep@0

      function dep@1() {
        echo "mock2:$1"
        return 6
      }
      export -f dep@1

      local o1
      o1="$(dep A 2>&1)"
      local -r r1=$?
      readonly o1

      local o2
      o2="$(dep B 2>&1)"
      local -r r2=$?
      readonly o2

      printf '%s\n' "${o1}" "${r1}" "${o2}" "${r2}"
    }

    When call in_tempdir arrange_then_invoke
    The status should be success
    The line 1 of stdout should equal 'mock1:A'
    The line 2 of stdout should equal '0'
    The line 3 of stdout should equal 'mock2:B'
    The line 4 of stdout should equal '6'
    The lines of stdout should equal 4
  End

End
