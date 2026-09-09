# gRPC Bazel 9 Support

go/grpc-bazel-9

Weizhe Yuan (weizheyuan@google.com)

## Summary

This document explains how we're adding Bazel 9 supports to gRPC. After switching, gRPC will still work with Bazel 8 and future versions can benefit from newer features. I'll also explain why bazel's package manager can make things tricky and unpredictable in certain use cases and offer a gradual approach to bazel 9 adoption.

## Requirement

The term "bazel 9 support" can refer to 2 different contexts:

1. Use bazel 9 to build gRPC from the source tree root. This is typically used in gRPC's own CI environment and/or when users download gRPC source code for compilation.
2. Use bazel 9 to add gRPC as a dependency module into user's project. This is typically done by adding a `bazel_dep()` line into `MODULE.bazel` file and bazel will download source code from BCR.

I propose a gradual approach which starting with 1), which enables bazel 9 support in our own CI system, and then extend the support to 2), aka end users. This is because the second problem is harder, more nuanced to tackle due to a combination of factors, more discussion will be covered in [Challenges](#challenges) section.

## Major Changes in Bazel 9

The following section highlights several backward incompatible changes in bazel 9. See also https://blog.bazel.build/2026/01/20/bazel-9.html.

### Mandatory Bazelmod and Deprecation of WORKSPACE

Bazel 9 is the first LTS version which mandates use of bazelmod, the new module and package management system. The new module system replaces the legacy WORKSPACE mechanism but also introduces certain new problems (see [Challenges](#challenges) section).

### Starlarkification

Bazel team demoted certain language rules (e.g. `(cc|java|py)_binary`) from bazel builtins to user space starlark implementation. Because these rules are no longer built-in, BUILD files must explicitly `load` them from their respective rulesets (such as `@rules_cc`, `@rules_java`, or `@rules_python`).

### Deprecation of incompatible flags

Certain incompatible flags are deleted https://blog.bazel.build/2026/01/20/bazel-9.html. It seems we have a low to moderate chance of running into these issues.

### (Only in 9.0) compatibility_level

`compatibility_level` bazel's own abstration layer that models major version number in semvar. It can leads to unsatisfiable version requirements and has been removed in 9.1 and 8.6 respectively (see [link](https://bazel.build/versions/9.1.0/external/faq#what-is-a-compatibility-level)). This loosens the constraints during version resolution and makes migration much easier, and that's why we should target bazel >= 9.1.

## Design

### Challenges {#challenges}

Empirically, the main challenge of this task is from the combination of facts that

* Some of our dependencies don't support bazel 9.
* Bazel can select a version different from what we declare in `MODULE.bazel`, making patching difficult to apply fix to a specific version of dependency (it is by design, see [appendix](#version-management)).
* Bazel build need to be consistent with other build systems (cmake, bazel, python autotools, rubyrake, etc), meaning that if we have to upgrade a dependency, we do everything in an atomic fashion.

As a result, we need to handle each dependency on a case-by-case basis. There're several imperfect solutions, such as patching or upgrading which all come with different problems, and this section will explains their respective pros and cons.

#### Option 1: Upgrade package to a (major) version that supports bazel 9

Pros:

* Doesn't require change in user code.
* Minimizes long term tech debt.

Cons:

* Certain packages may not support bazel 9, or become archived and never be able to support bazel 9 (e.g. opencensus-cpp only supports bazel 9 since 2026-05-22 through a contributed patch.)
* Our build system requires consistent version across various build systems. This can significantly amplify the difficulty of upgrades.

#### Option 2: Version pinning + Patching bazel dependencies.

Pros:

* Change is local to bazel-related code and owned by us. Won't break other builds (cmake etc).
* Migration is largely automated thanks to tools (`buildozer`, `buildifier` etc).

Cons:

* Patching only works when building from gRPC root , when user download gRPC using MODULE.bazel the build will break. For the same reason, the code can't be published to BCR (due to presubmit failure).
    * Alternatively we can instruct users to upgrade packages, but that combination of versions will be unsupported/untested by our CI.

#### Option 3: Contribute a patch release to BCR.

By convention, package maintainers will release packages suffixed with `.bcr.N` to bazel central registry, which is like a "patch" version number at one level lower than the upstream's patch version.

Pros:

* Slightly better chance that things will work on user machine.
* Doesn't require changing gRPC code.

Cons:

* May block on code review.
* Very situational. If bazel chooses a different version our work becomes no-op. This approach only works with packages that are archived or doesn't require frequent upgrades.

### Phased Approach

Due to the difficulty mentioned above, a phased approach is proposed:

- **Phase 0**: Add a warning in WORKSPACE that users will use it at their own risk.
- **Phase 1**: Use bazel 9 as the default version for developers and CI env. This step leverages automatic refactoring tools to patch selected versions of dependencies in our own source tree only.
- **Phase 2**: Make sure gRPC is buildable with bazel 9 + a curated set of package versions. This requires a out-of-tree build test with `bazel_dep()` instructions that makes bazel choose higher versions.
- **Phase 3**: Gradually upgrade dependencies to newer versions that support bazel 9, and remove the version overrides from tests in Phase 3.
- **Phase 4**: Once all the dependencies are upgraded, publish the version to BCR.

## Appendix: Overview of Bazel Version Management {#version-management}

Bazel's package manager uses Minimal Version Selection (https://bazel.build/external/module#version-selection) algorithm. In our own environment, most of the major dependencies are pinned to a specific version, and the resolved graph will be largely predictable. In user environment, however, some package invisible to gRPC can specify dependency on a newer package, and transitively causes bazel to bump up the final chosen version.

To mitigate the problem, bazel allows overriding the version resolution decision, but only in root module. (using *_override primitives).

## References

* Bazel 9 LTS announcements https://blog.bazel.build/2026/01/20/bazel-9.html.
* Bazel release notes https://github.com/bazelbuild/bazel/releases
* https://github.com/google/oss-policies-info/blob/main/foundational-cxx-support-matrix.md
* [KT: Bazelmod](https://docs.google.com/document/d/1zXCp7evG7AhyO2ndICYiPtG4otHPd7AjjSr-GwgwrKs/edit?resourcekey=0-FJLhEvtGT_0CwQZ2eI9q0w&tab=t.0#heading=h.gzx116ekt8hx)
* gRPC Migration to Bazel Module [go/grpc-bzlmod-migration](http://go/grpc-bzlmod-migration) 


