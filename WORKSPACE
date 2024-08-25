load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")

git_repository(
    name = "bazel_bats",
    remote = "https://github.com/filmil/bazel-bats",
    commit = "22db48a75128044bb611492b3e1e654187881fa3",
    shallow_since = "1677540706 -0800",
)

load("@bazel_bats//:deps.bzl", "bazel_bats_dependencies")

bazel_bats_dependencies()