#!/bin/bash
# shellcheck shell=bash

eval "$(shellspec - -c) exit 1"

Describe '@mock'

  # Source the library under test
  setup_lib() {
    # shellcheck source=../bash-mock.shlib
    . "${PROJECT_ROOT_DIR}/bash-mock.shlib"
  }

  It 'defines a mock function that delegates to suffixed implementations in order'
    # Given
    arrange_then_invoke() {
      setup_lib

      # Create the base mock for a dependency named "dep"
      @mock dep

      # Define the first implementation dep@0
      function dep@0() {
        echo "first:$1"
      }
      export -f dep@0

      # Define the second implementation dep@1
      function dep@1() {
        echo "second:$1"
        return 7
      }
      export -f dep@1

      # Call twice and print outputs and return codes
      local out1
      out1="$(dep argA 2>&1)"
      local -r rc1=$?
      readonly out1

      local out2
      out2="$(dep argB 2>&1)"
      local -r rc2=$?
      readonly out2

      printf '%s\n' "${out1}" "${rc1}" "${out2}" "${rc2}"
    }

    When call in_tempdir arrange_then_invoke
    The status should be success
    The line 1 of stdout should equal 'first:argA'
    The line 2 of stdout should equal '0'
    The line 3 of stdout should equal 'second:argB'
    The line 4 of stdout should equal '7'
    The lines of stdout should equal 4
  End

  It 'exports the mock so it is callable from a subshell and increments counter across subshell calls'
    # Given
    call_from_subshells() {
      setup_lib

      @mock task

      function task@0() {
        echo sub1
      }
      export -f task@0

      function task@1() {
        echo sub2;
      }
      export -f task@1

      # Call from subshells (to ensure export works and counter is persisted via file)
      local -r o1="$( ( task ) 2>&1 )"
      local -r r1=$?
      local -r o2="$( ( task ) 2>&1 )"
      local -r r2=$?

      printf '%s\n' "${o1}" "${r1}" "${o2}" "${r2}"
    }

    When call in_tempdir call_from_subshells
    The status should be success
    The line 1 of stdout should equal 'sub1'
    The line 2 of stdout should equal '0'
    The line 3 of stdout should equal 'sub2'
    The line 4 of stdout should equal '0'
    The lines of stdout should equal 4
  End

  It 'passes through all arguments intact to the implementation'
    # Given
    pass_args() {
      setup_lib
      @mock run

      function run@0() {
        printf "args:"
        printf "«%s»" "$@"
        printf "\n"
      }
      export -f run@0

      run "a b" "c" "d:e" "--flag" "x=y"
    }

    When call in_tempdir pass_args
    The status should be success
    The output should equal 'args:«a b»«c»«d:e»«--flag»«x=y»'
  End

End
