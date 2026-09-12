# gRPC Bazel 9 Support

go/grpc-bazel-9

Weizhe Yuan (weizheyuan@google.com)

## Summary

This document explains how we're adding Bazel 9 support to gRPC. After switching, gRPC will still work with Bazel 8 and future versions can benefit from newer features. This document also explains why Bazel's package manager can make things tricky and unpredictable in certain use cases, and proposes a gradual approach to Bazel 9 adoption.

## Requirement

The term "bazel 9 support" can refer to two different contexts:

1. Use Bazel 9 to build gRPC from the source tree root. This is typically used in gRPC's own CI environment and/or when users download gRPC source code for compilation.
2. Use Bazel 9 to add gRPC as a dependency module into a user's project. This is typically done by adding a `bazel_dep()` line to the `MODULE.bazel` file, which downloads the source code from the Bazel Central Registry (BCR).

The second scenario is harder due to transitive dependency requirements, detailed in the [Design](#design) section.

## Major Changes in Bazel 9

Key backward-incompatible changes in Bazel 9 (see the [Bazel 9 LTS announcement](https://blog.bazel.build/2026/01/20/bazel-9.html)) include:

### Mandatory Bazelmod and Deprecation of WORKSPACE

Bazel 9 is the first LTS version which mandates the use of bazelmod, the new module and package management system. The new module system replaces the legacy WORKSPACE mechanism, but also introduces certain new challenges (see [Design](#design) section).

### Starlarkification

Language rules (e.g., `(cc|java|py)_binary`) have been moved from built-ins to user-space Starlark. BUILD files must now explicitly `load` them from rulesets like `@rules_cc`, `@rules_java`, or `@rules_python`.

### Deprecation of incompatible flags

Certain incompatible flags have been removed (see the [Bazel 9 LTS announcement](https://blog.bazel.build/2026/01/20/bazel-9.html)). It seems we have a low to moderate chance of running into these issues.

### (Only in 9.0) compatibility_level

`compatibility_level` modeled major SemVer versions but often caused unsatisfiable version requirements. It was removed in Bazel 9.1 and 8.6 (see [Bazel FAQ](https://bazel.build/versions/9.1.0/external/faq#what-is-a-compatibility-level)). Removing it loosens resolution constraints and simplifies migration; hence, we should target Bazel >= 9.1.

## Design {#design}

### Phased Approach

Empirically, the main challenge of this task arises from a combination of factors:

* Some of our dependencies do not support Bazel 9. See this [example](#opt1).
* Bazel version selection can be different from what we declare in `MODULE.bazel`, making patching difficult or impossible. (see also [Appendix](#version-management)).
* The Bazel build needs to be consistent with other build systems (CMake, Python autotools, Ruby rake, etc.), meaning that if we must upgrade a dependency, we have to do so atomically across all build configurations.

To address these, we propose a phased approach:

- **Phase 0**: Add a warning in `WORKSPACE` that workspace support will be dropped soon.
- **Phase 1**: Adopt Bazel 9 internally (for gRPC developers and CI environment):
  1. Rewrite gRPC's own `BUILD` and `.bzl` files.
  2. For transitive dependencies, pin package versions and maintain Bazel 9 compatibility patches.
- **Phase 2**: Enable compatibility with newer, Bazel 9-compatible dependencies:
  1. Add a Bazel-only build test that intentionally overrides dependency versions to force newer releases.
- **Phase 3**: Gradually upgrade dependencies to newer versions that natively support Bazel 9:
  1. Remove the temporary version overrides introduced in Phase 2.
  2. Ensure tests and builds pass across other supported build systems.
- **Phase 4**: Once all dependencies are upgraded, publish the gRPC module to the BCR.

### Strategies for Upgrading Dependencies {#strats}

We need to handle each dependency on a case-by-case basis. Bazel offers several solutions—such as patching or upgrading—which all come with different shortcomings.

#### Option 1: Upgrade package to a version that supports Bazel 9 #{opt1}

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

* May block on BCR code review.
* Very situational. If Bazel chooses a different version, our work becomes a no-op. This approach only works with packages that are archived or do not require frequent upgrades.

## Appendix: Overview of Bazel Version Management {#version-management}

Bazel uses [Minimal Version Selection (MVS)](https://bazel.build/external/module#version-selection) to resolve dependencies. Version pinning can keep our CI environment predictable, but downstream user projects may pull in newer transitive versions of the same dependencies.

> Bazel uses the Minimal Version Selection (MVS) algorithm introduced in the Go module system. MVS assumes that all new versions of a module are backwards compatible, and so picks the highest version specified by any dependent.

To [override](https://bazel.build/external/module#overrides) resolution decisions, users must define `*_override` directives—but these are **only respected in the root module**, not in dependencies like gRPC.

> Specify overrides in the MODULE.bazel file to alter the behavior of Bazel module resolution. Only the root module’s overrides take effect — if a module is used as a dependency, its overrides are ignored.
> 
> Each override is specified for a certain module name, affecting all of its versions in the dependency graph. Although only the root module’s overrides take effect, they can be for transitive dependencies that the root module does not directly depend on.



## References

* Bazel 9 LTS announcements https://blog.bazel.build/2026/01/20/bazel-9.html.
* Bazel release notes https://github.com/bazelbuild/bazel/releases
* https://github.com/google/oss-policies-info/blob/main/foundational-cxx-support-matrix.md
* [KT: Bazelmod](https://docs.google.com/document/d/1zXCp7evG7AhyO2ndICYiPtG4otHPd7AjjSr-GwgwrKs/edit?resourcekey=0-FJLhEvtGT_0CwQZ2eI9q0w&tab=t.0#heading=h.gzx116ekt8hx)
* gRPC Migration to Bazel Module [go/grpc-bzlmod-migration](http://go/grpc-bzlmod-migration)
