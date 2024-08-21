#!/usr/bin/env bats --tap

load '/opt/homebrew/lib/bats-support/load.bash'
load '/opt/homebrew/lib/bats-assert/load.bash'

setup() {
  load "${BATS_TEST_DIRNAME}/bash-mock.shlib"
}

@test "should use actual function" {
  run "${BATS_TEST_DIRNAME}/testdata/sut-script-using-function.sh"

  assert_success
  assert_line 'first-call'
  assert_line 'second-call'
}

@test "should mock function" {
  @mock dependency-function
  function dependency-function@0() {
    assert_equal "$1" 'first-call'

    echo 'mocked first-call'
  } &&
  export -f dependency-function@0
  function dependency-function@1() {
    assert_equal "$1" 'second-call'

    echo 'mocked second-call'
  } &&
  export -f dependency-function@1

  run "${BATS_TEST_DIRNAME}/testdata/sut-script-using-function.sh"

  assert_success
  assert_line 'mocked first-call'
  assert_line 'mocked second-call'
}

@test "should use actual executable" {
  run "${BATS_TEST_DIRNAME}/testdata/sut-script-using-executable.sh"

  assert_success
  assert_line 'first-call'
  assert_line 'second-call'
}

@test "should mock executable" {
  @mock dependency-executable
  function dependency-executable@0() {
    assert_equal "$1" 'first-call'

    echo 'mocked first-call'
  } &&
  export -f dependency-executable@0
  function dependency-executable@1() {
    assert_equal "$1" 'second-call'

    echo 'mocked second-call'
  } &&
  export -f dependency-executable@1

  run "${BATS_TEST_DIRNAME}/testdata/sut-script-using-executable.sh"

  assert_success
  assert_line 'mocked first-call'
  assert_line 'mocked second-call'
}

@test "should work when mock is called in subshells" {
  @mock dependency-executable
  function dependency-executable@0() {
    assert_equal "$1" 'first-call'

    echo 'mocked first-call'
  } &&
  export -f dependency-executable@0
  function dependency-executable@1() {
    assert_equal "$1" 'second-call'

    echo 'mocked second-call'
  } &&
  export -f dependency-executable@1

  run "${BATS_TEST_DIRNAME}/testdata/sut-script-with-subshell-calls.sh"

  assert_success
  assert_line 'mocked first-call'
  assert_line 'mocked second-call'
}
