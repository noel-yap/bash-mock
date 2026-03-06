#!/bin/sh
# shellcheck shell=sh

eval "$(shellspec - -c) exit 1"

Describe 'mock_first_with_rest'

  It 'initializes index file and creates a mock executable'
    # Given
    execute_sut_then_output_results() {
      mock_first_with_rest dependency 'echo first; exit 0'

      printf 'index=%s\n' "$(cat .dependency.index)"
      ls dependency
    }

    When call in_tempdir execute_sut_then_output_results
    The status should be success
    The line 1 of stdout should equal 'index=0'
    The line 2 of stdout should equal 'dependency'
    The lines of stdout should equal 2
  End

  It 'preserves behaviors containing spaces (would break with word-splitting old impl)'
    run_with_spaces() {
      # The old implementation built the array like: behaviors=( ${_behaviors} )
      # which would split on spaces and break a single behavior into multiple
      # elements. The new implementation uses `declare -p behaviors`, preserving
      # each behavior as a single array element.
      mock_first_with_rest dependency \
        'echo one two; exit 0' \
        'echo three four; exit 0'

      out1="$(dependency 2>&1)"
      out2="$(dependency 2>&1)"

      printf '%s\n' "${out1}" "${out2}"
    }

    When call in_tempdir run_with_spaces
    The status should be success
    The line 1 of stdout should equal 'one two'
    The line 2 of stdout should equal 'three four'
    The lines of stdout should equal 2
  End

  It 'returns successive behaviors on each invocation and increments index'
    # Given
    prepare_then_execute_sut() {
      # shellcheck disable=SC2016
      {
        echo '#!/bin/sh'
        echo 'echo INFO: "$(basename "$0")"'
      } >dependency-0
      chmod +x dependency-0

      # shellcheck disable=SC2016
      {
        echo '#!/bin/sh'
        echo 'echo INFO: "$(basename "$0")"'
      } >dependency-1
      chmod +x dependency-1

      mock_first_with_rest dependency dependency-0 dependency-1
      dependency
      dependency
    }

    When call in_tempdir prepare_then_execute_sut
    The status should be success
    The line 1 of stdout should equal 'INFO: dependency-0'
    The line 2 of stdout should equal 'INFO: dependency-1'
    The lines of stdout should equal 2
  End

  It 'increments the index even on mock error'
    run_calls() {
      mock_first_with_rest dependency \
        'echo first; exit 0' \
        'echo second; exit 7'

      out1="$(dependency 2>&1)"; rc1=$?
      out2="$(dependency 2>&1)"; rc2=$?

      printf '%s\n' "${out1}"
      printf '%s\n' "${rc1}"
      printf '%s\n' "${out2}"
      printf '%s\n' "${rc2}"

      printf 'index=%s\n' "$(cat .dependency.index)"
    }

    When call in_tempdir run_calls
    The status should be success
    The line 1 of stdout should equal 'first'
    The line 2 of stdout should equal '0'
    The line 3 of stdout should equal 'second'
    The line 4 of stdout should equal '7'
    The line 5 of stdout should equal 'index=2'
    The lines of stdout should equal 5
  End

  It 'fails with an error after behaviors are exhausted (non-zero exit status)'
    run_exhausted() {
      mock_first_with_rest dependency \
        'echo only; exit 3'

      out1="$(dependency 2>&1)"; rc1=$?
      out2="$(dependency 2>&1)"; rc2=$?

      # Print placeholders for empty output to make assertions simple
      [ -n "${out1}" ] && printf '%s\n' "${out1}" || printf '<empty>\n'
      printf '%s\n' "${rc1}"
      [ -n "${out2}" ] && printf '%s\n' "${out2}" || printf '<empty>\n'
      printf '%s\n' "${rc2}"
      printf 'index=%s\n' "$(cat .dependency.index)"
    }

    When call in_tempdir run_exhausted
    The status should be success
    The line 1 of stdout should equal 'only'
    The line 2 of stdout should equal '3'
    The line 3 of stdout should equal 'ERROR: dependency: no more mocked behaviors (index 1 >= 1)'
    The line 4 of stdout should equal '1'
    The line 5 of stdout should equal 'index=2'
    The lines of stdout should equal 5
  End

  It 'resets the index when re-mocking the same dependency'
    run_reset() {
      mock_first_with_rest dependency \
        'echo first-A; exit 0' \
        'echo second-A; exit 0'

      _="$(dependency)"; _="$(dependency)"

      # Re-run with different behaviors, which should reset index to 0
      mock_first_with_rest dependency \
        'echo first-B; exit 5' \
        'echo second-B; exit 0'

      out="$(dependency 2>&1)"; rc=$?
      printf '%s\n' "${out}"
      printf '%s\n' "${rc}"
      printf 'index=%s\n' "$(cat .dependency.index)"
    }

    When call in_tempdir run_reset
    The status should be success
    The line 1 of stdout should equal 'first-B'
    The line 2 of stdout should equal '5'
    The line 3 of stdout should equal 'index=1'
    The lines of stdout should equal 3
  End

  It 'executes behavior in a subshell so EXIT trap in behavior does not override parent trap'
    run_subshell_check() {
      # The behavior sets its own EXIT trap to create a file, then exits 0.
      # If behavior ran in the same shell, it would override the parent's trap
      # and prevent the index increment. Running in a subshell should:
      #  - create the touched file from the subshell EXIT trap, and
      #  - still allow the parent EXIT trap to increment the index to 1.
      mock_first_with_rest dependency \
        'trap "echo SUBSHELL > touched" EXIT; exit 0'

      out="$(dependency 2>&1)"; rc=$?

      printf '%s\n' "${rc}"
      printf 'index=%s\n' "$(cat .dependency.index)"
      [ -f touched ] && echo 'touched:yes'
    }

    When call in_tempdir run_subshell_check
    The status should be success
    The line 1 of stdout should equal '0'
    The line 2 of stdout should equal 'index=1'
    The line 3 of stdout should equal 'touched:yes'
    The lines of stdout should equal 3
  End

End
