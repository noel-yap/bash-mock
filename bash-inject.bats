#!/usr/bin/env bats --tap

load '/opt/homebrew/lib/bats-support/load.bash'
load '/opt/homebrew/lib/bats-assert/load.bash'

setup() {
  load "${BATS_TEST_DIRNAME}/bash-inject.shlib"
}

@test "should default to defining function" {
  assert_equal "$(declare -F fn)" ''

  @inject "${BATS_TEST_DIRNAME}/fn.sh"

  run echo "$(declare -f fn)"
  assert_output -p "${BATS_TEST_DIRNAME}/fn.sh"
}

@test "should not define recursive function" {
  assert_equal "$(declare -F fn)" ''

  @inject "fn"

  run echo "$(declare -f fn)"
  assert_output ''
}

@test "should use injected function" {
  assert_equal "$(declare -F fn)" ''

  function fn() {
    echo mock fn
  }

  @inject "${BATS_TEST_DIRNAME}/fn.sh"

  run echo "$(declare -f fn)"
  assert_output -p 'echo mock fn'
}
