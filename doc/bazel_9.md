# gRPC Bazel 9 Support

go/grpc-bazel-9

Weizhe Yuan (weizheyuan@google.com)

## Summary

This document explains how we're adding Bazel 9 support to gRPC. After switching, gRPC will still work with Bazel 8 and future versions can benefit from newer features. This document also explains why Bazel's package manager can make things tricky and unpredictable in certain use cases, and proposes a gradual approach to Bazel 9 adoption.

## Requirement

The term "bazel 9 support" can refer to two different contexts:

1. Use Bazel 9 to build gRPC from the source tree root. This is typically used in gRPC's own CI environment and/or when users download gRPC source code for compilation.
2. Use Bazel 9 to add gRPC as a dependency module into a user's project. This is typically done by adding a `bazel_dep()` line to the `MODULE.bazel` file, which downloads the source code from the Bazel Central Registry (BCR).

I propose a gradual approach starting with 1), which enables Bazel 9 support in our own CI system, and then extending support to 2), i.e., end users. This is because the second problem is harder and more nuanced due to a combination of factors; more discussion is covered in the [Challenges](#challenges) section.

## Major Changes in Bazel 9

The following section highlights several backward incompatible changes in Bazel 9. See also https://blog.bazel.build/2026/01/20/bazel-9.html.

### Mandatory Bazelmod and Deprecation of WORKSPACE

Bazel 9 is the first LTS version which mandates the use of bazelmod, the new module and package management system. The new module system replaces the legacy WORKSPACE mechanism, but also introduces certain new challenges (see [Challenges](#challenges) section).

### Starlarkification

The Bazel team demoted certain language rules (e.g., `(cc|java|py)_binary`) from Bazel built-ins to user-space Starlark implementations. Because these rules are no longer built-in, BUILD files must explicitly `load` them from their respective rulesets (such as `@rules_cc`, `@rules_java`, or `@rules_python`).

### Deprecation of incompatible flags

Certain incompatible flags have been removed (see the [Bazel 9 LTS announcement](https://blog.bazel.build/2026/01/20/bazel-9.html)). It seems we have a low to moderate chance of running into these issues.

### (Only in 9.0) compatibility_level

`compatibility_level` is Bazel's own abstraction layer that models the major version number in Semantic Versioning (SemVer). It can lead to unsatisfiable version requirements and has been removed in 9.1 and 8.6, respectively (see the [Bazel FAQ](https://bazel.build/versions/9.1.0/external/faq#what-is-a-compatibility-level)). This loosens the constraints during version resolution and makes migration much easier; hence, we should target Bazel >= 9.1.

## Design

### Challenges {#challenges}

Empirically, the main challenge of this task arises from a combination of factors:

* Some of our dependencies do not support Bazel 9.
* Bazel can select a version different from what we declare in `MODULE.bazel`, making patching difficult since a patch applies to a specific version of a dependency (this is by design; see the [Appendix](#version-management)).
* The Bazel build needs to be consistent with other build systems (CMake, Python autotools, Ruby rake, etc.), meaning that if we must upgrade a dependency, we have to do so atomically across all build configurations.

As a result, we need to handle each dependency on a case-by-case basis. There are several imperfect solutions—such as patching or upgrading—which all come with different problems. This section explains their respective pros and cons.

#### Option 1: Upgrade package to a (major) version that supports Bazel 9

Pros:

* Doesn't require changes in user code.
* Minimizes long-term tech debt.

Cons:

* Certain packages may not support Bazel 9, or may be archived and never receive native Bazel 9 support (e.g., `opencensus-cpp` has only supported Bazel 9 since 2026-05-22 via a contributed patch).
* Our build system requires consistent dependency versions across various build systems, which significantly amplifies the difficulty of upgrades.

#### Option 2: Version pinning + Patching Bazel dependencies

Pros:

* Change is local to Bazel-related code and owned by us. Won't break other builds (CMake, etc.).
* Migration is largely automated thanks to tools (such as `buildozer` and `buildifier`).

Cons:

* Patching only works when building from the gRPC root; if a downstream user downloads gRPC using Bzlmod (`MODULE.bazel`), their build will break. Consequently, the module cannot be published to the Bazel Central Registry (BCR) due to presubmit failures.
    * Alternatively, we can instruct users to upgrade packages, but that specific combination of versions will be unsupported and untested by our CI.

#### Option 3: Contribute a patch release to BCR

By convention, package maintainers will release packages suffixed with `.bcr.N` to the BCR, which acts like a patch level below the upstream's own patch version.

Pros:

* Slightly better chance that things will work on a user's machine.
* Doesn't require changing gRPC code.

Cons:

* May block on code review.
* Very situational. If Bazel chooses a different version, our work becomes a no-op. This approach only works with packages that are archived or do not require frequent upgrades.

### Phased Approach

Due to the challenges mentioned above, a phased approach is proposed:

- **Phase 0**: Add a warning in `WORKSPACE` that users use it at their own risk.
- **Phase 1**: Use Bazel 9 as the default version for development and CI environments. This step leverages automatic refactoring tools to patch selected versions of dependencies in our own source tree only.
- **Phase 2**: Make sure gRPC is buildable with Bazel 9 and a curated set of package versions. This requires an out-of-tree build test with `bazel_dep()` instructions that forces Bazel to choose higher versions.
- **Phase 3**: Gradually upgrade dependencies to newer versions that support Bazel 9, and remove the version overrides during Phase 3.
- **Phase 4**: Once all dependencies are upgraded, publish the gRPC module to the BCR.

## Appendix: Overview of Bazel Version Management {#version-management}

Bazel's package manager uses the Minimal Version Selection (MVS) algorithm (https://bazel.build/external/module#version-selection). In our own environment, most of the major dependencies are pinned to a specific version, and the resolved graph will be largely predictable. In a user environment, however, some other package (invisible to gRPC) can specify a dependency on a newer version, transitively causing Bazel to bump up the final chosen version.

To mitigate this problem, Bazel allows overriding the version resolution decision, but only in the root module (using `*_override` primitives).

## References

* Bazel 9 LTS announcements https://blog.bazel.build/2026/01/20/bazel-9.html.
* Bazel release notes https://github.com/bazelbuild/bazel/releases
* https://github.com/google/oss-policies-info/blob/main/foundational-cxx-support-matrix.md
* [KT: Bazelmod](https://docs.google.com/document/d/1zXCp7evG7AhyO2ndICYiPtG4otHPd7AjjSr-GwgwrKs/edit?resourcekey=0-FJLhEvtGT_0CwQZ2eI9q0w&tab=t.0#heading=h.gzx116ekt8hx)
* gRPC Migration to Bazel Module [go/grpc-bzlmod-migration](http://go/grpc-bzlmod-migration) 


