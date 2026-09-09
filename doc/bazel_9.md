# gRPC Bazel 9 Support

go/grpc-bazel-9

Weizhe Yuan (weizheyuan@google.com)

## Summary

This document explains how we're adding Bazel 9 supports to gRPC. After switching, gRPC will still work with Bazel 8 and future versions can benefit from newer features.

## Changes in Bazel 9

The following section explains the backward incompatible changes in bazel 9. See also https://blog.bazel.build/2026/01/20/bazel-9.html.

### Mandatory Bazelmod and Deprecation of WORKSPACE

Bazel 9 is the first LTS version which mandates use of bazelmod, the new module and package management system. Traditionally bazel uses WORKSPACE for module management, which comes with a first-come-wins version dependency resolution mechanism akin to C-style header include guard. This causes numerous problems (e.g. name conflict in flat namespace, unsatisfiable version requirements, nuanced bugs caused by order of inclusion, etc). <!-- TODO: references --> The new module system solves these problems with certain tradeoffs (see [Problems](#problems) section), and becomes mandatory in Bazel 9.

### Starlarkification

Bazel team demoted certain language rules (e.g. `(cc|java|py)_binary`) from bazel builtins to user space starlark implementation. <!--TODO(gemini): explain why now we need to load(), this is largely automated. -->

### Deprecation of incompatible flags

<!-- TODO(gemini): very briefly mention https://blog.bazel.build/2026/01/20/bazel-9.html. explains we have a low to moderate chance of running into issue -->

### (Obsolete) compatibility_level

NOTE: This section becomes obsolete due to 9.1 deprecating `compatibility_level` and loosen the constraints. <!-- TODO(gemini): add reference link here-->

## Requirement

The term "bazel 9 support" can happen in 2 different contexts:

* Use bazel 9 to build gRPC from the source tree root. This is typically used in gRPC's own CI environment and/or when users download gRPC source code for compilation.
* Use bazel 9 to download gRPC as a dependency module into user's project. This is typically done by adding a `bazel_dep()` line into `MODULE.bazel` file.

## Problems {#problems}

The problem mainly comes from the lack of upstream support. 

## References

* Bazel 9 LTS announcements https://blog.bazel.build/2026/01/20/bazel-9.html.
* Bazel release notes https://github.com/bazelbuild/bazel/releases
* https://github.com/google/oss-policies-info/blob/main/foundational-cxx-support-matrix.md
* [KT: Bazelmod](https://docs.google.com/document/d/1zXCp7evG7AhyO2ndICYiPtG4otHPd7AjjSr-GwgwrKs/edit?resourcekey=0-FJLhEvtGT_0CwQZ2eI9q0w&tab=t.0#heading=h.gzx116ekt8hx)
* gRPC Migration to Bazel Module [go/grpc-bzlmod-migration](http://go/grpc-bzlmod-migration) 


