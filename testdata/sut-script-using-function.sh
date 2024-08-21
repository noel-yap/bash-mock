#!/bin/bash

cwd="$(dirname $0)"

. "${cwd}/dependency-function.shlib"

. "${cwd}/../bash-inject.shlib"

@inject dependency-fn

dependency-function first-call
dependency-function second-call
