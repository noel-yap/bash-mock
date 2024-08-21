# bash-mock

## Using @inject

```bash
# sut.sh
. bash-inject.shlib

declare -F fn ||
function fn() {
  echo aoeu
}

@inject fn

fn
```

## Using @mock

```bash
. bash-mock.shlib

@test "should mock" {
  @mock fn
  function fn@0() {
    echo snth
  } &&
  export -f fn@0

  run ./sut.sh

  assert_success
  assert_line 'snth'
}
```
