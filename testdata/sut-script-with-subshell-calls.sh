#!/bin/bash

cwd="$(dirname $0)"

. "${cwd}/../bash-inject.shlib"

@inject "${cwd}/dependency-executable.sh"

(
  dependency-executable first-call
  dependency-executable second-call
)
